import 'package:bb_block/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
          icon: Icons.rotate_right,
          charges: rotateCharges,
          active: rotateArmed,
          onTap: rotateCharges > 0 ? onRotateTap : null,
        ),
        _BoosterButton(
          icon: Icons.swap_horiz,
          charges: swapCharges,
          onTap: swapCharges > 0 ? onSwapTap : null,
        ),
        _BoosterButton(
          icon: Icons.auto_fix_high,
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

    return Material(
      color: active ? AppColors.gold : AppColors.navy,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.paper.withValues(alpha: enabled ? 1 : 0.4),
              ),
              const SizedBox(height: 2),
              Text(
                '$charges',
                style: TextStyle(
                  color: AppColors.paper.withValues(alpha: enabled ? 1 : 0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
