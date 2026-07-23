import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'board.freezed.dart';

@freezed
abstract class Board with _$Board {
  const factory Board({
    required int size,
    required List<CellState> cells,
  }) = _Board;

  const Board._();

  factory Board.empty({int size = BoardConstants.gridSize}) => Board(
        size: size,
        cells: List.filled(size * size, CellState.empty),
      );

  factory Board.framed({int size = BoardConstants.gridSize}) {
    final cells = List.filled(size * size, CellState.empty);
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        final isBorder =
            row == 0 || row == size - 1 || column == 0 || column == size - 1;
        if (isBorder) {
          cells[row * size + column] = CellState.frame;
        }
      }
    }
    return Board(size: size, cells: cells);
  }

  int indexOf(GridPosition position) => position.row * size + position.column;

  bool isInside(GridPosition position) =>
      position.row >= 0 &&
      position.row < size &&
      position.column >= 0 &&
      position.column < size;

  CellState cellAt(GridPosition position) => cells[indexOf(position)];
}
