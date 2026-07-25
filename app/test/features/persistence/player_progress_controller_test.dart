import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/features/booster/domain/booster_kind.dart';
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

  test(
      'advanceLevel does not grant a Gold Key before the milestone is '
      'reached', () async {
    final container = containerWith(FakeGameSaveRepository());
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    for (var i = 0; i < GoldKeyConstants.levelsPerGoldKeyReward - 1; i++) {
      await controller.advanceLevel();
    }

    expect(
      container.read(playerProgressControllerProvider).value!.goldKeyCount,
      0,
    );
  });

  test(
      'advanceLevel grants a free Gold Key every '
      'levelsPerGoldKeyReward completed levels', () async {
    final container = containerWith(FakeGameSaveRepository());
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    for (var i = 0; i < GoldKeyConstants.levelsPerGoldKeyReward; i++) {
      await controller.advanceLevel();
    }

    final progress = container.read(playerProgressControllerProvider).value!;
    expect(progress.currentLevel, 1 + GoldKeyConstants.levelsPerGoldKeyReward);
    expect(progress.goldKeyCount, 1);

    // A second full cycle grants a second key.
    for (var i = 0; i < GoldKeyConstants.levelsPerGoldKeyReward; i++) {
      await controller.advanceLevel();
    }
    expect(
      container.read(playerProgressControllerProvider).value!.goldKeyCount,
      2,
    );
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

  test('syncBoosterCharges writes back all three charge counts', () async {
    final container = containerWith(FakeGameSaveRepository());
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    await controller.syncBoosterCharges(
      rotate: 0,
      swap: 2,
      singleCellRemove: 1,
    );

    final progress = container.read(playerProgressControllerProvider).value!;
    expect(progress.rotateCharges, 0);
    expect(progress.swapCharges, 2);
    expect(progress.singleCellRemoveCharges, 1);
  });

  test('refillBooster spends one key and adds one charge of the chosen kind',
      () async {
    final container = containerWith(
      FakeGameSaveRepository(
        const PlayerProgress(goldKeyCount: 1, rotateCharges: 0),
      ),
    );
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    final refilled = await controller.refillBooster(BoosterKind.rotate);

    expect(refilled, isTrue);
    final progress = container.read(playerProgressControllerProvider).value!;
    expect(progress.rotateCharges, 1);
    expect(progress.goldKeyCount, 0);
  });

  test('refillBooster fails and leaves charges untouched with zero keys',
      () async {
    final container = containerWith(FakeGameSaveRepository());
    await container.read(playerProgressControllerProvider.future);
    final controller =
        container.read(playerProgressControllerProvider.notifier);

    final refilled = await controller.refillBooster(BoosterKind.swap);

    expect(refilled, isFalse);
    final progress = container.read(playerProgressControllerProvider).value!;
    expect(progress.swapCharges, const PlayerProgress().swapCharges);
    expect(progress.goldKeyCount, 0);
  });
}
