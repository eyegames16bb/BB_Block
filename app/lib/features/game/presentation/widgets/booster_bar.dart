import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// The three booster buttons (Rotate / Swap / Single Cell Remove), each
/// showing its remaining charge count. Only rendered for an unlocked Level
/// Mode attempt — Classic Mode has no boosters, so callers simply don't
/// mount this widget there.
class BoosterBar extends StatelessWidget {
  const BoosterBar({
    required this.rotateCharges,
    required this.swapCharges,
    required this.singleCellRemoveCharges,
    required this.rotateArmed,
    required this.removalArmed,
    required this.onRotateTap,
    required this.onSwapTap,
    required this.onRemovalTap,
    super.key,
  });

  final int rotateCharges;
  final int swapCharges;
  final int singleCellRemoveCharges;
  final bool rotateArmed;
  final bool removalArmed;
  final VoidCallback onRotateTap;
  final VoidCallback onSwapTap;
  final VoidCallback onRemovalTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BoosterButton(
          icon: PhosphorIcons.arrowsClockwise,
          charges: rotateCharges,
          active: rotateArmed,
          onTap: rotateCharges > 0 ? onRotateTap : null,
        ),
        _BoosterButton(
          icon: PhosphorIcons.swap,
          charges: swapCharges,
          onTap: swapCharges > 0 ? onSwapTap : null,
        ),
        _BoosterButton(
          icon: PhosphorIcons.eraser,
          charges: singleCellRemoveCharges,
          active: removalArmed,
          onTap: singleCellRemoveCharges > 0 ? onRemovalTap : null,
        ),
      ],
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.charges,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final int charges;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    // A tan wood panel, per the reference mockups' booster tray — not the
    // navy used by the HUD chips, which reads as "menu UI" rather than
    // "part of the table the board sits on".
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: active
              ? [GamePalette.recordGold, GamePalette.frameBlockEdge]
              : [GamePalette.frameBlock, GamePalette.frameBlockEdge],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: AppColors.ink.withValues(alpha: enabled ? 1 : 0.35),
                  size: 26,
                ),
                Positioned(
                  right: -10,
                  top: -8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.paper, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '$charges',
                        style: const TextStyle(
                          color: AppColors.paper,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
