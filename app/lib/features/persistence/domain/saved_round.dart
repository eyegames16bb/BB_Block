import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_engine/domain/game_session.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';

/// A snapshot of a round still in progress, saved instantly on every move so
/// the game survives a *full app close* — not just backgrounding, which
/// `GameScreen`'s pause overlay already handles in memory. `PlayerProgress`
/// deliberately never carries this: it's account-level, this is a single
/// resumable attempt, cleared the moment that attempt actually ends (win,
/// lose, or the player quits back to the main menu).
class SavedRound {
  const SavedRound({
    required this.config,
    required this.boardSize,
    required this.cells,
    required this.tray,
    required this.score,
    required this.frameRemoved,
    required this.rotateCharges,
    required this.swapCharges,
    required this.singleCellRemoveCharges,
    this.starTargetRow,
    this.starTargetColumn,
  });

  factory SavedRound.fromSession({
    required GameLaunchConfig config,
    required GameSession session,
  }) =>
      SavedRound(
        config: config,
        boardSize: session.board.size,
        cells: session.board.cells,
        tray: [
          for (final piece in session.tray) SavedRoundTrayPiece.from(piece),
        ],
        score: session.score,
        frameRemoved: session.frameRemoved,
        rotateCharges: session.rotateCharges,
        swapCharges: session.swapCharges,
        singleCellRemoveCharges: session.singleCellRemoveCharges,
        starTargetRow: session.starTargetRow,
        starTargetColumn: session.starTargetColumn,
      );

  final GameLaunchConfig config;
  final int boardSize;
  final List<CellState> cells;
  final List<SavedRoundTrayPiece> tray;
  final int score;
  final bool frameRemoved;
  final int rotateCharges;
  final int swapCharges;
  final int singleCellRemoveCharges;
  // Level Mode's star-marked row/column (see `GameSession`'s doc comment)
  // — must persist across a resume, since it's meant to stay fixed for the
  // whole level, not just the in-memory session.
  final int? starTargetRow;
  final int? starTargetColumn;

  Board toBoard() => Board(size: boardSize, cells: cells);

  List<TrayPiece> toTrayPieces() => [
        for (final piece in tray) piece.toTrayPiece(),
      ];

  Map<String, dynamic> toJson() => {
        'mode': config.mode.name,
        'classicHasFrame': config.classicHasFrame,
        'levelBoostersUnlocked': config.levelBoostersUnlocked,
        'boardSize': boardSize,
        'cells': [for (final cell in cells) cell.name],
        'tray': [for (final piece in tray) piece.toJson()],
        'score': score,
        'frameRemoved': frameRemoved,
        'rotateCharges': rotateCharges,
        'swapCharges': swapCharges,
        'singleCellRemoveCharges': singleCellRemoveCharges,
        'starTargetRow': starTargetRow,
        'starTargetColumn': starTargetColumn,
      };

  /// Returns `null` on anything malformed (an old save shape from a prior
  /// build, corrupt data) rather than throwing — the safest fallback is to
  /// silently discard it and start a fresh round instead of crashing launch.
  static SavedRound? tryFromJson(Map<String, dynamic> json) {
    try {
      final config = GameLaunchConfig(
        mode: GameModeType.values.byName(json['mode']! as String),
        classicHasFrame: json['classicHasFrame']! as bool,
        levelBoostersUnlocked: json['levelBoostersUnlocked']! as bool,
      );
      final cells = [
        for (final raw in json['cells']! as List<dynamic>)
          CellState.values.byName(raw as String),
      ];
      final tray = [
        for (final raw in json['tray']! as List<dynamic>)
          SavedRoundTrayPiece.fromJson(raw as Map<String, dynamic>),
      ];
      return SavedRound(
        config: config,
        boardSize: json['boardSize']! as int,
        cells: cells,
        tray: tray,
        score: json['score']! as int,
        frameRemoved: json['frameRemoved']! as bool,
        rotateCharges: json['rotateCharges']! as int,
        swapCharges: json['swapCharges']! as int,
        singleCellRemoveCharges: json['singleCellRemoveCharges']! as int,
        // Absent entirely in a save written before this field existed —
        // `null` is the correct fallback (Classic Mode never has one
        // anyway, and a Level Mode round without one just re-rolls next
        // time `GameEngine` builds a *fresh* session, which only happens
        // once this old save is consumed and cleared).
        starTargetRow: json['starTargetRow'] as int?,
        starTargetColumn: json['starTargetColumn'] as int?,
      );
    } on Object {
      return null;
    }
  }
}

class SavedRoundTrayPiece {
  const SavedRoundTrayPiece({
    required this.shapeId,
    required this.cellRows,
    required this.cellColumns,
    required this.baseWeight,
    required this.isUsed,
  });

  factory SavedRoundTrayPiece.from(TrayPiece piece) => SavedRoundTrayPiece(
        shapeId: piece.shape.id,
        cellRows: [for (final cell in piece.shape.cells) cell.row],
        cellColumns: [for (final cell in piece.shape.cells) cell.column],
        baseWeight: piece.shape.baseWeight,
        isUsed: piece.isUsed,
      );

  factory SavedRoundTrayPiece.fromJson(Map<String, dynamic> json) =>
      SavedRoundTrayPiece(
        shapeId: PieceShapeId.values.byName(json['shapeId']! as String),
        cellRows: [
          for (final row in json['cellRows']! as List<dynamic>) row as int,
        ],
        cellColumns: [
          for (final column in json['cellColumns']! as List<dynamic>)
            column as int,
        ],
        baseWeight: json['baseWeight']! as int,
        isUsed: json['isUsed']! as bool,
      );

  final PieceShapeId shapeId;
  final List<int> cellRows;
  final List<int> cellColumns;
  final int baseWeight;
  final bool isUsed;

  TrayPiece toTrayPiece() => TrayPiece(
        shape: PieceShape(
          id: shapeId,
          cells: [
            for (var i = 0; i < cellRows.length; i++)
              GridPosition(row: cellRows[i], column: cellColumns[i]),
          ],
          baseWeight: baseWeight,
        ),
        isUsed: isUsed,
      );

  Map<String, dynamic> toJson() => {
        'shapeId': shapeId.name,
        'cellRows': cellRows,
        'cellColumns': cellColumns,
        'baseWeight': baseWeight,
        'isUsed': isUsed,
      };
}
