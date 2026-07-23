import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_fixtures.dart';

void main() {
  group('Board factories', () {
    test('empty board has no filled or frame cells', () {
      final board = Board.empty(size: 4);

      expect(board.cells.length, 16);
      expect(board.cells.every((cell) => cell == CellState.empty), isTrue);
      expect(board.hasFrame, isFalse);
    });

    test('framed board rings the border and leaves the interior empty', () {
      final board = Board.framed(size: 4);

      expect(board.hasFrame, isTrue);
      expect(board.cellAt(const GridPosition(row: 0, column: 0)),
          CellState.frame);
      expect(board.cellAt(const GridPosition(row: 3, column: 3)),
          CellState.frame);
      expect(board.cellAt(const GridPosition(row: 1, column: 1)),
          CellState.empty);
    });
  });

  test('place marks the shape cells filled at the anchor', () {
    final board = Board.empty(size: 4);
    final lShape = shapeById(PieceShapeId.lTriomino0);

    final placed = board.place(lShape, const GridPosition(row: 1, column: 1));

    for (final offset in lShape.cells) {
      final target = const GridPosition(row: 1, column: 1).offsetBy(offset);
      expect(placed.cellAt(target), CellState.filled);
    }
    // Original board is untouched (immutability).
    expect(board.cells.every((cell) => cell == CellState.empty), isTrue);
  });

  test('withFrameRemoved turns frame cells empty but keeps filled ones', () {
    final board = boardFromRows([
      '####',
      '#XX#',
      '#..#',
      '####',
    ]);

    final result = board.withFrameRemoved();

    expect(result.hasFrame, isFalse);
    expect(result.cellAt(const GridPosition(row: 1, column: 1)),
        CellState.filled);
    expect(result.cellAt(const GridPosition(row: 0, column: 0)),
        CellState.empty);
  });
}
