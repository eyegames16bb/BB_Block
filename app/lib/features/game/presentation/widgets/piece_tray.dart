import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_view.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';

/// The three-piece tray. Each unused piece is draggable onto the board; the
/// dragged feedback is rendered at [dragCellSize] so it matches the board's
/// scale, while the resting tray shows pieces smaller at [trayCellSize].
class PieceTray extends StatelessWidget {
  const PieceTray({
    required this.tray,
    required this.dragCellSize,
    this.trayCellSize = 22,
    super.key,
  });

  final List<TrayPiece> tray;
  final double dragCellSize;
  final double trayCellSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var index = 0; index < tray.length; index++)
          Expanded(child: _slot(tray[index], index)),
      ],
    );
  }

  Widget _slot(TrayPiece piece, int index) {
    if (piece.isUsed) return const SizedBox.shrink();

    final resting = Center(
      child: PieceView(shape: piece.shape, cellSize: trayCellSize),
    );

    return Draggable<int>(
      data: index,
      // Lifts the dragged piece above the fingertip instead of anchoring
      // its (0,0) cell exactly under the touch point
      // (`pointerDragAnchorStrategy`) — otherwise the finger itself hides
      // the very cells the player is trying to aim at.
      // `BoardGrid._anchorFrom` reads the feedback widget's own reported
      // position to compute the placement cell, so shifting the anchor
      // here changes *where the piece is shown and placed* together — it
      // stays what-you-see-is-what-you-get, just shown above the finger
      // rather than under it.
      dragAnchorStrategy: (draggable, context, position) =>
          Offset(0, dragCellSize * 1.3),
      feedback: PieceView(shape: piece.shape, cellSize: dragCellSize),
      childWhenDragging: Opacity(
        opacity: GamePalette.draggingSlotOpacity,
        child: resting,
      ),
      child: resting,
    );
  }
}
