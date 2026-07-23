import 'package:bb_block/core/constants/app_constants.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_progress.freezed.dart';
part 'player_progress.g.dart';

@freezed
abstract class PlayerProgress with _$PlayerProgress {
  const factory PlayerProgress({
    @Default(0) int classicHighScoreFramed,
    @Default(0) int classicHighScoreFrameless,
    @Default(1) int currentLevel,
    @Default(0) int goldKeyCount,
    @Default(BoosterConstants.defaultRotateCharges) int rotateCharges,
    @Default(BoosterConstants.defaultSwapCharges) int swapCharges,
    @Default(BoosterConstants.defaultSingleCellRemoveCharges)
    int singleCellRemoveCharges,
  }) = _PlayerProgress;

  factory PlayerProgress.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressFromJson(json);
}
