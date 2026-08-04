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
import 'package:bb_block/features/game/presentation/game_screen.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/booster_bar.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_tray.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/persistence/domain/saved_round.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../support/fake_audio_service.dart';
import '../../support/fake_game_save_repository.dart';
import '../../support/fake_haptics_service.dart';
import '../../support/fake_round_save_repository.dart';
import '../../support/test_fixtures.dart';

void main() {
  Widget wrap(
    GameLaunchConfig config, {
    PlayerProgress? progress,
    FakeRoundSaveRepository? roundRepo,
  }) =>
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            FakeGameSaveRepository(progress ?? const PlayerProgress()),
          ),
          roundSaveRepositoryProvider.overrideWithValue(
            roundRepo ?? FakeRoundSaveRepository(),
          ),
          hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
        ],
        child: MaterialApp(
          // Pinned rather than left to the test platform's default locale
          // (which resolves to 'en', one of our supported locales, and
          // would silently render English) — GameScreen itself doesn't
          // read `PlayerProgress.languageCode` (only `BbBlockApp` binds
          // that), so this test's expected-Turkish assertions need an
          // explicit locale here.
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(config: config),
        ),
      );

  testWidgets('classic frameless game renders the board and a full tray',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.classic)),
    );
    await tester.pump();

    expect(find.byType(BoardGrid), findsOneWidget);
    expect(find.byType(PieceTray), findsOneWidget);
    // Three draggable pieces in a fresh tray.
    expect(find.byType(Draggable<int>), findsNWidgets(3));
  });

  testWidgets('level game shows the score-to-target progress header',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.level)),
    );
    // Level Mode gates on PlayerProgress finishing its load before it
    // mounts the actual game (see GameScreen.build) — one extra pump past
    // that loading frame.
    await tester.pump();
    await tester.pump();

    expect(find.text('0 / 1000'), findsOneWidget);
    // The Material LinearProgressIndicator was replaced with a custom thin
    // line + threshold tick matching the reference mockups; it's private to
    // game_screen.dart, so the test targets it by key instead of type.
    expect(find.byKey(const Key('level-progress-bar')), findsOneWidget);
    // Fresh progress starts at level 1.
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets(
      "level game shows the player's actual current level, not always 1",
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const GameLaunchConfig(mode: GameModeType.level),
        progress: const PlayerProgress(currentLevel: 7),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Level 7'), findsOneWidget);
  });

  testWidgets('BoosterBar is hidden for Classic Mode', (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.classic)),
    );
    await tester.pump();

    expect(find.byType(BoosterBar), findsNothing);
  });

  testWidgets(
      'BoosterBar shows zero charges for Level Mode started without a key',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const GameLaunchConfig(
          mode: GameModeType.level,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(BoosterBar), findsOneWidget);
    final boosterBar = find.byType(BoosterBar);
    // All three boosters start at zero unless a Gold Key was spent at the
    // start-of-round sheet (see GameLaunchConfig.levelBoostersUnlocked).
    expect(
      find.descendant(of: boosterBar, matching: find.text('0')),
      findsNWidgets(3),
    );
  });

  testWidgets(
      'BoosterBar shows one charge of every booster when unlocked with a '
      'Gold Key', (tester) async {
    await tester.pumpWidget(
      wrap(
        const GameLaunchConfig(
          mode: GameModeType.level,
          levelBoostersUnlocked: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final boosterBar = find.byType(BoosterBar);
    expect(
      find.descendant(of: boosterBar, matching: find.text('1')),
      findsNWidgets(3),
    );
  });

  testWidgets('the pause button shows an overlay, and Devam Et dismisses it',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.classic)),
    );
    await tester.pump();

    expect(find.text('Duraklatıldı'), findsNothing);

    await tester.tap(find.byIcon(PhosphorIcons.pause));
    await tester.pump();

    expect(find.text('Duraklatıldı'), findsOneWidget);

    await tester.tap(find.text('Devam Et'));
    await tester.pump();

    expect(find.text('Duraklatıldı'), findsNothing);
  });

  testWidgets(
      'backgrounding the app mid-round pauses it, visible again on return',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.classic)),
    );
    await tester.pump();

    // The engine binding deliberately suppresses frames while the
    // simulated app is AppLifecycleState.paused (it mirrors real OS
    // behaviour: a backgrounded app isn't drawing). setState still runs
    // and marks the pause dirty, but nothing paints until state returns to
    // resumed — exactly when the player would actually see the screen
    // again, so this sequence matches what really happens on-device.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Duraklatıldı'), findsOneWidget);
  });

  testWidgets('placing a piece shows a rising +N score popup',
      (tester) async {
    const config = GameLaunchConfig(mode: GameModeType.classic);
    await tester.pumpWidget(wrap(config));
    await tester.pump();

    expect(find.textContaining('+'), findsNothing);

    // Drive the same controller call BoardGrid's onPlace would make on a
    // real drop, rather than simulating the drag gesture itself — that
    // mechanics is already covered end-to-end by board_grid_test.dart.
    // The board starts empty, so any tray piece fits at the origin.
    final context = tester.element(find.byType(GameScreen));
    ProviderScope.containerOf(context)
        .read(gameControllerProvider(config).notifier)
        .placePiece(
          trayIndex: 0,
          anchor: const GridPosition(row: 0, column: 0),
        );
    await tester.pump();

    expect(find.textContaining('+'), findsOneWidget);
  });

  testWidgets(
      'a Classic Mode round persists the high score the instant it is '
      'beaten, without waiting for game over', (tester) async {
    const config = GameLaunchConfig(mode: GameModeType.classic);
    await tester.pumpWidget(wrap(config));
    await tester.pump();

    final context = tester.element(find.byType(GameScreen));
    final container = ProviderScope.containerOf(context);
    container.read(gameControllerProvider(config).notifier).placePiece(
          trayIndex: 0,
          anchor: const GridPosition(row: 0, column: 0),
        );
    await tester.pump();

    final score = container.read(gameControllerProvider(config)).score;
    expect(score, greaterThan(0));
    expect(
      container.read(playerProgressControllerProvider).value!
          .classicHighScoreFrameless,
      score,
    );
  });

  testWidgets(
      'Classic Mode "no valid move" shows the Gold Coin continue button, '
      'and tapping it revives the round', (tester) async {
    const config = GameLaunchConfig(mode: GameModeType.classic);
    final board = Board(
      size: 10,
      cells: [
        CellState.empty,
        ...List.filled(99, CellState.filled),
      ],
    );
    final domino = shapeById(PieceShapeId.dominoHorizontal);
    final savedRound = SavedRound(
      config: config,
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

    await tester.pumpWidget(
      wrap(
        config,
        progress: const PlayerProgress(
          goldKeyCount: GoldKeyConstants.actionCostCoins,
        ),
        roundRepo: roundRepo,
      ),
    );
    await tester.pump();

    expect(find.text('Devam Et (100'), findsOneWidget);

    await tester.tap(find.text('Devam Et (100'));
    await tester.pump();

    final context = tester.element(find.byType(GameScreen));
    final container = ProviderScope.containerOf(context);
    expect(
      container.read(gameControllerProvider(config)).outcome,
      const RoundOutcome.ongoing(),
    );
    expect(
      container.read(playerProgressControllerProvider).value!.goldKeyCount,
      0,
    );
  });

  /// Every cell filled except: a lone diagonal gap in each row (all
  /// isolated — no two are ever adjacent, so nothing but a single-cell
  /// piece could ever land in one), plus a genuine 2-cell horizontal gap
  /// at (5,5)-(5,6) reserved for the first of three horizontal dominoes in
  /// the tray, plus one extra isolated gap at (5,0) so row 5 itself never
  /// becomes fully filled (and therefore never clears) once that domino
  /// lands. Placing the first domino leaves zero valid placements for the
  /// other two (dominoes need two *adjacent* empty cells; every remaining
  /// gap is a lone single) — this drives Classic Mode into
  /// `RoundOutcomeClassicGameOver` through the real placement pipeline
  /// (`GameController._apply`), not by pre-loading an already-terminal
  /// `SavedRound` the way the test above does.
  ///
  /// One subtlety a first version of this fixture missed: column 5's
  /// *only* empty cell was (5,5) itself — filling it with the domino
  /// completed the whole column, triggering a real line-clear that reopened
  /// a fresh 2-cell gap and kept the round `Ongoing` instead of ending it.
  /// The extra isolated gap at (0,5) keeps column 5 (like every other row
  /// and column here) permanently short of complete.
  Board almostFullClassicBoard() {
    final cells = List<CellState>.filled(100, CellState.filled);
    for (var r = 0; r < 10; r++) {
      if (r == 5) continue;
      cells[r * 10 + r] = CellState.empty;
    }
    cells[5 * 10 + 0] = CellState.empty;
    cells[5 * 10 + 5] = CellState.empty;
    cells[5 * 10 + 6] = CellState.empty;
    cells[0 * 10 + 5] = CellState.empty;
    return Board(size: 10, cells: cells);
  }

  testWidgets(
      'Tekrar Oyna after a real (not pre-loaded) Classic Mode game-over '
      'actually restarts from zero — score back to 0, a genuinely empty '
      'board, and the round-over overlay gone', (tester) async {
    const config = GameLaunchConfig(mode: GameModeType.classic);
    final domino = shapeById(PieceShapeId.dominoHorizontal);
    final savedRound = SavedRound(
      config: config,
      boardSize: 10,
      cells: almostFullClassicBoard().cells,
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

    await tester.pumpWidget(wrap(config, roundRepo: roundRepo));
    await tester.pump();

    final context = tester.element(find.byType(GameScreen));
    final container = ProviderScope.containerOf(context);

    // Confirms the fixture actually starts *ongoing*, not already
    // game-over — the round-over transition below has to come from the
    // real placement pipeline, exactly like real gameplay.
    expect(
      container.read(gameControllerProvider(config)).outcome,
      const RoundOutcome.ongoing(),
    );

    container.read(gameControllerProvider(config).notifier).placePiece(
          trayIndex: 0,
          anchor: const GridPosition(row: 5, column: 5),
        );
    await tester.pump();

    expect(
      container.read(gameControllerProvider(config)).outcome,
      const RoundOutcome.classicGameOver(),
    );
    expect(find.text('Tekrar Oyna'), findsOneWidget);

    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pump();

    final freshSession = container.read(gameControllerProvider(config));
    expect(freshSession.outcome, const RoundOutcome.ongoing());
    expect(freshSession.score, 0);
    expect(
      freshSession.board.cells.every((cell) => cell == CellState.empty),
      isTrue,
    );
    expect(find.text('Tekrar Oyna'), findsNothing);
  });
}
