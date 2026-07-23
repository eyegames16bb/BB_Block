import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';

/// Rotates a piece 90 degrees clockwise and re-anchors it to the origin so
/// its cells stay non-negative and ready to place.
final class RotatePieceCommand {
  const RotatePieceCommand();

  PieceShape execute(PieceShape shape) {
    final rotated = [
      for (final cell in shape.cells)
        GridPosition(row: cell.column, column: -cell.row),
    ];

    final minRow = rotated.map((cell) => cell.row).reduce(
          (a, b) => a < b ? a : b,
        );
    final minColumn = rotated.map((cell) => cell.column).reduce(
          (a, b) => a < b ? a : b,
        );

    final normalized = [
      for (final cell in rotated)
        GridPosition(row: cell.row - minRow, column: cell.column - minColumn),
    ];

    return shape.copyWith(cells: normalized);
  }
}
