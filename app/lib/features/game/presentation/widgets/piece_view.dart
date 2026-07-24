import 'dart:math' as math;

import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:flutter/material.dart';

/// Renders a [PieceShape] as wood tiles laid out in its own bounding box,
/// sized to [cellSize] per cell. Used both in the tray and as the drag
/// feedback so the dragged piece matches the board's scale.
class PieceView extends StatelessWidget {
  const PieceView({
    required this.shape,
    required this.cellSize,
    this.opacity = 1,
    super.key,
  });

  final PieceShape shape;
  final double cellSize;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final rows =
        shape.cells.map((cell) => cell.row).reduce(math.max) + 1;
    final columns =
        shape.cells.map((cell) => cell.column).reduce(math.max) + 1;

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: columns * cellSize,
        height: rows * cellSize,
        child: Stack(
          children: [
            for (final cell in shape.cells)
              Positioned(
                left: cell.column * cellSize,
                top: cell.row * cellSize,
                width: cellSize,
                height: cellSize,
                child: WoodTile(size: cellSize),
              ),
          ],
        ),
      ),
    );
  }
}
