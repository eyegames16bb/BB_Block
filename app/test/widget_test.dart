import 'package:bb_block/app.dart';
import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/persistence/domain/saved_round.dart';
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
      'Klasik Mod always shows the Çerçeve Var/Yok sheet, even with a '
      'saved round already in progress (revised user instruction), and '
      'resumes whichever variant is chosen', (tester) async {
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

    await tester.pumpWidget(appWith(roundRepo: roundRepo));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.tap(find.text('Klasik Mod'));
    await tester.pumpAndSettle();

    // The sheet shows every time now — a saved round no longer skips it.
    expect(find.text('Çerçeve Var (8x8)'), findsOneWidget);
    expect(find.text('Çerçeve Yok (10x10)'), findsOneWidget);

    await tester.tap(find.text('Çerçeve Var (8x8)'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The framed variant's saved round (score 321) resumed instead of a
    // fresh one starting at 0 — both the live score readout and the
    // (equally caught-up, since 321 already beats a 0 persisted best)
    // record badge show it.
    expect(find.text('321'), findsWidgets);
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'a fresh player is asked to confirm spending a Gold Key on first '
      'Level entry — playing without a key is no longer offered (user '
      'instruction)', (tester) async {
    await tester.pumpWidget(appWith());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.tap(find.text('Level 1'));
    await tester.pumpAndSettle();

    expect(find.text('Tamamlayıcılar İle Oyna (100'), findsOneWidget);
  });

  testWidgets(
      'Level Mod skips the key-choice sheet and resumes straight into the '
      'round when a choice is already locked in for the current level '
      '(user instruction: no re-asking every entry)', (tester) async {
    // `appRouter` is a top-level singleton shared by every test in this
    // file (and by production `app.dart`) — this test is the only one that
    // performs a real navigation, so it must leave the router back where
    // it found it or every test that runs after it inherits a stale
    // `/game` location with no `extra`, crashing on rebuild.
    addTearDown(() => appRouter.go(AppRoutes.home));

    await tester.pumpWidget(
      appWith(
        progress: const PlayerProgress(
          tutorialCompleted: true,
          pendingLevelChoiceLevel: 1,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Not `pumpAndSettle()`: GameScreen's board wraps a `Newton` particle
    // overlay whose internal Ticker never stops on its own (see
    // board_grid_test.dart) — a bounded pump is the established workaround.
    await tester.tap(find.text('Level 1'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The sheet's own title ("Level Mod"/`levelSheetTitle`) is a distinct
    // string from the home button's live "Level N" counter — its absence
    // confirms the sheet itself was skipped, not just that its now-removed
    // "without a key" button is gone.
    expect(find.text('Level Mod'), findsNothing);
    expect(find.text('Level 1'), findsOneWidget);
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

    // Closing the sheet returns to the (now English) home screen.
    await tester.tapAt(const Offset(200, 100));
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
      'a fresh install sees the interactive tutorial before the home menu '
      '(user instruction: first launch only)', (tester) async {
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

    // A positive check that the tutorial is genuinely showing — not just
    // that home isn't — or this would pass just as well while stuck on
    // the splash screen (which was never reached because of a bug),
    // making the negative checks below meaningless.
    expect(find.text('Atla'), findsOneWidget);
    expect(find.text('Klasik Mod'), findsNothing);
    expect(find.text('Level 1'), findsNothing);
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
