import 'dart:async';

import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_view.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three-piece tray. Each unused piece is draggable onto the board; the
/// dragged feedback is rendered at [dragCellSize] so it matches the board's
/// scale, while the resting tray shows pieces smaller at [trayCellSize].
class PieceTray extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // The reference mockup's `.piece-dock` — a dark-wood panel grounding
    // the slots, instead of the pieces floating directly on the table
    // background with nothing behind them.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GamePalette.panelDark,
        border: Border.all(color: GamePalette.panelDarkBorder, width: 3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var index = 0; index < tray.length; index++)
            Expanded(child: _slot(ref, tray[index], index)),
        ],
      ),
    );
  }

  Widget _slot(WidgetRef ref, TrayPiece piece, int index) {
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
      // "Block Grab" from the Game Feel spec: a soft pick-up sound + light
      // haptic the instant the drag starts, and the feedback widget below
      // renders at 105% with a soft glow — the piece should feel like it
      // physically lifted off the tray, not just teleported under the
      // finger.
      onDragStarted: () {
        unawaited(
          ref.read(audioServiceProvider).playEffect(SoundEffect.piecePickUp),
        );
        unawaited(
          ref.read(audioServiceProvider).playEffect(SoundEffect.pieceDrag),
        );
        unawaited(
          ref.read(hapticsServiceProvider).trigger(HapticIntensity.light),
        );
      },
      feedback: _GrabbedPiece(shape: piece.shape, cellSize: dragCellSize),
      childWhenDragging: Opacity(
        opacity: GamePalette.draggingSlotOpacity,
        child: resting,
      ),
      child: resting,
    );
  }
}

/// The piece as it appears while being dragged — 105% scale and a soft
/// golden glow + drop shadow underneath, per the Game Feel spec's "Block
/// Grab" sequence, instead of a plain 1:1 copy of the resting piece.
class _GrabbedPiece extends StatelessWidget {
  const _GrabbedPiece({required this.shape, required this.cellSize});

  final PieceShape shape;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.05,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: GamePalette.recordGold.withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: PieceView(shape: shape, cellSize: cellSize),
      ),
    );
  }
}
