import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:flutter/material.dart';

/// A single wood block, used for both placed pieces and the permanent frame.
/// The slightly darker bottom-right edge gives a low-effort sense of depth
/// without needing a bitmap asset.
class WoodTile extends StatelessWidget {
  const WoodTile({
    required this.size,
    this.isFrame = false,
    super.key,
  });

  final double size;
  final bool isFrame;

  @override
  Widget build(BuildContext context) {
    final edge =
        isFrame ? GamePalette.frameBlockEdge : GamePalette.placedBlockEdge;

    return Padding(
      padding: EdgeInsets.all(size * 0.05),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isFrame ? GamePalette.frameBlock : null,
          // Placed (non-frame) tiles are a diagonal amber gradient with a
          // permanent soft glow — `.cell.filled`'s
          // `linear-gradient(135deg, ...)` + glowing `box-shadow` from the
          // newer reference image/CSS. The frame keeps its flat fill.
          gradient: isFrame
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GamePalette.placedBlockGradientStart,
                    GamePalette.placedBlockGradientEnd,
                  ],
                ),
          borderRadius: BorderRadius.circular(size * 0.16),
          border: Border(
            bottom: BorderSide(color: edge, width: size * 0.1),
            right: BorderSide(color: edge, width: size * 0.1),
          ),
          boxShadow: isFrame
              ? null
              : [
                  BoxShadow(
                    color: GamePalette.placedBlockGlow,
                    blurRadius: size * 0.2,
                  ),
                ],
        ),
        // A soft top-left highlight so the tile reads as a raised chip
        // rather than a flat painted square, matching the beveled piece art
        // in the reference mockup.
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [GamePalette.tileHighlight, Colors.transparent],
              stops: [0, 0.6],
            ),
          ),
        ),
      ),
    );
  }
}
