import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

enum GameModeType { classic, level }

abstract interface class GameModeStrategy {
  GameModeType get type;

  ScoringStrategy get scoringStrategy;

  /// The board a fresh session of this mode starts from — framed or empty
  /// depending on the mode and its options.
  Board createInitialBoard();

  /// Whether the border frame should be torn down now that the player has
  /// reached [score]. Classic mode keeps its frame permanently (always
  /// false); Level mode strips it once the 750-point threshold is passed.
  bool shouldRemoveFrameAt(int score);

  RoundOutcome evaluateOutcome({
    required int currentScore,
    required bool hasAnyValidPlacement,
  });
}
