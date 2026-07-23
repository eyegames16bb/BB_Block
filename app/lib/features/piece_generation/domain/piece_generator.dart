import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';

/// Produces a new hand of pieces for the player's tray.
///
/// This only guarantees that a *fresh batch* is solvable — it does not decide
/// round/level failure. That check belongs to whatever evaluates the current
/// tray against `PlacementValidator.hasAnyValidPlacement` after every
/// placement, since a batch that started solvable can still be exhausted down
/// to an unplaceable last piece.
abstract interface class PieceGenerator {
  List<PieceShape> nextBatch({
    required Board board,
    int count = BoardConstants.piecesPerTurn,
  });
}
