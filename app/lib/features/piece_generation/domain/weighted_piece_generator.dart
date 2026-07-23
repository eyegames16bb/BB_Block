import 'dart:math';

import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:bb_block/features/piece_generation/domain/piece_generator.dart';

/// Draws pieces by [PieceShape.baseWeight] rather than uniformly, so small
/// shapes (weighted higher) appear more often than large ones. The first
/// piece of every batch is drawn only from shapes that currently fit
/// somewhere on the board, so a brand-new hand can never be an instant,
/// unavoidable game over; the remaining pieces are drawn from the full
/// catalog and may or may not fit, which is what makes later turns
/// genuinely challenging.
final class WeightedPieceGenerator implements PieceGenerator {
  WeightedPieceGenerator({
    Random? random,
    PlacementValidator? placementValidator,
    List<PieceShape>? catalog,
  })  : _random = random ?? Random(),
        _placementValidator =
            placementValidator ?? const DefaultPlacementValidator(),
        _catalog = catalog ?? PieceShapeCatalog.all;

  final Random _random;
  final PlacementValidator _placementValidator;
  final List<PieceShape> _catalog;

  @override
  List<PieceShape> nextBatch({
    required Board board,
    int count = 3,
  }) {
    final placeableShapes = _catalog
        .where(
          (shape) => _placementValidator.hasAnyValidPlacement(
            board: board,
            shape: shape,
          ),
        )
        .toList();

    final guaranteedPool = placeableShapes.isEmpty ? _catalog : placeableShapes;

    return [
      for (var index = 0; index < count; index++)
        _pickWeighted(index == 0 ? guaranteedPool : _catalog),
    ];
  }

  PieceShape _pickWeighted(List<PieceShape> candidates) {
    final totalWeight =
        candidates.fold<int>(0, (sum, shape) => sum + shape.baseWeight);
    var roll = _random.nextInt(totalWeight);

    for (final shape in candidates) {
      if (roll < shape.baseWeight) return shape;
      roll -= shape.baseWeight;
    }
    return candidates.last;
  }
}
