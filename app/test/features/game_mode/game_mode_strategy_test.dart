import 'package:bb_block/features/game_mode/domain/classic_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/level_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassicModeStrategy', () {
    test('framed option starts on a framed board, frameless on an empty one',
        () {
      expect(ClassicModeStrategy(hasFrame: true).createInitialBoard().hasFrame,
          isTrue);
      expect(ClassicModeStrategy(hasFrame: false).createInitialBoard().hasFrame,
          isFalse);
    });

    test('never removes its frame, whatever the score', () {
      final strategy = ClassicModeStrategy(hasFrame: true);
      expect(strategy.shouldRemoveFrameAt(0), isFalse);
      expect(strategy.shouldRemoveFrameAt(100000), isFalse);
    });

    test('ends the round only when no placement remains', () {
      final strategy = ClassicModeStrategy(hasFrame: false);
      expect(
        strategy.evaluateOutcome(currentScore: 50, hasAnyValidPlacement: true),
        const RoundOutcome.ongoing(),
      );
      expect(
        strategy.evaluateOutcome(currentScore: 50, hasAnyValidPlacement: false),
        const RoundOutcome.classicGameOver(),
      );
    });
  });

  group('LevelModeStrategy', () {
    const strategy = LevelModeStrategy();

    test('always starts on a framed board', () {
      expect(strategy.createInitialBoard().hasFrame, isTrue);
    });

    test('removes the frame at and after 900 points', () {
      expect(strategy.shouldRemoveFrameAt(899), isFalse);
      expect(strategy.shouldRemoveFrameAt(900), isTrue);
    });

    test('completes at 1000 points regardless of remaining moves', () {
      expect(
        strategy.evaluateOutcome(
            currentScore: 1000, hasAnyValidPlacement: false),
        const RoundOutcome.levelComplete(),
      );
    });

    test('fails when stuck below the target', () {
      expect(
        strategy.evaluateOutcome(
          currentScore: 500,
          hasAnyValidPlacement: false,
        ),
        const RoundOutcome.levelFailed(),
      );
    });

    test('stays ongoing while moves remain below the target', () {
      expect(
        strategy.evaluateOutcome(currentScore: 500, hasAnyValidPlacement: true),
        const RoundOutcome.ongoing(),
      );
    });
  });
}
