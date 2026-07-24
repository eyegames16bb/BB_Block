import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/booster/domain/booster_kind.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// The three booster buttons (Rotate / Swap / Single Cell Remove), each
/// showing its remaining persistent charge count. Only rendered in Level
/// Mode — Classic Mode has no boosters, so callers simply don't mount this
/// widget there.
///
/// A button at zero charges isn't just disabled: if the player owns a Gold
/// Key, tapping it spends one to refill *that* booster by one (see
/// [onRefill]) — the badge swaps its "0" for a key glyph to hint at this.
/// Only out of both charges and keys does the button go fully inert.
class BoosterBar extends StatelessWidget {
  const BoosterBar({
    required this.rotateCharges,
    required this.swapCharges,
    required this.singleCellRemoveCharges,
    required this.goldKeyCount,
    required this.rotateArmed,
    required this.removalArmed,
    required this.onRotateTap,
    required this.onSwapTap,
    required this.onRemovalTap,
    required this.onRefill,
    super.key,
  });

  final int rotateCharges;
  final int swapCharges;
  final int singleCellRemoveCharges;
  final int goldKeyCount;
  final bool rotateArmed;
  final bool removalArmed;
  final VoidCallback onRotateTap;
  final VoidCallback onSwapTap;
  final VoidCallback onRemovalTap;
  final ValueChanged<BoosterKind> onRefill;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BoosterButton(
          icon: PhosphorIcons.arrowsClockwise,
          charges: rotateCharges,
          canRefill: goldKeyCount > 0,
          active: rotateArmed,
          onTap: rotateCharges > 0
              ? onRotateTap
              : (goldKeyCount > 0
                  ? () => onRefill(BoosterKind.rotate)
                  : null),
        ),
        _BoosterButton(
          icon: PhosphorIcons.swap,
          charges: swapCharges,
          canRefill: goldKeyCount > 0,
          onTap: swapCharges > 0
              ? onSwapTap
              : (goldKeyCount > 0 ? () => onRefill(BoosterKind.swap) : null),
        ),
        _BoosterButton(
          icon: PhosphorIcons.eraser,
          charges: singleCellRemoveCharges,
          canRefill: goldKeyCount > 0,
          active: removalArmed,
          onTap: singleCellRemoveCharges > 0
              ? onRemovalTap
              : (goldKeyCount > 0
                  ? () => onRefill(BoosterKind.singleCellRemove)
                  : null),
        ),
      ],
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.charges,
    required this.canRefill,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final int charges;
  final bool canRefill;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final refillable = charges <= 0 && canRefill;

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
                      color: refillable
                          ? GamePalette.recordGold
                          : AppColors.navy,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.paper, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: refillable
                          ? const Icon(
                              PhosphorIcons.keyFill,
                              color: AppColors.ink,
                              size: 11,
                            )
                          : Text(
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
