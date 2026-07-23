import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_fixtures.dart';

void main() {
  const validator = DefaultPlacementValidator();

  test('canPlace rejects placements that spill outside the board', () {
    final board = boardFromRows(['..', '..']);
    final horizontalDomino = shapeById(PieceShapeId.dominoHorizontal);

    expect(
      validator.canPlace(
        board: board,
        shape: horizontalDomino,
        anchor: const GridPosition(row: 0, column: 1),
      ),
      isFalse,
    );
  });

  test('canPlace rejects overlap with filled or frame cells', () {
    final board = boardFromRows([
      '#..',
      '.X.',
      '...',
    ]);
    final single = shapeById(PieceShapeId.single);

    expect(
      validator.canPlace(
        board: board,
        shape: single,
        anchor: const GridPosition(row: 1, column: 1),
      ),
      isFalse,
    );
    expect(
      validator.canPlace(
        board: board,
        shape: single,
        anchor: const GridPosition(row: 0, column: 0),
      ),
      isFalse,
    );
    expect(
      validator.canPlace(
        board: board,
        shape: single,
        anchor: const GridPosition(row: 2, column: 2),
      ),
      isTrue,
    );
  });

  test('hasAnyValidPlacement is false when only isolated cells remain', () {
    final board = boardFromRows([
      'X.X',
      'XXX',
      'X.X',
    ]);
    final horizontalDomino = shapeById(PieceShapeId.dominoHorizontal);
    final verticalDomino = shapeById(PieceShapeId.dominoVertical);

    expect(
      validator.hasAnyValidPlacement(board: board, shape: horizontalDomino),
      isFalse,
    );
    expect(
      validator.hasAnyValidPlacement(board: board, shape: verticalDomino),
      isFalse,
    );
    expect(
      validator.hasAnyValidPlacement(
        board: board,
        shape: shapeById(PieceShapeId.single),
      ),
      isTrue,
    );
  });
}
