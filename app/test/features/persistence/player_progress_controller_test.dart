import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_game_save_repository.dart';

void main() {
  ProviderContainer containerWith(FakeGameSaveRepository repo) {
    final container = ProviderContainer(
      overrides: [gameSaveRepositoryProvider.overrideWithValue(repo)],
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
}
