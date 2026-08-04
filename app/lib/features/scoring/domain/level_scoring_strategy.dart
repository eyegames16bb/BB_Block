import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

final class LevelScoringStrategy implements ScoringStrategy {
  const LevelScoringStrategy();

  @override
  int pointsForClear({required int lineCount, required int scoreBeforeClear}) {
    if (scoreBeforeClear >= LevelModeConstants.frameRemovalThreshold) {
      // Unchanged, original flat-rate model — user instruction: "the
      // current scoring system continues" once the frame is gone.
      return lineCount * ScoringConstants.levelPostThresholdLineScore;
    }
    const table = ScoringConstants.standardClearPoints;
    return table[lineCount.clamp(0, table.length - 1)];
  }

  @override
  int comboBonusPoints({required int scoreBeforeClear}) =>
      scoreBeforeClear >= LevelModeConstants.frameRemovalThreshold
          ? 0
          : ScoringConstants.standardComboBonus;
}
