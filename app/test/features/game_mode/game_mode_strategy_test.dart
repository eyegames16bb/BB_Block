import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
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

    test(
        'the framed board is a 10x10 grid with an 8x8 interior — not a '
        'separately-sized smaller board', () {
      final board = ClassicModeStrategy(hasFrame: true).createInitialBoard();

      expect(board.size, 10);
      // Every border cell is frame, every interior cell is empty — an 8x8
      // playable area inside the 10x10 grid.
      for (var row = 0; row < board.size; row++) {
        for (var column = 0; column < board.size; column++) {
          final position = GridPosition(row: row, column: column);
          final isBorder = row == 0 ||
              row == board.size - 1 ||
              column == 0 ||
              column == board.size - 1;
          expect(
            board.cellAt(position),
            isBorder ? CellState.frame : CellState.empty,
          );
        }
      }
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

    test('removes the frame at and after 750 points', () {
      expect(strategy.shouldRemoveFrameAt(749), isFalse);
      expect(strategy.shouldRemoveFrameAt(750), isTrue);
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
