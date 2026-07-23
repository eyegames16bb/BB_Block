import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';

final class ClearedLines {
  const ClearedLines({required this.rows, required this.columns});

  final List<int> rows;
  final List<int> columns;

  bool get isEmpty => rows.isEmpty && columns.isEmpty;

  int get lineCount => rows.length + columns.length;
}

abstract interface class LineClearResolver {
  ClearedLines findCompletedLines(Board board);

  Board clearLines(Board board, ClearedLines lines);
}

/// Only cells in [CellState.filled] are ever cleared. A line made entirely of
/// [CellState.frame] cells (the untouched border) is never reported as
/// completed — frame teardown is a separate, explicit event (see Level Mode's
/// 900-point Frame Destroy rule), not a byproduct of ordinary line clearing.
final class DefaultLineClearResolver implements LineClearResolver {
  const DefaultLineClearResolver();

  @override
  ClearedLines findCompletedLines(Board board) {
    final rows = <int>[
      for (var row = 0; row < board.size; row++)
        if (_isLineComplete(board, _rowCells(board, row))) row,
    ];
    final columns = <int>[
      for (var column = 0; column < board.size; column++)
        if (_isLineComplete(board, _columnCells(board, column))) column,
    ];

    return ClearedLines(rows: rows, columns: columns);
  }

  @override
  Board clearLines(Board board, ClearedLines lines) {
    if (lines.isEmpty) return board;

    final updatedCells = List<CellState>.from(board.cells);

    for (final row in lines.rows) {
      for (final position in _rowCells(board, row)) {
        _clearIfFilled(board, updatedCells, position);
      }
    }
    for (final column in lines.columns) {
      for (final position in _columnCells(board, column)) {
        _clearIfFilled(board, updatedCells, position);
      }
    }

    return board.copyWith(cells: updatedCells);
  }

  void _clearIfFilled(
    Board board,
    List<CellState> updatedCells,
    GridPosition position,
  ) {
    final index = board.indexOf(position);
    if (updatedCells[index] == CellState.filled) {
      updatedCells[index] = CellState.empty;
    }
  }

  bool _isLineComplete(Board board, List<GridPosition> line) {
    var hasFilledCell = false;
    for (final position in line) {
      final state = board.cellAt(position);
      if (state == CellState.empty) return false;
      if (state == CellState.filled) hasFilledCell = true;
    }
    return hasFilledCell;
  }

  List<GridPosition> _rowCells(Board board, int row) => [
        for (var column = 0; column < board.size; column++)
          GridPosition(row: row, column: column),
      ];

  List<GridPosition> _columnCells(Board board, int column) => [
        for (var row = 0; row < board.size; row++)
          GridPosition(row: row, column: column),
      ];
}
