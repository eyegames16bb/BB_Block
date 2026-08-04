import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game/application/game_controller.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/persistence/domain/saved_round.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_audio_service.dart';
import '../../support/fake_game_save_repository.dart';
import '../../support/fake_haptics_service.dart';
import '../../support/fake_round_save_repository.dart';
import '../../support/test_fixtures.dart';

void main() {
  ProviderContainer containerWith({
    required FakeRoundSaveRepository roundRepo,
    PlayerProgress progress = const PlayerProgress(),
  }) {
    final container = ProviderContainer(
      overrides: [
        gameSaveRepositoryProvider.overrideWithValue(
          FakeGameSaveRepository(progress),
        ),
        roundSaveRepositoryProvider.overrideWithValue(roundRepo),
        hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
        audioServiceProvider.overrideWithValue(FakeAudioService()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a fresh round is saved the instant it is built, before any move', () {
    final roundRepo = FakeRoundSaveRepository();
    final container = containerWith(roundRepo: roundRepo);
    const config = GameLaunchConfig(mode: GameModeType.classic);

    final session = container.read(gameControllerProvider(config));

    final saved = roundRepo.load(GameModeType.classic);
    expect(saved, isNotNull);
    expect(saved!.score, session.score);
    expect(saved.boardSize, session.board.size);
  });

  test('placing a piece re-saves the round with the new state', () {
    final roundRepo = FakeRoundSaveRepository();
    final container = containerWith(roundRepo: roundRepo);
    const config = GameLaunchConfig(mode: GameModeType.classic);

    container.read(gameControllerProvider(config));
    final controller =
        container.read(gameControllerProvider(config).notifier);
    controller.placePiece(
      trayIndex: 0,
      anchor: const GridPosition(row: 0, column: 0),
    );

    final saved = roundRepo.load(GameModeType.classic);
    final session = container.read(gameControllerProvider(config));
    expect(saved!.score, session.score);
    expect(saved.score, greaterThan(0));
  });

  test(
      'a saved round for the same classicHasFrame variant takes priority '
      'over a fresh start and resumes the exact board/tray/score', () {
    final board = Board(
      size: 10,
      cells: [
        CellState.filled,
        CellState.filled,
        ...List.filled(98, CellState.empty),
      ],
    );
    final piece = shapeById(PieceShapeId.square);
    final savedRound = SavedRound(
      config: const GameLaunchConfig(
        mode: GameModeType.classic,
        classicHasFrame: true,
      ),
      boardSize: 10,
      cells: board.cells,
      tray: [SavedRoundTrayPiece.from(TrayPiece(shape: piece))],
      score: 42,
      frameRemoved: false,
      rotateCharges: 0,
      swapCharges: 0,
      singleCellRemoveCharges: 0,
      starTargetRow: 6,
    );
    final roundRepo = FakeRoundSaveRepository()..save(savedRound);
    final container = containerWith(roundRepo: roundRepo);

    // User instruction: Classic Mode's two frame variants keep fully
    // independent rounds — `HomeScreen._startClassic` always asks the
    // Çerçeve Var/Yok sheet first, then looks up *that* variant's saved
    // round, so the config it pushes with already matches (unlike Level
    // Mode's config, which is resumed regardless of what's passed in).
    const passedInConfig = GameLaunchConfig(
      mode: GameModeType.classic,
      classicHasFrame: true,
    );
    final session = container.read(gameControllerProvider(passedInConfig));

    expect(session.score, 42);
    expect(session.board.cells[0], CellState.filled);
    expect(session.board.cells[1], CellState.filled);
    expect(session.tray, hasLength(1));
    expect(session.tray.single.shape.id, PieceShapeId.square);
    // The star target (Level Mode's mechanic, but stored generically on
    // any SavedRound) survives the resume unchanged — user instruction: it
    // stays fixed for the whole level, not just the in-memory session.
    expect(session.starTargetRow, 6);
    expect(session.starTargetColumn, isNull);
  });

  test(
      "Classic Mode's two frame variants keep fully independent saved "
      'rounds — resuming one never surfaces the other (user instruction)',
      () {
    final framedBoard = Board.framed();
    final framelessBoard = Board.empty();
    final roundRepo = FakeRoundSaveRepository()
      ..save(
        SavedRound(
          config: const GameLaunchConfig(
            mode: GameModeType.classic,
            classicHasFrame: true,
          ),
          boardSize: framedBoard.size,
          cells: framedBoard.cells,
          tray: const [],
          score: 111,
          frameRemoved: false,
          rotateCharges: 0,
          swapCharges: 0,
          singleCellRemoveCharges: 0,
        ),
      )
      ..save(
        SavedRound(
          config: const GameLaunchConfig(mode: GameModeType.classic),
          boardSize: framelessBoard.size,
          cells: framelessBoard.cells,
          tray: const [],
          score: 222,
          frameRemoved: false,
          rotateCharges: 0,
          swapCharges: 0,
          singleCellRemoveCharges: 0,
        ),
      );
    final container = containerWith(roundRepo: roundRepo);

    const framedConfig = GameLaunchConfig(
      mode: GameModeType.classic,
      classicHasFrame: true,
    );
    const framelessConfig = GameLaunchConfig(mode: GameModeType.classic);

    expect(
      container.read(gameControllerProvider(framedConfig)).score,
      111,
    );
    expect(
      container.read(gameControllerProvider(framelessConfig)).score,
      222,
    );
  });

  test(
      "Level Mode's config is always resumed from the saved round "
      'regardless of what the caller passes in (unlike Classic Mode, whose '
      'classicHasFrame is itself the lookup key)', () {
    final board = Board.framed();
    final savedRound = SavedRound(
      config: const GameLaunchConfig(
        mode: GameModeType.level,
        levelBoostersUnlocked: true,
      ),
      boardSize: board.size,
      cells: board.cells,
      tray: const [],
      score: 77,
      frameRemoved: false,
      rotateCharges: 1,
      swapCharges: 1,
      singleCellRemoveCharges: 1,
    );
    final roundRepo = FakeRoundSaveRepository()..save(savedRound);
    final container = containerWith(roundRepo: roundRepo);

    // Passed in with `levelBoostersUnlocked: false` — the saved round's
    // own `true` wins anyway, since Level Mode has only one round slot.
    const passedInConfig = GameLaunchConfig(mode: GameModeType.level);
    final session = container.read(gameControllerProvider(passedInConfig));

    expect(session.score, 77);
    expect(session.rotateCharges, 1);
  });

  test('the saved round is cleared once the round actually ends', () {
    // 996 points, frame already down (score well past the frame-removal
    // threshold): a single 4-cell square placement that completes no line
    // pushes the score straight to the 1000-point target — a clean Level
    // Complete with no line-clear/frame-teardown edge cases to worry about.
    final board = Board.empty();
    final square = shapeById(PieceShapeId.square);
    final savedRound = SavedRound(
      config: const GameLaunchConfig(mode: GameModeType.level),
      boardSize: 10,
      cells: board.cells,
      tray: [SavedRoundTrayPiece.from(TrayPiece(shape: square))],
      score: 996,
      frameRemoved: true,
      rotateCharges: 0,
      swapCharges: 0,
      singleCellRemoveCharges: 0,
    );
    final roundRepo = FakeRoundSaveRepository()..save(savedRound);
    final container = containerWith(roundRepo: roundRepo);
    const config = GameLaunchConfig(mode: GameModeType.level);

    container.read(gameControllerProvider(config));
    final controller =
        container.read(gameControllerProvider(config).notifier);
    controller.placePiece(
      trayIndex: 0,
      anchor: const GridPosition(row: 0, column: 0),
    );

    final session = container.read(gameControllerProvider(config));
    expect(session.outcome, const RoundOutcome.levelComplete());
    expect(roundRepo.load(GameModeType.level), isNull);
  });

  test(
      'continueWithGoldKey spends one key and revives a Classic Mode round '
      'stuck at "no valid move"', () async {
    // The board is full except one isolated empty cell, so a domino tray
    // can never place (game over) but a fresh single-cell-guaranteed batch
    // (see WeightedPieceGenerator) can always fill that one gap.
    final board = Board(
      size: 10,
      cells: [
        CellState.empty,
        ...List.filled(99, CellState.filled),
      ],
    );
    final domino = shapeById(PieceShapeId.dominoHorizontal);
    final savedRound = SavedRound(
      config: const GameLaunchConfig(mode: GameModeType.classic),
      boardSize: 10,
      cells: board.cells,
      tray: [
        SavedRoundTrayPiece.from(TrayPiece(shape: domino)),
        SavedRoundTrayPiece.from(TrayPiece(shape: domino)),
        SavedRoundTrayPiece.from(TrayPiece(shape: domino)),
      ],
      score: 500,
      frameRemoved: false,
      rotateCharges: 0,
      swapCharges: 0,
      singleCellRemoveCharges: 0,
    );
    final roundRepo = FakeRoundSaveRepository()..save(savedRound);
    final container = containerWith(
      roundRepo: roundRepo,
      progress: const PlayerProgress(
        goldKeyCount: GoldKeyConstants.actionCostCoins,
      ),
    );
    const config = GameLaunchConfig(mode: GameModeType.classic);

    final session = container.read(gameControllerProvider(config));
    expect(session.outcome, const RoundOutcome.classicGameOver());

    // Let the async PlayerProgress load settle before spending from it.
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(gameControllerProvider(config).notifier);
    await controller.continueWithGoldKey();

    final revived = container.read(gameControllerProvider(config));
    expect(revived.outcome, const RoundOutcome.ongoing());
    expect(revived.score, 500);
    final progress =
        container.read(playerProgressControllerProvider).value!;
    expect(progress.goldKeyCount, 0);
  });

  test(
      'continueWithGoldKey does nothing when the player has no Gold Key '
      'left', () async {
    final board = Board(
      size: 10,
      cells: [
        CellState.empty,
        ...List.filled(99, CellState.filled),
      ],
    );
    final domino = shapeById(PieceShapeId.dominoHorizontal);
    final savedRound = SavedRound(
      config: const GameLaunchConfig(mode: GameModeType.classic),
      boardSize: 10,
      cells: board.cells,
      tray: [
        SavedRoundTrayPiece.from(TrayPiece(shape: domino)),
        SavedRoundTrayPiece.from(TrayPiece(shape: domino)),
        SavedRoundTrayPiece.from(TrayPiece(shape: domino)),
      ],
      score: 500,
      frameRemoved: false,
      rotateCharges: 0,
      swapCharges: 0,
      singleCellRemoveCharges: 0,
    );
    final roundRepo = FakeRoundSaveRepository()..save(savedRound);
    final container = containerWith(
      roundRepo: roundRepo,
      progress: const PlayerProgress(goldKeyCount: 0),
    );
    const config = GameLaunchConfig(mode: GameModeType.classic);

    container.read(gameControllerProvider(config));
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(gameControllerProvider(config).notifier);
    await controller.continueWithGoldKey();

    final session = container.read(gameControllerProvider(config));
    expect(session.outcome, const RoundOutcome.classicGameOver());
  });
}
