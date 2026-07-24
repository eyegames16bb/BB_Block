import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        ref.watch(playerProgressControllerProvider).value ??
            const PlayerProgress();

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
                    onTap: () => ref
                        .read(playerProgressControllerProvider.notifier)
                        .grantGoldKey(),
                  ),
                  _TopChip(
                    icon: Icons.vpn_key_outlined,
                    label: '${progress.goldKeyCount}',
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
              const SizedBox(height: 12),
              _BestScores(progress: progress),
              const Spacer(),
              _ModeButton(
                label: 'Level Mod',
                onTap: () => _startLevel(context, ref, progress.goldKeyCount),
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

  Future<void> _startLevel(
    BuildContext context,
    WidgetRef ref,
    int goldKeyCount,
  ) async {
    final useKey = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (context) => _GoldKeyChoiceSheet(goldKeyCount: goldKeyCount),
    );
    if (useKey == null || !context.mounted) return;

    final boostersUnlocked = useKey &&
        await ref
            .read(playerProgressControllerProvider.notifier)
            .spendGoldKey();
    if (!context.mounted) return;

    await context.push(
      AppRoutes.game,
      extra: GameLaunchConfig(
        mode: GameModeType.level,
        levelBoostersUnlocked: boostersUnlocked,
      ),
    );
  }
}

class _BestScores extends StatelessWidget {
  const _BestScores({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.ink.withValues(alpha: 0.7),
      fontSize: 14,
    );

    return Column(
      children: [
        Text('En İyi (Çerçeveli): ${progress.classicHighScoreFramed}',
            style: style),
        Text('En İyi (Çerçevesiz): ${progress.classicHighScoreFrameless}',
            style: style),
        Text('Level: ${progress.currentLevel}', style: style),
      ],
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

class _GoldKeyChoiceSheet extends StatelessWidget {
  const _GoldKeyChoiceSheet({required this.goldKeyCount});

  final int goldKeyCount;

  @override
  Widget build(BuildContext context) {
    final canUseKey = goldKeyCount > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Level Mod',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$goldKeyCount Altın Anahtarın var',
              style: TextStyle(color: AppColors.ink.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            _ModeButton(
              label: 'Anahtarsız Başla',
              onTap: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 12),
            _ModeButton(
              label: 'Altın Anahtar İle Başla',
              onTap:
                  canUseKey ? () => Navigator.of(context).pop(true) : null,
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
  final VoidCallback? onTap;

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
