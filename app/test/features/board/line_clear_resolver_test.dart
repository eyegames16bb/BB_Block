import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/services/line_clear_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_fixtures.dart';

void main() {
  const resolver = DefaultLineClearResolver();

  test('detects a completed row and a completed column together', () {
    final board = boardFromRows([
      'XXX',
      'X..',
      'X..',
    ]);

    final cleared = resolver.findCompletedLines(board);

    expect(cleared.rows, [0]);
    expect(cleared.columns, [0]);
    expect(cleared.lineCount, 2);
  });

  test('a border-only line is never counted as complete', () {
    // Top row is all frame; it must not be reported as a cleared line.
    final board = boardFromRows([
      '###',
      '.X.',
      '...',
    ]);

    final cleared = resolver.findCompletedLines(board);

    expect(cleared.isEmpty, isTrue);
  });

  test('clearing empties filled cells but preserves frame cells', () {
    final board = boardFromRows([
      '#XXXXXXX#',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
      '.........',
    ]);

    final cleared = resolver.findCompletedLines(board);
    expect(cleared.rows, [0]);

    final result = resolver.clearLines(board, cleared);

    expect(result.cellAt(const GridPosition(row: 0, column: 1)),
        CellState.empty);
    // Frame corners stay intact.
    expect(result.cellAt(const GridPosition(row: 0, column: 0)),
        CellState.frame);
    expect(result.cellAt(const GridPosition(row: 0, column: 8)),
        CellState.frame);
  });
}
