import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PieceShape shape(PieceShapeId id) =>
      PieceShapeCatalog.all.firstWhere((shape) => shape.id == id);

  test(
      'square, 2/3/4-cell line pieces, and the L-tromino "triangle" shapes '
      'are weighted a notch higher than before (user instruction)', () {
    expect(shape(PieceShapeId.square).baseWeight, 7);

    expect(shape(PieceShapeId.dominoHorizontal).baseWeight, 10);
    expect(shape(PieceShapeId.dominoVertical).baseWeight, 10);
    expect(shape(PieceShapeId.triominoLineHorizontal).baseWeight, 8);
    expect(shape(PieceShapeId.triominoLineVertical).baseWeight, 8);
    expect(shape(PieceShapeId.tetrominoLineHorizontal).baseWeight, 5);
    expect(shape(PieceShapeId.tetrominoLineVertical).baseWeight, 5);

    expect(shape(PieceShapeId.lTriomino0).baseWeight, 7);
    expect(shape(PieceShapeId.lTriomino90).baseWeight, 7);
    expect(shape(PieceShapeId.lTriomino180).baseWeight, 7);
    expect(shape(PieceShapeId.lTriomino270).baseWeight, 7);
  });

  test('shapes outside the boosted categories are unchanged', () {
    expect(shape(PieceShapeId.single).baseWeight, 10);
    expect(shape(PieceShapeId.lTetromino0).baseWeight, 3);
    expect(shape(PieceShapeId.jTetromino0).baseWeight, 3);
    expect(shape(PieceShapeId.tTetromino0).baseWeight, 3);
    expect(shape(PieceShapeId.sTetromino0).baseWeight, 3);
    expect(shape(PieceShapeId.zTetromino0).baseWeight, 3);
    expect(shape(PieceShapeId.pentominoLineHorizontal).baseWeight, 2);
    expect(shape(PieceShapeId.pentominoLineVertical).baseWeight, 2);
  });
}
