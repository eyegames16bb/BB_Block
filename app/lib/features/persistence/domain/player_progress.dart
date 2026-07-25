import 'package:bb_block/core/constants/app_constants.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_progress.freezed.dart';
part 'player_progress.g.dart';

/// Account-level progress. Booster charges are deliberately *not* stored
/// here — they're an attempt-scoped resource now, not a persistent one: at
/// the start of each Level Mode round the player either spends one Gold Key
/// for one charge of every booster that round only, or plays with none
/// (see `HomeScreen`'s start sheet and `GameLaunchConfig.
/// levelBoostersUnlocked`). Unused charges are lost at round end and
/// nothing mid-round can add more. Classic Mode never has boosters at all.
@freezed
abstract class PlayerProgress with _$PlayerProgress {
  const factory PlayerProgress({
    @Default(0) int classicHighScoreFramed,
    @Default(0) int classicHighScoreFrameless,
    @Default(1) int currentLevel,
    @Default(GoldKeyConstants.startingGoldKeyCount) int goldKeyCount,
    @Default(true) bool soundEnabled,
    @Default(true) bool hapticsEnabled,
  }) = _PlayerProgress;

  factory PlayerProgress.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressFromJson(json);
}
