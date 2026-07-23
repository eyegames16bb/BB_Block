import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';

abstract interface class PlacementValidator {
  bool canPlace({
    required Board board,
    required PieceShape shape,
    required GridPosition anchor,
  });

  bool hasAnyValidPlacement({
    required Board board,
    required PieceShape shape,
  });
}

final class DefaultPlacementValidator implements PlacementValidator {
  const DefaultPlacementValidator();

  @override
  bool canPlace({
    required Board board,
    required PieceShape shape,
    required GridPosition anchor,
  }) {
    for (final offset in shape.cells) {
      final target = anchor.offsetBy(offset);
      if (!board.isInside(target)) return false;
      if (board.cellAt(target) != CellState.empty) return false;
    }
    return true;
  }

  @override
  bool hasAnyValidPlacement({
    required Board board,
    required PieceShape shape,
  }) {
    for (var row = 0; row < board.size; row++) {
      for (var column = 0; column < board.size; column++) {
        final anchor = GridPosition(row: row, column: column);
        if (canPlace(board: board, shape: shape, anchor: anchor)) return true;
      }
    }
    return false;
  }
}
