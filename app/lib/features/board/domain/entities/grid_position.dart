import 'package:freezed_annotation/freezed_annotation.dart';

part 'grid_position.freezed.dart';

@freezed
abstract class GridPosition with _$GridPosition {
  const factory GridPosition({
    required int row,
    required int column,
  }) = _GridPosition;

  const GridPosition._();

  GridPosition offsetBy(GridPosition delta) => GridPosition(
        row: row + delta.row,
        column: column + delta.column,
      );
}
