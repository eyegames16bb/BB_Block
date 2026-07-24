import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TopChip(
                    icon: Icons.movie_outlined,
                    label: 'Ödüllü Reklam',
                    onTap: () {},
                  ),
                  _TopChip(
                    icon: Icons.vpn_key_outlined,
                    label: '0',
                    onTap: () {},
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'BB Block',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const Spacer(),
              _ModeButton(
                label: 'Level Mod',
                onTap: () => context.push(
                  AppRoutes.game,
                  extra: const GameLaunchConfig(mode: GameModeType.level),
                ),
              ),
              const SizedBox(height: 12),
              _ModeButton(
                label: 'Klasik Mod',
                onTap: () => _startClassic(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startClassic(BuildContext context) async {
    final hasFrame = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (context) => const _FrameChoiceSheet(),
    );
    if (hasFrame == null || !context.mounted) return;

    await context.push(
      AppRoutes.game,
      extra: GameLaunchConfig(
        mode: GameModeType.classic,
        classicHasFrame: hasFrame,
      ),
    );
  }
}

class _FrameChoiceSheet extends StatelessWidget {
  const _FrameChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Çerçeve',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _ModeButton(
              label: 'Çerçeve VAR',
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 12),
            _ModeButton(
              label: 'Çerçeve YOK',
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.paper, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: AppColors.paper),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
