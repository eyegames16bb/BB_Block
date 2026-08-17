import 'package:bb_block/core/providers/ads_providers.dart';
import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BbBlockApp extends ConsumerWidget {
  const BbBlockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // App Store rejection fix (Guideline 2.1, real review on iPadOS): the
    // ATT permission request inside `AdMobAdsService.init()` was correctly
    // written but never actually ran — `adsServiceProvider` (a plain,
    // lazily-initialized Riverpod Provider) was never read anywhere in the
    // widget tree, since the rewarded-ad UI uses an in-house fake ad screen
    // instead of the real AdMob service. The app's own privacy manifest
    // declares tracking (NSPrivacyTracking=true, google_mobile_ads bundled),
    // so Apple's reviewer expected — and never saw — the ATT prompt. Reading
    // the provider here (once, on app start, before any ad is shown) forces
    // the lazy `AdMobAdsService()` + `.init()` to actually run.
    ref.read(adsServiceProvider);

    // `.select` narrows the watch to just `languageCode` — without it, this
    // root widget (wrapping the whole `MaterialApp.router`, i.e. every
    // screen) rebuilt on every `PlayerProgress` mutation anywhere in the
    // app (score updates, gold key spends, booster unlocks, ...), not just
    // language changes.
    final languageCode = ref.watch(
      playerProgressControllerProvider.select(
        (async) => async.value?.languageCode ?? 'tr',
      ),
    );

    return MaterialApp.router(
      title: 'BB Block',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
      locale: Locale(languageCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
