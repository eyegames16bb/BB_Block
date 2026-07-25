import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/services/line_clear_resolver.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:bb_block/features/booster/domain/rotate_piece_command.dart';
import 'package:bb_block/features/booster/domain/single_cell_remove_command.dart';
import 'package:bb_block/features/booster/domain/swap_pieces_command.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_engine/domain/game_session.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/piece_generation/domain/piece_generator.dart';

/// The UI-independent heart of the game. It owns the current [GameSession]
/// and is the single place board/tray/score mutations happen, driven by a
/// [GameModeStrategy] for all mode-specific rules. Every operation returns an
/// ordered list of [GameEvent]s describing what happened, so the presentation
/// layer can react (audio/haptics/animation) without knowing any internals.
///
/// It imports nothing from Flutter — it is pure Dart and fully unit-testable.
///
/// Classic Mode never has boosters (the GDD is explicit: "Bu oyun modunda
/// tamamlayıcı olmayacaktır") — its caller simply never passes initial
/// charges. Level Mode boosters are a *persistent* resource (see
/// `PlayerProgress`): the engine itself doesn't know that: it just starts a
/// session with whatever charge counts the caller hands it and decrements
/// them as they're used. `GameController` is the layer that reads/writes
/// those counts from `PlayerProgress` before/after each engine call.
class GameEngine {
  GameEngine({
    required GameModeStrategy mode,
    required PieceGenerator generator,
    int initialRotateCharges = 0,
    int initialSwapCharges = 0,
    int initialSingleCellRemoveCharges = 0,
    PlacementValidator? placementValidator,
    LineClearResolver? lineClearResolver,
    RotatePieceCommand rotateCommand = const RotatePieceCommand(),
    SingleCellRemoveCommand singleCellRemoveCommand =
        const SingleCellRemoveCommand(),
    SwapPiecesCommand? swapCommand,
  })  : _mode = mode,
        _generator = generator,
        _initialRotateCharges = initialRotateCharges,
        _initialSwapCharges = initialSwapCharges,
        _initialSingleCellRemoveCharges = initialSingleCellRemoveCharges,
        _placementValidator =
            placementValidator ?? const DefaultPlacementValidator(),
        _lineClearResolver =
            lineClearResolver ?? const DefaultLineClearResolver(),
        _rotateCommand = rotateCommand,
        _singleCellRemoveCommand = singleCellRemoveCommand,
        _swapCommand = swapCommand ?? SwapPiecesCommand() {
    _session = _createInitialSession();
  }

  final GameModeStrategy _mode;
  final PieceGenerator _generator;
  final int _initialRotateCharges;
  final int _initialSwapCharges;
  final int _initialSingleCellRemoveCharges;
  final PlacementValidator _placementValidator;
  final LineClearResolver _lineClearResolver;
  final RotatePieceCommand _rotateCommand;
  final SingleCellRemoveCommand _singleCellRemoveCommand;
  final SwapPiecesCommand _swapCommand;

  late GameSession _session;

  GameSession get session => _session;

  GameSession _createInitialSession() {
    final board = _mode.createInitialBoard();
    return GameSession(
      board: board,
      tray: _freshTray(board),
      score: 0,
      mode: _mode.type,
      outcome: const RoundOutcome.ongoing(),
      rotateCharges: _initialRotateCharges,
      swapCharges: _initialSwapCharges,
      singleCellRemoveCharges: _initialSingleCellRemoveCharges,
    );
  }

  List<TrayPiece> _freshTray(Board board) => [
        for (final shape in _generator.nextBatch(board: board))
          TrayPiece(shape: shape),
      ];

