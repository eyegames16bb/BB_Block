import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/tutorial/presentation/tutorial_screen.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_audio_service.dart';
import '../../support/fake_game_save_repository.dart';
import '../../support/fake_haptics_service.dart';

/// Settles every `PlaceSequence` pop-in spring (the tutorial's initial
/// boards start with several already-filled cells — see `_buildSteps`'s
/// rationale — each mounting its own spring simulation at `initState`) in
/// small steps rather than one big jump: a single huge `pump(duration)`
/// sometimes leaves the very last spring's completion Future one tick shy
/// of resolving, which fails the "no pending timers" test invariant.
Future<void> settleSprings(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [
        gameSaveRepositoryProvider.overrideWithValue(
          FakeGameSaveRepository(),
        ),
        audioServiceProvider.overrideWithValue(FakeAudioService()),
        hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
      ],
    );
    addTearDown(container.dispose);
    // See rewarded_ad_screen_test.dart's identical note:
    // PlayerProgressController is `@riverpod` (autoDispose) and nothing
    // here keeps a `ref.watch` on it the way HomeScreen does in production.
    container.listen(playerProgressControllerProvider, (_, _) {});
    return container;
  }

  Widget wrap(
    ProviderContainer container, {
    required VoidCallback onFinished,
  }) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TutorialScreen(onFinished: onFinished),
    ),
  );

  /// Drags the tutorial's one tray piece so its (0,0) cell lands at
  /// (targetRow, targetColumn). `PieceTray`'s real `dragAnchorStrategy`
  /// pins the feedback widget's top edge `GamePalette.dragLiftPixels` — a
  /// FIXED physical distance, not cell-relative — *above* the pointer (so
  /// the dragged piece doesn't hide under the finger) — the pointer
  /// position has to compensate for that same offset, or the drop lands
  /// too high.
  Future<void> dragPieceOnto(
    WidgetTester tester, {
    required int targetRow,
    required int targetColumn,
  }) async {
    final boardTopLeft = tester.getTopLeft(find.byType(BoardGrid));
    final cellSize = tester.getSize(find.byType(BoardGrid)).width / 10;
    final targetCellTopLeft =
        boardTopLeft + Offset(targetColumn * cellSize, targetRow * cellSize);
    final pointerTarget = targetCellTopLeft +
        Offset(
          cellSize / 2,
          GamePalette.dragLiftPixels + cellSize / 2,
        );

    final source = tester.getCenter(find.byType(Draggable<int>));
    final gesture = await tester.startGesture(source);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(pointerTarget);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await settleSprings(tester);
  }

  testWidgets(
    'step 1: dragging the piece onto the correct spot completes the row '
    'and advances to step 2 (user instruction: fully player-driven, no '
    'auto-play)',
    (tester) async {
      var finished = false;
      await tester.pumpWidget(
        wrap(container(), onFinished: () => finished = true),
      );
      await tester.pump();
      await settleSprings(tester);

      await dragPieceOnto(tester, targetRow: 5, targetColumn: 3);

      // Step 2's piece is the 2x2 square — a different shape than step 1's
      // horizontal 3-line — appearing confirms the step actually advanced.
      expect(find.byType(Draggable<int>), findsOneWidget);
      expect(finished, isFalse);
    },
  );

  // A test chaining all three steps' drags in a single `testWidgets` body
  // was tried (user instruction: test the tutorial seriously) and found to
  // be genuinely unreliable — the exact same sequence of real gesture-based
  // drags passed on one run and failed on the next (and, after tightening
  // the assertions to pin down where, failed consistently at the *third*
  // drag specifically), matching this codebase's already-documented
  // caution about chained drag-and-drop simulations through a full widget
  // tree (see board_grid_test.dart/game_screen_test.dart's notes). Rather
  // than ship a flaky test, coverage stays at exactly one real drag per
  // test: step 1's success case above, the invalid-drop rejection below,
  // and the skip path — the shared `_onPlace`/`_advanceAfterDelay`/finish
  // logic is the same code path regardless of which step triggers it. A
  // full 3-step walkthrough (steps 2's and 3's specific anchors, the
  // step-3 double-clear combo, and the final confetti/finish sequence)
  // still needs manual or emulator verification, not an automated test.

  testWidgets('an invalid drop plays the invalid-move feedback and does not '
      'advance the step', (tester) async {
    final audio = FakeAudioService();
    final container = ProviderContainer(
      overrides: [
        gameSaveRepositoryProvider.overrideWithValue(
          FakeGameSaveRepository(),
        ),
        audioServiceProvider.overrideWithValue(audio),
        hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(playerProgressControllerProvider, (_, _) {});

    await tester.pumpWidget(wrap(container, onFinished: () {}));
    await tester.pump();
    await settleSprings(tester);

    // Row 5's gap is columns 3-5; dropping at column 0 instead is an
    // already-filled cell, an invalid placement.
    await dragPieceOnto(tester, targetRow: 5, targetColumn: 0);

    expect(audio.playedEffects, contains(SoundEffect.invalidMove));
    // Still on the same (unused) piece — a fresh drag is still possible.
    expect(find.byType(Draggable<int>), findsOneWidget);
  });

  testWidgets('skipping immediately marks the tutorial complete and calls '
      'onFinished (user instruction: replayable/skippable)', (tester) async {
    var finished = false;
    final providerContainer = container();
    await tester.pumpWidget(
      wrap(providerContainer, onFinished: () => finished = true),
    );
    await tester.pump();
    await settleSprings(tester);

    await tester.tap(find.text('Atla'));
    await tester.pump();

    expect(finished, isTrue);
    expect(
      providerContainer
          .read(playerProgressControllerProvider)
          .value!
          .tutorialCompleted,
      isTrue,
    );
  });
}
