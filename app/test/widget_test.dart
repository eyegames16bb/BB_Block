import 'package:bb_block/app.dart';
import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/persistence/domain/saved_round.dart';
import 'package:bb_block/features/settings/presentation/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'support/fake_game_save_repository.dart';
import 'support/fake_round_save_repository.dart';

void main() {
  // Defaults to a completed tutorial — these tests exercise the home
  // screen and its features, not the first-launch onboarding gate (that
  // has its own dedicated tests further down).
  Widget appWith({
    PlayerProgress? progress,
    FakeRoundSaveRepository? roundRepo,
  }) =>
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            FakeGameSaveRepository(
              progress ?? const PlayerProgress(tutorialCompleted: true),
            ),
          ),
          roundSaveRepositoryProvider.overrideWithValue(
            roundRepo ?? FakeRoundSaveRepository(),
          ),
        ],
        child: const BbBlockApp(),
      );

  testWidgets('home screen shows both mode buttons', (tester) async {
    await tester.pumpWidget(appWith());
    // `SplashScreen` (the EyeGames logo, user instruction) holds the very
    // first 3 seconds of every cold launch — this skips straight past it
    // before `StartupGate`'s own (already-completed) tutorial check
    // resolves, same as every other `appWith()` test below.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // No separate "BB Block" title text — the background artwork itself
    // carries the game's branding (see home_screen.dart's _HomeBackground
    // doc comment).
    expect(find.text('Klasik Mod'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets(
      'Klasik Mod resumes a saved round directly — the start-confirmation '
      'sheet was removed (user instruction)', (tester) async {
    addTearDown(() => appRouter.go(AppRoutes.home));

    final board = Board.framed();
    final roundRepo = FakeRoundSaveRepository()
      ..save(
        SavedRound(
          config: const GameLaunchConfig(
            mode: GameModeType.classic,
            classicHasFrame: true,
          ),
          boardSize: board.size,
          cells: board.cells,
          tray: const [],
          score: 321,
          frameRemoved: false,
          rotateCharges: 0,
          swapCharges: 0,
          singleCellRemoveCharges: 0,
        ),
      );

    // `PlayerProgress.classicHasFrame` defaults to true (8x8) — matches the
    // saved round above.
    await tester.pumpWidget(appWith(roundRepo: roundRepo));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.tap(find.text('Klasik Mod'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The framed variant's saved round (score 321) resumed instead of a
    // fresh one starting at 0 — both the live score readout and the
    // (equally caught-up, since 321 already beats a 0 persisted best)
    // record badge show it.
    expect(find.text('321'), findsWidgets);
  });

  testWidgets(
      'changing the Classic Mode board size in Settings is what a fresh '
      'Klasik Mod round uses next (user instruction: persistent Settings '
      'choice, no per-launch sheet anymore)', (tester) async {
    addTearDown(() => appRouter.go(AppRoutes.home));

    await tester.pumpWidget(appWith());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();

    expect(find.text('Klasik Mod'), findsWidgets);
    await tester.tap(find.text('10x10'));
    await tester.pumpAndSettle();

    // Dismiss the sheet via its own Navigator rather than an arbitrary
    // tap coordinate — the sheet's grown taller since this was first
    // written (more rows), so a fixed offset that used to land on the
    // scrim can now land on the sheet's own content instead.
    Navigator.of(tester.element(find.byType(SettingsSheet))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Klasik Mod'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BoardGrid), findsOneWidget);
    final progress = await ProviderScope.containerOf(
      tester.element(find.byType(BoardGrid)),
    ).read(playerProgressControllerProvider.future);
    expect(progress.classicHasFrame, isFalse);
  });

  testWidgets(
      'tapping the rewarded ad chip opens the test ad screen (user '
      'instruction: replace AdMob with our own test ad for this button)',
      (tester) async {
    addTearDown(() => appRouter.go(AppRoutes.home));

    await tester.pumpWidget(appWith());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.tap(find.text('Ödüllü Reklam'));
    await tester.pumpAndSettle();

    // The confirm sheet (user instruction: moved to a bottom sheet, new
    // wording) sits in front of the ad screen — confirm it before the ad
    // itself is expected to appear.
    expect(find.text('Reklam izle ve 100 Coin kazan!'), findsOneWidget);
    await tester.tap(find.text('Reklam İzle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'a Gold Coin gain (e.g. from a rewarded ad) shows a quick +N pop-up '
      'over the home screen coin chip, which fades away on its own (user '
      'instruction)', (tester) async {
    await tester.pumpWidget(appWith());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    const before = GoldKeyConstants.startingGoldKeyCount;
    const after = before + GoldKeyConstants.rewardedAdCoins;
    expect(find.text('$before'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);

    final context = tester.element(find.text('Klasik Mod'));
    await ProviderScope.containerOf(
      context,
    ).read(playerProgressControllerProvider.notifier).grantGoldKey();
    await tester.pump();

    expect(find.text('$after'), findsOneWidget);
    expect(find.text('+${GoldKeyConstants.rewardedAdCoins}'), findsOneWidget);

    // The pop-up is a self-driven, sub-second animation — it disappears on
    // its own without any further state change.
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('+${GoldKeyConstants.rewardedAdCoins}'), findsNothing);
    expect(find.text('$after'), findsOneWidget);
  });

  testWidgets(
      'Level 1 starts straight into the round — the Gold Key choice sheet '
      'was removed (user instruction: boosters are a free, shared ledger '
      'now, no per-round unlock purchase)', (tester) async {
    // `appRouter` is a top-level singleton shared by every test in this
    // file (and by production `app.dart`) — this test is the only one that
    // performs a real navigation, so it must leave the router back where
    // it found it or every test that runs after it inherits a stale
    // `/game` location with no `extra`, crashing on rebuild.
    addTearDown(() => appRouter.go(AppRoutes.home));

    await tester.pumpWidget(appWith());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Not `pumpAndSettle()`: GameScreen's board wraps a `Newton` particle
    // overlay whose internal Ticker never stops on its own (see
    // board_grid_test.dart) — a bounded pump is the established workaround.
    await tester.tap(find.text('Level 1'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('0 / 1000'), findsOneWidget);
  });

  testWidgets(
      'tapping the Gold Key chip opens a read-only progress sheet showing '
      'the balance and the milestone countdown', (tester) async {
    await tester.pumpWidget(
      appWith(
        // Level 4 → 3 levels completed → 3 into the 10-level cycle, 7 to go.
        progress: const PlayerProgress(
          tutorialCompleted: true,
          currentLevel: 4,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.tap(find.text('${GoldKeyConstants.startingGoldKeyCount}'));
    await tester.pumpAndSettle();

    expect(find.text('Altın Coin'), findsOneWidget);
    expect(
      find.text('3 / 10 level tamamlandı — 7 level sonra yeni coin'),
      findsOneWidget,
    );
  });

  testWidgets(
      'switching to English from Settings retranslates the whole app '
      'immediately (user instruction: full TR/EN support)', (tester) async {
    await tester.pumpWidget(appWith());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Klasik Mod'), findsOneWidget);

    await tester.tap(find.byIcon(PhosphorIcons.gear));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    // Closing the sheet returns to the (now English) home screen — via its
    // own Navigator rather than an arbitrary tap coordinate, which grew
    // unreliable once the sheet gained more rows (see the board-size test
    // above for the same fix).
    Navigator.of(tester.element(find.byType(SettingsSheet))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Classic Mode'), findsOneWidget);
    // The Level button's "Level N" counter is the same numeral text in
    // both languages (no translated word to swap), so its presence here
    // doesn't itself prove retranslation — "Classic Mode" above already
    // does that; this just confirms the button still renders correctly.
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Klasik Mod'), findsNothing);
  });

  testWidgets(
      'a fresh install goes straight to the home menu now — the tutorial '
      'is temporarily disabled (user instruction)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            FakeGameSaveRepository(),
          ),
          roundSaveRepositoryProvider.overrideWithValue(
            FakeRoundSaveRepository(),
          ),
        ],
        child: const BbBlockApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Klasik Mod'), findsOneWidget);
  });

  testWidgets(
      'a player who already finished the tutorial goes straight to the '
      'home menu', (tester) async {
    await tester.pumpWidget(appWith());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Klasik Mod'), findsOneWidget);
  });
}