  /// Attempts to place the tray piece at [trayIndex], anchored at [anchor].
  /// Runs the full turn loop: place → clear lines → score → refill tray if
  /// emptied → tear down the frame if the mode says so → re-evaluate the
  /// round outcome. On an invalid request nothing changes and a single
  /// [GameEvent.invalidMove] is returned.
  List<GameEvent> placePiece({
    required int trayIndex,
    required GridPosition anchor,
  }) {
    if (_session.isOver) return const [GameEvent.invalidMove()];

    final piece = _session.tray[trayIndex];
    if (piece.isUsed ||
        !_placementValidator.canPlace(
          board: _session.board,
          shape: piece.shape,
          anchor: anchor,
        )) {
      return const [GameEvent.invalidMove()];
    }

    final events = <GameEvent>[];

    var board = _session.board.place(piece.shape, anchor);
    var score = _session.score + piece.shape.cellCount;
    events.add(GameEvent.piecePlaced(placementPoints: piece.shape.cellCount));

    final cleared = _lineClearResolver.findCompletedLines(board);
    if (!cleared.isEmpty) {
      final linePoints = cleared.lineCount *
          _mode.scoringStrategy.pointsPerClearedLine(scoreBeforeClear: score);
      board = _lineClearResolver.clearLines(board, cleared);
      score += linePoints;
      events.add(
        GameEvent.linesCleared(
          rows: cleared.rows,
          columns: cleared.columns,
          linePoints: linePoints,
        ),
      );
    }

    var tray = [
      for (var i = 0; i < _session.tray.length; i++)
        if (i == trayIndex) _session.tray[i].copyWith(isUsed: true)
        else _session.tray[i],
    ];
    if (tray.every((piece) => piece.isUsed)) {
      tray = _freshTray(board);
      events.add(const GameEvent.trayRefilled());
    }

    var frameRemoved = _session.frameRemoved;
    if (!frameRemoved && _mode.shouldRemoveFrameAt(score)) {
      board = board.withFrameRemoved();
      frameRemoved = true;
      events.add(const GameEvent.frameDestroyed());
    }

    final outcome = _mode.evaluateOutcome(
      currentScore: score,
      hasAnyValidPlacement: _hasAnyPlaceableTrayPiece(board, tray),
    );
    if (outcome is! RoundOutcomeOngoing) {
      events.add(GameEvent.roundEnded(outcome: outcome));
    }

    _session = _session.copyWith(
      board: board,
      tray: tray,
      score: score,
      outcome: outcome,
      frameRemoved: frameRemoved,
    );
    return events;
  }

  /// Rotates every unused tray piece 90° clockwise in place, all at once —
  /// applied instantly like the Swap booster, not a "pick a piece" flow.
  /// Consumes one rotate charge; unavailable at zero charges (including
  /// Classic Mode, which always starts at zero).
  List<GameEvent> rotateTray() {
    if (_session.isOver || _session.rotateCharges <= 0) {
      return const [GameEvent.invalidMove()];
    }

    final tray = [
      for (final piece in _session.tray)
        piece.isUsed
            ? piece
            : piece.copyWith(shape: _rotateCommand.execute(piece.shape)),
    ];

    _session = _session.copyWith(
      tray: tray,
      rotateCharges: _session.rotateCharges - 1,
    );
    return [const GameEvent.trayRotated(), ..._reevaluateOutcome()];
  }

  /// Replaces the entire tray with a fresh batch of small pieces. Consumes
  /// one swap charge.
  List<GameEvent> swapTray() {
    if (_session.isOver || _session.swapCharges <= 0) {
      return const [GameEvent.invalidMove()];
    }

    final shapes = _swapCommand.execute(board: _session.board);
    final tray = [for (final shape in shapes) TrayPiece(shape: shape)];

    _session = _session.copyWith(
      tray: tray,
      swapCharges: _session.swapCharges - 1,
    );
    return [const GameEvent.traySwapped(), ..._reevaluateOutcome()];
  }

  /// Erases a single player-placed cell at [position]. Frame cells are never
  /// eligible (see [SingleCellRemoveCommand]). Consumes one single-cell-
  /// remove charge.
  List<GameEvent> removeCell(GridPosition position) {
    if (_session.isOver ||
        _session.singleCellRemoveCharges <= 0 ||
        !_singleCellRemoveCommand.canExecute(
          board: _session.board,
          target: position,
        )) {
      return const [GameEvent.invalidMove()];
    }

    final board = _singleCellRemoveCommand.execute(
      board: _session.board,
      target: position,
    );

    _session = _session.copyWith(
      board: board,
      singleCellRemoveCharges: _session.singleCellRemoveCharges - 1,
    );
    return [
      GameEvent.cellRemoved(position: position),
      ..._reevaluateOutcome(),
    ];
  }

  List<GameEvent> _reevaluateOutcome() {
    final outcome = _mode.evaluateOutcome(
      currentScore: _session.score,
      hasAnyValidPlacement:
          _hasAnyPlaceableTrayPiece(_session.board, _session.tray),
    );
    if (outcome == _session.outcome || outcome is RoundOutcomeOngoing) {
      _session = _session.copyWith(outcome: outcome);
      return const [];
    }
    _session = _session.copyWith(outcome: outcome);
    return [GameEvent.roundEnded(outcome: outcome)];
  }

  bool _hasAnyPlaceableTrayPiece(Board board, List<TrayPiece> tray) {
    for (final piece in tray) {
      if (piece.isUsed) continue;
      if (_placementValidator.hasAnyValidPlacement(
        board: board,
        shape: piece.shape,
      )) {
        return true;
      }
    }
    return false;
  }
}
