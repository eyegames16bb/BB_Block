import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_audio_service.dart';
import '../../support/fake_game_save_repository.dart';
import '../../support/fake_haptics_service.dart';

void main() {
  // `build()` syncs the loaded sound/haptics preference straight into the
  // audio/haptics services (see player_progress_controller.dart), so the
  // real `audioplayers`/`vibration`-backed implementations must be swapped
  // for fakes here — they touch platform channels that need a widget test
  // binding this plain `test()` file never initializes.
  ProviderContainer containerWith(FakeGameSaveRepository repo) {
    final container = ProviderContainer(
      overrides: [
        gameSaveRepositoryProvider.overrideWithValue(repo),
        audioServiceProvider.overrideWithValue(FakeAudioService()),
        hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('keeps the higher classic score and ignores a lower one', () async {
    final container = containerWith(FakeGameSaveRepository());
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    await controller.recordClassicScore(hasFrame: false, score: 120);
    await controller.recordClassicScore(hasFrame: false, score: 80);

    final progress = container.read(playerProgressControllerProvider).value!;
    expect(progress.classicHighScoreFrameless, 120);
  });

  test('tracks framed and frameless bests independently', () async {
    final container = containerWith(FakeGameSaveRepository());
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    await controller.recordClassicScore(hasFrame: true, score: 50);
    await controller.recordClassicScore(hasFrame: false, score: 90);

    final progress = container.read(playerProgressControllerProvider).value!;
    expect(progress.classicHighScoreFramed, 50);
    expect(progress.classicHighScoreFrameless, 90);
  });

  test('advanceLevel increments and persists through the repository', () async {
    final repo = FakeGameSaveRepository();
    final container = containerWith(repo);
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    await controller.advanceLevel();

    expect(
      container.read(playerProgressControllerProvider).value!.currentLevel,
      2,
    );
    expect((await repo.load()).currentLevel, 2);
  });

  test('grantGoldKey increments the persisted count', () async {
    final container = containerWith(FakeGameSaveRepository());
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    await controller.grantGoldKey();
    await controller.grantGoldKey();

    expect(
      container.read(playerProgressControllerProvider).value!.goldKeyCount,
      2,
    );
  });

  test('spendGoldKey succeeds and decrements when a key is available',
      () async {
    final container = containerWith(
      FakeGameSaveRepository(const PlayerProgress(goldKeyCount: 1)),
    );
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    final spent = await controller.spendGoldKey();

    expect(spent, isTrue);
    expect(
      container.read(playerProgressControllerProvider).value!.goldKeyCount,
      0,
    );
  });

  test('spendGoldKey fails and leaves state untouched with zero keys',
      () async {
    final container = containerWith(FakeGameSaveRepository());
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    final spent = await controller.spendGoldKey();

    expect(spent, isFalse);
    expect(
      container.read(playerProgressControllerProvider).value!.goldKeyCount,
      0,
    );
  });
}
