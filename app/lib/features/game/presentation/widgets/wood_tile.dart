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
    final face = isFrame ? GamePalette.frameBlock : GamePalette.placedBlock;
    final edge =
        isFrame ? GamePalette.frameBlockEdge : GamePalette.placedBlockEdge;

    return Padding(
      padding: EdgeInsets.all(size * 0.05),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(size * 0.16),
          border: Border(
            bottom: BorderSide(color: edge, width: size * 0.1),
            right: BorderSide(color: edge, width: size * 0.1),
          ),
        ),
      ),
    );
  }
}
