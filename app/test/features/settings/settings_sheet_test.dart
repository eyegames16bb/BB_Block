import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/providers/url_launcher_providers.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/settings/presentation/settings_sheet.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_audio_service.dart';
import '../../support/fake_game_save_repository.dart';
import '../../support/fake_haptics_service.dart';
import '../../support/fake_url_launcher_service.dart';

void main() {
  // Mirrors `BbBlockApp`'s real `locale: Locale(progress.languageCode)`
  // binding — without it, tapping the EN option would persist the
  // preference but nothing in this isolated harness would react to it.
  Widget wrap(FakeUrlLauncherService urlLauncher) => ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            FakeGameSaveRepository(),
          ),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
          hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
          urlLauncherServiceProvider.overrideWithValue(urlLauncher),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final languageCode = ref
                    .watch(playerProgressControllerProvider)
                    .value
                    ?.languageCode ??
                'tr';
            return MaterialApp(
              locale: Locale(languageCode),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: SettingsSheet()),
            );
          },
        ),
      );

  testWidgets(
      'the developer (HAYB) credit row is gone (removed, user instruction) '
      '— only the publisher credit remains', (tester) async {
    await tester.pumpWidget(wrap(FakeUrlLauncherService()));

    expect(find.text('HAYB'), findsNothing);
    expect(find.text(CreditsConstants.publisherName), findsOneWidget);
  });

  testWidgets(
      'tapping the publisher credit opens the EYE Games link '
      '(user instruction)', (tester) async {
    final urlLauncher = FakeUrlLauncherService();
    await tester.pumpWidget(wrap(urlLauncher));

    await tester.tap(find.text(CreditsConstants.publisherName));
    await tester.pump();

    expect(urlLauncher.launchedUrls, [CreditsConstants.publisherUrl]);
  });

  testWidgets(
      'the Vibration toggle is gone (removed again, user instruction) — '
      'only the Sound switch remains, and haptics keep working under the '
      'hood regardless', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            FakeGameSaveRepository(),
          ),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
          hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsSheet()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Titreşim'), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets(
      'defaults to Turkish and switches to English immediately when EN is '
      'tapped (user instruction: full TR/EN support)', (tester) async {
    await tester.pumpWidget(wrap(FakeUrlLauncherService()));

    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Ses'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Ayarlar'), findsNothing);
  });
}
