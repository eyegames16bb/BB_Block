import 'dart:async';

import 'package:bb_block/core/providers/ads_providers.dart';
import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/wood_background.dart';
import 'package:bb_block/features/booster/domain/booster_kind.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/settings/presentation/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        ref.watch(playerProgressControllerProvider).value ??
            const PlayerProgress();

    return Scaffold(
      body: WoodBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TopChip(
                      icon: PhosphorIcons.filmSlate,
                      label: 'Ödüllü Reklam',
                      onTap: () => _watchRewardedAd(context, ref),
                    ),
                    Row(
                      children: [
                        _TopChip(
                          icon: PhosphorIcons.keyFill,
                          iconColor: GamePalette.recordGold,
                          label: '${progress.goldKeyCount}',
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _RoundIconButton(
                          icon: PhosphorIcons.gear,
                          onTap: () => SettingsSheet.show(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'BB Block',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.paper,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 14),
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
      ),
    );
  }

  Future<void> _watchRewardedAd(BuildContext context, WidgetRef ref) async {
    final ads = ref.read(adsServiceProvider);
    if (!ads.isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam henüz hazır değil, birazdan tekrar deneyin.'),
        ),
      );
      return;
    }

    await ads.showRewardedAd(
      onRewardEarned: () {
        unawaited(
          ref.read(playerProgressControllerProvider.notifier).grantGoldKey(),
        );
      },
    );
  }

  Future<void> _startClassic(BuildContext context) async {
    final hasFrame = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    // GameController reads booster charges from PlayerProgress the instant
    // it builds, synchronously — guarantee it's actually loaded first, so a
    // player with real saved charges never gets seeded with fallback
    // defaults just because SharedPreferences hadn't resolved yet.
    await ref.read(playerProgressControllerProvider.future);
    if (!context.mounted) return;

    // `null` result means "skip" (dismissed, or explicitly chose to start
    // without spending a key) — booster charges are a persistent resource
    // now (see PlayerProgress), so skipping just means playing with
    // whatever's already stashed rather than unlocking anything.
    final chosen = await showModalBottomSheet<BoosterKind>(
      context: context,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BoosterChoiceSheet(goldKeyCount: goldKeyCount),
    );
    if (!context.mounted) return;

    if (chosen != null) {
      await ref
          .read(playerProgressControllerProvider.notifier)
          .refillBooster(chosen);
      if (!context.mounted) return;
    }

    await context.push(
      AppRoutes.game,
      extra: const GameLaunchConfig(mode: GameModeType.level),
    );
  }
}

class _BestScores extends StatelessWidget {
  const _BestScores({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.paper.withValues(alpha: 0.85),
      fontSize: 14,
      shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.paper),
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

/// Booster charges persist across levels and retries (see `PlayerProgress`)
/// — this sheet is just an optional, skippable chance to spend a Gold Key
/// on one specific booster before starting, not a gate on using boosters at
/// all like the old unlock-the-whole-attempt flow was.
class _BoosterChoiceSheet extends StatelessWidget {
  const _BoosterChoiceSheet({required this.goldKeyCount});

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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.paper),
            ),
            const SizedBox(height: 8),
            Text(
              canUseKey
                  ? '$goldKeyCount Altın Anahtarın var — bir tamamlayıcıyı '
                      '+1 doldurmak ister misin?'
                  : 'Altın Anahtarın yok',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.paper.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            _ModeButton(
              icon: PhosphorIcons.arrowsClockwise,
              label: 'Yön Değiştirme +1',
              onTap: canUseKey
                  ? () => Navigator.of(context).pop(BoosterKind.rotate)
                  : null,
            ),
            const SizedBox(height: 12),
            _ModeButton(
              icon: PhosphorIcons.swap,
              label: 'Parça Değiştirme +1',
              onTap: canUseKey
                  ? () => Navigator.of(context).pop(BoosterKind.swap)
                  : null,
            ),
            const SizedBox(height: 12),
            _ModeButton(
              icon: PhosphorIcons.eraser,
              label: 'Tek Nokta Silici +1',
              onTap: canUseKey
                  ? () => Navigator.of(context)
                      .pop(BoosterKind.singleCellRemove)
                  : null,
            ),
            const SizedBox(height: 12),
            _ModeButton(
              label: 'Anahtarsız Başla',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.paper, size: 18),
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
    this.iconColor = AppColors.paper,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      shadowColor: Colors.black54,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 18),
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
  const _ModeButton({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          elevation: 4,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: icon == null
            ? Text(label, style: const TextStyle(fontSize: 18))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(fontSize: 18)),
                ],
              ),
      ),
    );
  }
}
