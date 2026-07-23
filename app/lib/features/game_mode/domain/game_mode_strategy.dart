import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

enum GameModeType { classic, level }

abstract interface class GameModeStrategy {
  GameModeType get type;

  ScoringStrategy get scoringStrategy;

  RoundOutcome evaluateOutcome({
    required int currentScore,
    required bool hasAnyValidPlacement,
  });
}
