import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_launch_config.freezed.dart';

/// The choices made before a round starts, carried into the game screen and
/// used to build the right [GameModeStrategy]. Value equality (from Freezed)
/// lets this double as the game controller's provider-family key.
@freezed
abstract class GameLaunchConfig with _$GameLaunchConfig {
  const factory GameLaunchConfig({
    required GameModeType mode,
    @Default(false) bool classicHasFrame,
  }) = _GameLaunchConfig;
}
