import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';

/// Removes a single player-placed cell the user taps on the board. Frame
/// cells are never eligible — they must survive until the mode-specific
/// frame-removal rule triggers, not be erased by this booster.
final class SingleCellRemoveCommand {
  const SingleCellRemoveCommand();

  bool canExecute({required Board board, required GridPosition target}) =>
      board.isInside(target) && board.cellAt(target) == CellState.filled;

  Board execute({required Board board, required GridPosition target}) {
    if (!canExecute(board: board, target: target)) return board;

    final updatedCells = List<CellState>.from(board.cells);
    updatedCells[board.indexOf(target)] = CellState.empty;

    return board.copyWith(cells: updatedCells);
  }
}
