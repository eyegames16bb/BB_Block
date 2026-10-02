import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// The three booster buttons (Rotate / Swap / Single Cell Remove), each
/// showing its remaining charge for *this round only*. Only rendered in
/// Level Mode — Classic Mode has no boosters, so callers simply don't mount
/// this widget there.
///
/// A button at zero charges is no longer dimmed (user instruction: it must
/// not look disabled) — it just shows "0" and, when tapped, calls that
/// booster's own `onXEmptyTap` instead of its normal action, which the
/// caller uses to open a refill sheet specific to that one booster.
class BoosterBar extends StatelessWidget {
  const BoosterBar({
    required this.rotateCharges,
    required this.swapCharges,
    required this.singleCellRemoveCharges,
    required this.removalArmed,
    required this.onRotateTap,
    required this.onSwapTap,
    required this.onRemovalTap,
    required this.onRotateEmptyTap,
    required this.onSwapEmptyTap,
    required this.onRemovalEmptyTap,
    required this.onPurchaseAllTap,
    super.key,
  });

  final int rotateCharges;
  final int swapCharges;
  final int singleCellRemoveCharges;
  final bool removalArmed;
  final VoidCallback onRotateTap;
  final VoidCallback onSwapTap;
  final VoidCallback onRemovalTap;
  // Separate purchase entry point per booster (user instruction) — each
  // only offered once that specific booster reaches zero charges.
  final VoidCallback onRotateEmptyTap;
  final VoidCallback onSwapEmptyTap;
  final VoidCallback onRemovalEmptyTap;
  // The fourth "Satın Al" button (user instruction) — always tappable,
  // opens the buy-all-three sheet regardless of current charges.
  final VoidCallback onPurchaseAllTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rotate applies to the whole tray instantly on tap — no "arm and
        // pick a piece" step, so it never shows an armed/active state.
        _BoosterButton(
          icon: PhosphorIconsBold.arrowsClockwise,
          label: l10n.boosterRotate,
          charges: rotateCharges,
          onTap: rotateCharges > 0 ? onRotateTap : onRotateEmptyTap,
        ),
        _BoosterButton(
          icon: PhosphorIconsBold.swap,
          label: l10n.boosterSwap,
          charges: swapCharges,
          onTap: swapCharges > 0 ? onSwapTap : onSwapEmptyTap,
        ),
        _BoosterButton(
          icon: PhosphorIconsBold.bomb,
          label: l10n.boosterErase,
          charges: singleCellRemoveCharges,
          active: removalArmed,
          onTap: singleCellRemoveCharges > 0 ? onRemovalTap : onRemovalEmptyTap,
        ),
        // The fourth "Satın Al" button (user instruction) — same pill
        // chrome/size as the other three, but a coin icon instead of a
        // charge badge, and always tappable (no charge count of its own).
        _PurchaseAllButton(
          label: l10n.boosterPurchaseAllLabel,
          onTap: onPurchaseAllTap,
        ),
      ],
    );
  }
}

class _PurchaseAllButton extends StatelessWidget {
  const _PurchaseAllButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpringPressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GamePalette.panelDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: GamePalette.panelDarkBorder,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(color: GamePalette.buttonLedge, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(
              PhosphorIconsFill.coin,
              color: GamePalette.recordGold,
              size: 22,
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
    );
  }
}

/// A wood pill button — `.powerup-btn` from the reference mockup — instead
/// of the earlier circular medallion. Icon and charge badge sit side by
/// side inside one dark-brown pill with a solid drop ledge, the same
/// chrome [SpringPressable] and `_RoundIconButton` use in `game_screen.dart`,
/// so every wood button in the HUD reads as one consistent chrome family.
class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.label,
    required this.charges,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final int charges;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        active ? GamePalette.recordGold : GamePalette.panelDarkBorder;

    // Deliberately never dimmed, even at zero charges (user instruction) —
    // a zero-charge tap opens the refill sheet instead of doing nothing.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpringPressable(
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
                _ChargeBadge(charges: charges),
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
    );
  }
}

/// The `.add-btn` square gradient chip from the reference mockup, reused as
/// the charge count badge instead of a plain outlined circle.
class _ChargeBadge extends StatelessWidget {
  const _ChargeBadge({required this.charges});

  final int charges;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GamePalette.woodButtonLight, GamePalette.woodButtonDark],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: GamePalette.woodButtonBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
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
