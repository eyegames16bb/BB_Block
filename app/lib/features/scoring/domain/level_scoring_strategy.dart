import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

final class LevelScoringStrategy implements ScoringStrategy {
  const LevelScoringStrategy();

  @override
  int pointsPerClearedLine({required int scoreBeforeClear}) =>
      scoreBeforeClear >= LevelModeConstants.frameRemovalThreshold
          ? ScoringConstants.levelPostThresholdLineScore
          : ScoringConstants.levelPreThresholdLineScore;
}
