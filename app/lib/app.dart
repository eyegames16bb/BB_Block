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
