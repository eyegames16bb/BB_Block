import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/booster/domain/booster_kind.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/pressable_scale.dart';
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
          icon: PhosphorIconsBold.bomb,
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

/// A wood pill button — `.powerup-btn` from the reference mockup — instead
/// of the earlier circular medallion. Icon and charge badge sit side by
/// side inside one dark-brown pill with a solid drop ledge, the same
/// chrome [PressableScale] and `_RoundIconButton` use in `game_screen.dart`,
/// so every wood button in the HUD reads as one consistent chrome family.
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

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final refillable = charges <= 0 && canRefill;
    final borderColor =
        active ? GamePalette.recordGold : GamePalette.panelDarkBorder;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PressableScale(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: GamePalette.panelDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  const BoxShadow(
                    color: GamePalette.buttonLedge,
                    offset: Offset(0, 3),
                  ),
                  if (active)
                    BoxShadow(
                      color: GamePalette.recordGold.withValues(alpha: 0.55),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: active ? GamePalette.recordGold : AppColors.paper,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  _ChargeBadge(charges: charges, refillable: refillable),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
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

/// The `.add-btn` square gradient chip from the reference mockup, reused as
/// the charge count / refill badge instead of a plain outlined circle.
class _ChargeBadge extends StatelessWidget {
  const _ChargeBadge({required this.charges, required this.refillable});

  final int charges;
  final bool refillable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: refillable
              ? const [
                  GamePalette.progressFillLight,
                  GamePalette.progressFillDark,
                ]
              : const [GamePalette.woodButtonLight, GamePalette.woodButtonDark],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: GamePalette.woodButtonBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: refillable
            ? const Icon(PhosphorIcons.keyFill, color: AppColors.ink, size: 13)
            : Text(
                '$charges',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
      ),
    );
  }
}
