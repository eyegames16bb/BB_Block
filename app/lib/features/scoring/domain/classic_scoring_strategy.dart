import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

final class ClassicScoringStrategy implements ScoringStrategy {
  const ClassicScoringStrategy({required this.hasFrame});

  final bool hasFrame;

  @override
  int pointsPerClearedLine({required int scoreBeforeClear}) => hasFrame
      ? ScoringConstants.classicFramedLineScore
      : ScoringConstants.classicFramelessLineScore;
}
