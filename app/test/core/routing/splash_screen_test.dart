import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/routing/splash_screen.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_game_save_repository.dart';
import '../../support/fake_round_save_repository.dart';

void main() {
  Widget wrap({PlayerProgress? progress}) => ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            FakeGameSaveRepository(
              progress ?? const PlayerProgress(tutorialCompleted: true),
            ),
          ),
          roundSaveRepositoryProvider.overrideWithValue(
            FakeRoundSaveRepository(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashScreen(),
        ),
      );

  testWidgets(
      'shows the full-screen EyeGames logo first (user instruction), still '
      'showing just under 3 seconds in', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/eyegames_logo.png',
    );
    expect(image.fit, BoxFit.cover);

    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.byType(Image), findsOneWidget);
    // Nothing from StartupGate's own content has appeared yet.
    expect(find.text('Klasik Mod'), findsNothing);
  });

  testWidgets(
      'hands off to StartupGate after exactly 3 seconds (user instruction: '
      '"3 saniye durduktan sonra oyun giriş ana ekranı gelebilir")',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Not `find.byType(Image), findsNothing` — HomeScreen has its own
    // background `Image` (a different asset, and one that's now wrapped in
    // a `ResizeImage` rather than a bare `AssetImage` since it's decoded
    // via `cacheWidth`/`cacheHeight` — hence the `is AssetImage` guard
    // below instead of an unchecked cast); only the splash logo
    // specifically should be gone.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/eyegames_logo.png',
      ),
      findsNothing,
    );
    expect(find.text('Klasik Mod'), findsOneWidget);
  });
}
