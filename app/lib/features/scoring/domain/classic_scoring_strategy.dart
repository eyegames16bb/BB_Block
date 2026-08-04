import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

final class ClassicScoringStrategy implements ScoringStrategy {
  const ClassicScoringStrategy({required this.hasFrame});

  final bool hasFrame;

  @override
  int pointsForClear({required int lineCount, required int scoreBeforeClear}) {
    final table = hasFrame
        ? ScoringConstants.standardClearPoints
        : ScoringConstants.classicFramelessClearPoints;
    final index = lineCount.clamp(0, table.length - 1);
    return table[index];
  }

  @override
  int comboBonusPoints({required int scoreBeforeClear}) => hasFrame
      ? ScoringConstants.standardComboBonus
      : ScoringConstants.classicFramelessComboBonus;
}
