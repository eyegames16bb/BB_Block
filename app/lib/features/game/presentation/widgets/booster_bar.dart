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
/// Charges are no longer a persistent, refillable resource (see
/// `PlayerProgress`'s doc comment) — a button at zero charges is simply
/// inert for the rest of the round, whether that's because the player
/// started without a Gold Key (all three start at 0) or already spent the
/// one charge a key unlocked.
class BoosterBar extends StatelessWidget {
  const BoosterBar({
    required this.rotateCharges,
    required this.swapCharges,
    required this.singleCellRemoveCharges,
    required this.removalArmed,
    required this.onRotateTap,
    required this.onSwapTap,
    required this.onRemovalTap,
    super.key,
  });

  final int rotateCharges;
  final int swapCharges;
  final int singleCellRemoveCharges;
  final bool removalArmed;
  final VoidCallback onRotateTap;
  final VoidCallback onSwapTap;
  final VoidCallback onRemovalTap;

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
          onTap: rotateCharges > 0 ? onRotateTap : null,
        ),
        _BoosterButton(
          icon: PhosphorIconsBold.swap,
          label: l10n.boosterSwap,
          charges: swapCharges,
          onTap: swapCharges > 0 ? onSwapTap : null,
        ),
        _BoosterButton(
          icon: PhosphorIconsBold.bomb,
          label: l10n.boosterErase,
          charges: singleCellRemoveCharges,
          active: removalArmed,
          onTap: singleCellRemoveCharges > 0 ? onRemovalTap : null,
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final borderColor =
        active ? GamePalette.recordGold : GamePalette.panelDarkBorder;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
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
      ),
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
