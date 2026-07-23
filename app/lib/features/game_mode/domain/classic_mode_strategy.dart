import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/scoring/domain/classic_scoring_strategy.dart';
import 'package:bb_block/features/scoring/domain/scoring_strategy.dart';

final class ClassicModeStrategy implements GameModeStrategy {
  ClassicModeStrategy({required this.hasFrame})
      : scoringStrategy = ClassicScoringStrategy(hasFrame: hasFrame);

  final bool hasFrame;

  @override
  final ScoringStrategy scoringStrategy;

  @override
  GameModeType get type => GameModeType.classic;

  @override
  Board createInitialBoard() =>
      hasFrame ? Board.framed() : Board.empty();

  /// The classic frame is permanent — the GDD is explicit that it stays until
  /// the board fills up ("Silinmeyecektir").
  @override
  bool shouldRemoveFrameAt(int score) => false;

  @override
  RoundOutcome evaluateOutcome({
    required int currentScore,
    required bool hasAnyValidPlacement,
  }) =>
      hasAnyValidPlacement
          ? const RoundOutcome.ongoing()
          : const RoundOutcome.classicGameOver();
}
