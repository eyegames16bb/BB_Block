import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/glass_panel.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Shown from the gear icon on both the main menu and the game screen.
/// Minimal by design — sound/haptics toggles are the only settings the game
/// actually has right now.
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        ref.watch(playerProgressControllerProvider).value ??
        const PlayerProgress();
    final controller = ref.read(playerProgressControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassPanel(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(PhosphorIconsBold.gear, color: AppColors.paper),
                  const SizedBox(width: 10),
                  Text(
                    'Ayarlar',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.paper),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingToggle(
                icon: PhosphorIconsBold.speakerHigh,
                label: 'Ses',
                value: progress.soundEnabled,
                onChanged: (enabled) =>
                    controller.setSoundEnabled(enabled: enabled),
              ),
              const SizedBox(height: 10),
              _SettingToggle(
                icon: PhosphorIconsBold.vibrate,
                label: 'Titreşim',
                value: progress.hapticsEnabled,
                onChanged: (enabled) =>
                    controller.setHapticsEnabled(enabled: enabled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              color: value
                  ? GamePalette.recordGold
                  : AppColors.paper.withValues(alpha: 0.55),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.paper,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: GamePalette.recordGold,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
