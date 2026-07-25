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
        // Rotate applies to the whole tray instantly on tap — no "arm and
        // pick a piece" step, so it never shows an armed/active state.
        _BoosterButton(
          icon: PhosphorIconsBold.arrowsClockwise,
          label: 'Yön',
          charges: rotateCharges,
          canRefill: goldKeyCount > 0,
          onTap: rotateCharges > 0
              ? onRotateTap
              : (goldKeyCount > 0
                  ? () => onRefill(BoosterKind.rotate)
                  : null),
        ),
        _BoosterButton(
          icon: PhosphorIconsBold.swap,
          label: 'Değiştir',
          charges: swapCharges,
          canRefill: goldKeyCount > 0,
          onTap: swapCharges > 0
              ? onSwapTap
              : (goldKeyCount > 0 ? () => onRefill(BoosterKind.swap) : null),
        ),
        _BoosterButton(
          icon: PhosphorIconsBold.eraser,
          label: 'Sil',
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

/// A round, coin-like token instead of the earlier bordered square panel —
/// closer to the reference mockups' compact in-game booster icons than a
/// literal framed rectangle. A soft radial highlight simulates a raised
/// lacquered-wood disc; the charge/refill badge sits inset in the token's
/// own bottom edge rather than as a separately-outlined circle, so it reads
/// as one integrated piece rather than an icon-plus-frame.
class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.label,
    required this.charges,
    required this.canRefill,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final int charges;
  final bool canRefill;
  final bool active;
  final VoidCallback? onTap;

  static const double _diameter = 60;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final refillable = charges <= 0 && canRefill;
    final baseColor = active ? GamePalette.recordGold : GamePalette.frameBlock;
    final edgeColor =
        active ? GamePalette.frameBlockEdge : AppColors.woodDeep;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _diameter,
            height: _diameter,
            child: Material(
              shape: const CircleBorder(),
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    radius: 1.1,
                    colors: [
                      Color.lerp(baseColor, Colors.white, 0.35)!,
                      baseColor,
                      edgeColor,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    if (active)
                      BoxShadow(
                        color: GamePalette.recordGold.withValues(alpha: 0.55),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(icon, color: AppColors.ink, size: 26),
                      Positioned(
                        bottom: -6,
                        child: _ChargeBadge(
                          charges: charges,
                          refillable: refillable,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.paper.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargeBadge extends StatelessWidget {
  const _ChargeBadge({required this.charges, required this.refillable});

  final int charges;
  final bool refillable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: refillable ? GamePalette.recordGold : AppColors.navy,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: refillable
            ? const Icon(PhosphorIcons.keyFill, color: AppColors.ink, size: 12)
            : Text(
                '$charges',
                style: const TextStyle(
                  color: AppColors.paper,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
      ),
    );
  }
}
