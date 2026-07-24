import 'package:bb_block/app.dart';
import 'package:bb_block/core/providers/ads_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ads_service.dart';
import 'support/fake_game_save_repository.dart';

void main() {
  Widget appWith(FakeAdsService ads) => ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            FakeGameSaveRepository(),
          ),
          adsServiceProvider.overrideWithValue(ads),
        ],
        child: const BbBlockApp(),
      );

  testWidgets('home screen shows the game title and both mode buttons',
      (tester) async {
    await tester.pumpWidget(appWith(FakeAdsService()));

    expect(find.text('BB Block'), findsOneWidget);
    expect(find.text('Klasik Mod'), findsOneWidget);
    expect(find.text('Level Mod'), findsOneWidget);
  });

  testWidgets(
      'tapping the rewarded ad chip shows a snackbar when no ad is loaded',
      (tester) async {
    await tester.pumpWidget(appWith(FakeAdsService()));

    await tester.tap(find.text('Ödüllü Reklam'));
    await tester.pump();

    expect(
      find.text('Reklam henüz hazır değil, birazdan tekrar deneyin.'),
      findsOneWidget,
    );
  });

  testWidgets('watching a ready rewarded ad grants a gold key',
      (tester) async {
    await tester.pumpWidget(
      appWith(FakeAdsService(isRewardedAdReady: true)),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Ödüllü Reklam'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
  });
}
