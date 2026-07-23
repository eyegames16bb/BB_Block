import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/scoring/domain/level_scoring_strategy.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

final class LevelModeStrategy implements GameModeStrategy {
  const LevelModeStrategy();

  @override
  ScoringStrategy get scoringStrategy => const LevelScoringStrategy();

  @override
  GameModeType get type => GameModeType.level;

  @override
  RoundOutcome evaluateOutcome({
    required int currentScore,
    required bool hasAnyValidPlacement,
  }) {
    if (currentScore >= LevelModeConstants.targetScore) {
      return const RoundOutcome.levelComplete();
    }
    if (!hasAnyValidPlacement) {
      return const RoundOutcome.levelFailed();
    }
    return const RoundOutcome.ongoing();
  }
}
