import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/analytics_providers.dart';
import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/providers/review_providers.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/rewarded_ad/presentation/rewarded_ad_screen.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../support/fake_analytics_service.dart';
import '../../support/fake_audio_service.dart';
import '../../support/fake_game_save_repository.dart';
import '../../support/fake_haptics_service.dart';
import '../../support/fake_review_service.dart';

void main() {
  // `PlayerProgressController.build()` touches both services (to sync a
  // persisted mute preference) — without fakes here, the real
  // platform-channel-backed implementations throw under `flutter test`.
  late FakeAnalyticsService analyticsService;
  late FakeReviewService reviewService;
  ProviderContainer container() {
    analyticsService = FakeAnalyticsService();
    reviewService = FakeReviewService();
    final container = ProviderContainer(
      overrides: [
        gameSaveRepositoryProvider.overrideWithValue(
          FakeGameSaveRepository(),
        ),
        audioServiceProvider.overrideWithValue(FakeAudioService()),
        hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
        analyticsServiceProvider.overrideWithValue(analyticsService),
        reviewServiceProvider.overrideWithValue(reviewService),
      ],
    );
    addTearDown(container.dispose);
    // `PlayerProgressController` is `@riverpod` (autoDispose). In production
    // it stays alive because `HomeScreen` underneath keeps a `ref.watch` on
    // it while `RewardedAdScreen` is pushed on top — nothing in this test
    // harness does that, so without a subscription here the provider gets
    // disposed right after the initial `.future` read completes and silently
    // rebuilds (back to `AsyncLoading`) the next time anything reads it.
    container.listen(playerProgressControllerProvider, (_, _) {});
    return container;
  }

  Widget wrap(ProviderContainer container, {required Widget home}) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          // Pinned rather than left to the test platform's default locale
          // (which resolves to 'en', one of our supported locales) — this
          // screen doesn't itself read `PlayerProgress.languageCode` (only
          // `BbBlockApp` binds that), so Turkish assertions here need an
          // explicit locale.
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  Widget openerHarness(ProviderContainer container) => wrap(
        container,
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RewardedAdScreen(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  testWidgets(
      'plays for 20 seconds with a spinner, then shows a close button — '
      'user instruction: 20s test ad, spinning loading icon, X to close',
      (tester) async {
    await tester.pumpWidget(openerHarness(container()));
    await tester.tap(find.text('open'));
    // Not pumpAndSettle(): the spin controller runs a real 20s animation,
    // and settling would fast-forward straight through the whole ad — a
    // bounded pump just clears the page-push transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.x), findsNothing);

    // ~300ms already elapsed (the push transition pumps above) — budget
    // the rest so the running total lands just under, then just over, 20s.
    await tester.pump(const Duration(seconds: 19, milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(PhosphorIconsBold.x), findsOneWidget);
  });

  testWidgets(
      'shows a numeric countdown that ticks down from the full ad duration '
      '(user instruction: a visible countdown synced to the wait, and a '
      'rotating loading ring tied to it rather than a plain indeterminate '
      'spinner)', (tester) async {
    await tester.pumpWidget(openerHarness(container()));
    await tester.tap(find.text('open'));
    // Clears the page-push transition first, same as the other tests in
    // this file — the countdown text isn't reliably found until then.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Well under a second in (~300ms elapsed) — still the full duration.
    expect(find.text('20'), findsOneWidget);

    // A little over one second in total — the countdown should have
    // ticked down by exactly one, and the ring should still be the same
    // determinate indicator (not swapped out for a different widget).
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('19'), findsOneWidget);
    expect(find.text('20'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 18, milliseconds: 500));
    expect(find.text('1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    // The ad has ended — the countdown text is gone, replaced by the
    // close (X) button.
    expect(find.text('1'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.byIcon(PhosphorIconsBold.x), findsOneWidget);
  });

  testWidgets(
      'closing the ad grants a Gold Key immediately, requests the real '
      'native store review prompt, and returns straight to the previous '
      'screen — the old fake 5-star "rate us" screen was removed (user '
      'instruction: no fake prompt, a real one instead)', (tester) async {
    final providerContainer = container();
    await providerContainer.read(playerProgressControllerProvider.future);

    await tester.pumpWidget(openerHarness(providerContainer));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pump(const Duration(seconds: 20, milliseconds: 100));
    await tester.tap(find.byIcon(PhosphorIconsBold.x));
    await tester.pumpAndSettle();

    // Back to the opener screen directly — no rating UI of our own ever
    // appeared.
    expect(find.text('open'), findsOneWidget);
    expect(
      providerContainer
          .read(playerProgressControllerProvider)
          .value!
          .goldKeyCount,
      GoldKeyConstants.startingGoldKeyCount + GoldKeyConstants.rewardedAdCoins,
    );
    // eyegames.net admin dashboard's ad-view counter — logged at the same
    // moment as the reward.
    expect(analyticsService.rewardedAdViewCount, 1);
    // The real platform review prompt was requested exactly once.
    expect(reviewService.requestCount, 1);
  });
}
