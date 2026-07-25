import 'package:bb_block/core/constants/app_constants.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_progress.freezed.dart';
part 'player_progress.g.dart';

/// Account-level progress. Booster charges live here (not in `GameSession`)
/// because they're a persistent resource, not an attempt-scoped one: a new
/// player starts with one of each, unused charges carry across levels and
/// app restarts, and the only way to gain more is spending a Gold Key on the
/// specific type you want (see `PlayerProgressController.refillBooster`).
/// Classic Mode never touches these fields — it has no boosters at all.
@freezed
abstract class PlayerProgress with _$PlayerProgress {
  const factory PlayerProgress({
    @Default(0) int classicHighScoreFramed,
    @Default(0) int classicHighScoreFrameless,
    @Default(1) int currentLevel,
    @Default(GoldKeyConstants.startingGoldKeyCount) int goldKeyCount,
    @Default(true) bool soundEnabled,
    @Default(true) bool hapticsEnabled,
    @Default(BoosterConstants.defaultRotateCharges) int rotateCharges,
    @Default(BoosterConstants.defaultSwapCharges) int swapCharges,
    @Default(BoosterConstants.defaultSingleCellRemoveCharges)
    int singleCellRemoveCharges,
  }) = _PlayerProgress;

  factory PlayerProgress.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressFromJson(json);
}
