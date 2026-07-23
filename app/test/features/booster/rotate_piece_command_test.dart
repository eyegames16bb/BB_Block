import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/booster/domain/rotate_piece_command.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_fixtures.dart';

void main() {
  const command = RotatePieceCommand();

  test('rotates an L-triomino 90 degrees clockwise, re-anchored to origin', () {
    // Original L:      Expected after 90° CW:
    //   X .              X X
    //   X X              X .
    final lShape = shapeById(PieceShapeId.lTriomino0);

    final rotated = command.execute(lShape);

    expect(
      rotated.cells.toSet(),
      {
        const GridPosition(row: 0, column: 0),
        const GridPosition(row: 0, column: 1),
        const GridPosition(row: 1, column: 0),
      },
    );
  });

  test('four rotations return to the original shape', () {
    final original = shapeById(PieceShapeId.lTriomino0);

    var shape = original;
    for (var i = 0; i < 4; i++) {
      shape = command.execute(shape);
    }

    expect(shape.cells.toSet(), original.cells.toSet());
  });

  test('rotated cells never contain negative coordinates', () {
    for (final shape in PieceShapeCatalog.all) {
      final rotated = command.execute(shape);
      for (final cell in rotated.cells) {
        expect(cell.row, greaterThanOrEqualTo(0));
        expect(cell.column, greaterThanOrEqualTo(0));
      }
    }
  });
}
