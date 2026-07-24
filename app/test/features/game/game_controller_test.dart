import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/game/application/game_controller.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_game_save_repository.dart';
import '../../support/fake_haptics_service.dart';

void main() {
  ProviderContainer containerWith(FakeHapticsService haptics) {
    final container = ProviderContainer(
      overrides: [
        gameSaveRepositoryProvider.overrideWithValue(
          FakeGameSaveRepository(),
        ),
        hapticsServiceProvider.overrideWithValue(haptics),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('placing a piece triggers a haptic pulse through the real wiring',
      () {
    final haptics = FakeHapticsService();
    final container = containerWith(haptics);
    const config = GameLaunchConfig(mode: GameModeType.classic);

    // Build the session (an empty board); every catalog shape fits at the
    // origin of an empty 9x9 board, so this is deterministic regardless of
    // which shape the real weighted generator drew.
    container.read(gameControllerProvider(config));
    final controller =
        container.read(gameControllerProvider(config).notifier);

    controller.placePiece(
      trayIndex: 0,
      anchor: const GridPosition(row: 0, column: 0),
    );

    expect(haptics.triggered, isNotEmpty);
  });

  test(
      'a booster refused in Classic Mode still triggers a light '
      'rejection pulse', () {
    final haptics = FakeHapticsService();
    final container = containerWith(haptics);
    const config = GameLaunchConfig(mode: GameModeType.classic);

    container.read(gameControllerProvider(config));
    final controller =
        container.read(gameControllerProvider(config).notifier);

    // Classic Mode never has boosters (boostersEnabled is always false for
    // it), so this is refused unconditionally — no board setup needed.
    controller.rotatePiece(0);

    expect(haptics.triggered, [HapticIntensity.light]);
  });
}
