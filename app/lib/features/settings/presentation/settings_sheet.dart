import 'package:bb_block/core/theme/app_theme.dart';
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
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(PhosphorIcons.gear, color: AppColors.paper),
                const SizedBox(width: 10),
                Text(
                  'Ayarlar',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.paper),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingToggle(
              icon: PhosphorIcons.speakerHigh,
              label: 'Ses',
              value: progress.soundEnabled,
              onChanged: (enabled) =>
                  controller.setSoundEnabled(enabled: enabled),
            ),
            const SizedBox(height: 12),
            _SettingToggle(
              icon: PhosphorIcons.vibrate,
              label: 'Titreşim',
              value: progress.hapticsEnabled,
              onChanged: (enabled) =>
                  controller.setHapticsEnabled(enabled: enabled),
            ),
          ],
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
    return Row(
      children: [
        Icon(icon, color: AppColors.paper.withValues(alpha: 0.85), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.paper, fontSize: 16),
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.gold,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
