import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/piece_generation/domain/piece_generator.dart';
import 'package:bb_block/features/piece_generation/domain/weighted_piece_generator.dart';

/// Replaces the whole tray with a fresh batch drawn only from small shapes
/// (3 cells or fewer), per the GDD's "az sayıda blok noktasından oluşan
/// parçalar" rule for this booster.
final class SwapPiecesCommand {
  SwapPiecesCommand({PieceGenerator? generator})
      : _generator = generator ??
            WeightedPieceGenerator(
              catalog: PieceShapeCatalog.all
                  .where((shape) => shape.cellCount <= 3)
                  .toList(),
            );

  final PieceGenerator _generator;

  List<PieceShape> execute({
    required Board board,
    int count = BoardConstants.piecesPerTurn,
  }) =>
      _generator.nextBatch(board: board, count: count);
}
