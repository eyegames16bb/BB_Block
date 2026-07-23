import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/scoring/domain/classic_scoring_strategy.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

final class ClassicModeStrategy implements GameModeStrategy {
  ClassicModeStrategy({required bool hasFrame})
      : scoringStrategy = ClassicScoringStrategy(hasFrame: hasFrame);

  @override
  final ScoringStrategy scoringStrategy;

  @override
  GameModeType get type => GameModeType.classic;

  @override
  RoundOutcome evaluateOutcome({
    required int currentScore,
    required bool hasAnyValidPlacement,
  }) =>
      hasAnyValidPlacement
          ? const RoundOutcome.ongoing()
          : const RoundOutcome.classicGameOver();
}
