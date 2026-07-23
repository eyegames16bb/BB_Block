import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'piece_shape.freezed.dart';

enum PieceShapeId {
  single,
  dominoHorizontal,
  dominoVertical,
  triominoLineHorizontal,
  triominoLineVertical,
  lTriomino0,
  lTriomino90,
  lTriomino180,
  lTriomino270,
  square,
  tetrominoLineHorizontal,
  tetrominoLineVertical,
  lTetromino0,
  lTetromino90,
  lTetromino180,
  lTetromino270,
  jTetromino0,
  jTetromino90,
  jTetromino180,
  jTetromino270,
  tTetromino0,
  tTetromino90,
  tTetromino180,
  tTetromino270,
  sTetromino0,
  sTetromino90,
  zTetromino0,
  zTetromino90,
  pentominoLineHorizontal,
  pentominoLineVertical,
}

@freezed
abstract class PieceShape with _$PieceShape {
  const factory PieceShape({
    required PieceShapeId id,
    required List<GridPosition> cells,
    required int baseWeight,
  }) = _PieceShape;

  const PieceShape._();

  int get cellCount => cells.length;
}

abstract final class PieceShapeCatalog {
  static const List<PieceShape> all = [
    PieceShape(
      id: PieceShapeId.single,
      cells: [GridPosition(row: 0, column: 0)],
      baseWeight: 10,
    ),
    PieceShape(
      id: PieceShapeId.dominoHorizontal,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
      ],
      baseWeight: 8,
    ),
    PieceShape(
      id: PieceShapeId.dominoVertical,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
      ],
      baseWeight: 8,
    ),
    PieceShape(
      id: PieceShapeId.triominoLineHorizontal,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 0, column: 2),
      ],
      baseWeight: 6,
    ),
    PieceShape(
      id: PieceShapeId.triominoLineVertical,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 2, column: 0),
      ],
      baseWeight: 6,
    ),
    PieceShape(
      id: PieceShapeId.lTriomino0,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
      ],
      baseWeight: 5,
    ),
    PieceShape(
      id: PieceShapeId.lTriomino90,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 0),
      ],
      baseWeight: 5,
    ),
    PieceShape(
      id: PieceShapeId.lTriomino180,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 1),
      ],
      baseWeight: 5,
    ),
    PieceShape(
      id: PieceShapeId.lTriomino270,
      cells: [
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
      ],
      baseWeight: 5,
    ),
    PieceShape(
      id: PieceShapeId.square,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
      ],
      baseWeight: 5,
    ),
    PieceShape(
      id: PieceShapeId.tetrominoLineHorizontal,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 0, column: 2),
        GridPosition(row: 0, column: 3),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.tetrominoLineVertical,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 2, column: 0),
        GridPosition(row: 3, column: 0),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.lTetromino0,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 2, column: 0),
        GridPosition(row: 2, column: 1),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.lTetromino90,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 0, column: 2),
        GridPosition(row: 1, column: 0),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.lTetromino180,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 2, column: 1),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.lTetromino270,
      cells: [
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 1, column: 2),
        GridPosition(row: 0, column: 2),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.jTetromino0,
      cells: [
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 2, column: 0),
        GridPosition(row: 2, column: 1),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.jTetromino90,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 1, column: 2),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.jTetromino180,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 2, column: 0),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.jTetromino270,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 0, column: 2),
        GridPosition(row: 1, column: 2),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.tTetromino0,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 0, column: 2),
        GridPosition(row: 1, column: 1),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.tTetromino90,
      cells: [
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 2, column: 1),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.tTetromino180,
      cells: [
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 1, column: 2),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.tTetromino270,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 2, column: 0),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.sTetromino0,
      cells: [
        GridPosition(row: 0, column: 1),
        GridPosition(row: 0, column: 2),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.sTetromino90,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 2, column: 1),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.zTetromino0,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 1, column: 2),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.zTetromino90,
      cells: [
        GridPosition(row: 0, column: 1),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 1, column: 1),
        GridPosition(row: 2, column: 0),
      ],
      baseWeight: 3,
    ),
    PieceShape(
      id: PieceShapeId.pentominoLineHorizontal,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 0, column: 1),
        GridPosition(row: 0, column: 2),
        GridPosition(row: 0, column: 3),
        GridPosition(row: 0, column: 4),
      ],
      baseWeight: 2,
    ),
    PieceShape(
      id: PieceShapeId.pentominoLineVertical,
      cells: [
        GridPosition(row: 0, column: 0),
        GridPosition(row: 1, column: 0),
        GridPosition(row: 2, column: 0),
        GridPosition(row: 3, column: 0),
        GridPosition(row: 4, column: 0),
      ],
      baseWeight: 2,
    ),
  ];
}
