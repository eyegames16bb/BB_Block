import 'dart:async';

import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/providers/ads_providers.dart';
import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/home/presentation/widgets/premium_game_button.dart';
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
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackground()),
          SafeArea(
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
                              color: Colors.black87,
                              blurRadius: 16,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 14),
                  _BestScores(progress: progress),
                  const Spacer(),
                  PremiumGameButton(
                    label: 'Level Mod',
                    icon: PhosphorIconsFill.mountains,
                    glossTop: const Color(0xFF8DE25C),
                    glossMid: const Color(0xFF5DBE38),
                    glossDeep: const Color(0xFF3C9626),
                    onTap: () =>
                        _startLevel(context, ref, progress.goldKeyCount),
                  ),
                  const SizedBox(height: 14),
                  PremiumGameButton(
                    label: 'Klasik Mod',
                    icon: PhosphorIconsFill.crown,
                    glossTop: const Color(0xFF6FD1F5),
                    glossMid: const Color(0xFF2E9FE0),
                    glossDeep: const Color(0xFF1B6FA8),
                    onTap: () => _startClassic(context),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
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
    await ref.read(playerProgressControllerProvider.future);
    if (!context.mounted) return;

    // `null` means the sheet was dismissed without a choice — don't start a
    // round at all. Otherwise the bool is the player's actual choice:
    // `true` = spent a key, boosters unlocked for this round only; `false`
    // = playing with none, both are terminal decisions for the round (see
    // `PlayerProgress`'s doc comment — nothing mid-round can change this).
    final useKey = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LevelStartSheet(goldKeyCount: goldKeyCount),
    );
    if (useKey == null || !context.mounted) return;

    var boostersUnlocked = false;
    if (useKey) {
      boostersUnlocked = await ref
          .read(playerProgressControllerProvider.notifier)
          .spendGoldKeyForBoosters();
      if (!context.mounted) return;
    }

    await context.push(
      AppRoutes.game,
      extra: GameLaunchConfig(
        mode: GameModeType.level,
        levelBoostersUnlocked: boostersUnlocked,
      ),
    );
  }
}

/// The provided home screen artwork, cropped to hide its own baked-in
/// "BEN BRICK BLOCKS" sign (a placeholder title from whatever prompt
/// generated the art — this game is BB Block, not that). The image's
/// aspect ratio is close enough to a modern phone screen's that a plain
/// `BoxFit.cover` barely crops anything, so this deliberately over-scales
/// the image (anchored to the bottom) and clips the overflow, pushing the
/// sign off the top of the screen while keeping the mascot and scenery
/// below it fully visible and anchored to the bottom edge.
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scale: 1.75,
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            'assets/images/home_background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
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
      color: AppColors.paper.withValues(alpha: 0.9),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('En İyi (Çerçeveli): ${progress.classicHighScoreFramed}',
                style: style),
            Text('En İyi (Çerçevesiz): ${progress.classicHighScoreFrameless}',
                style: style),
            Text('Level: ${progress.currentLevel}', style: style),
          ],
        ),
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.paper),
            ),
            const SizedBox(height: 16),
            _SheetChoiceButton(
              label: 'Çerçeve Var (8x8)',
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 12),
            _SheetChoiceButton(
              label: 'Çerçeve Yok (10x10)',
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Level Mode's start-of-round choice: spend one Gold Key to play this
/// round with one charge of every booster (never refillable, never carried
/// to the next level — see `PlayerProgress`'s doc comment), or skip
/// straight in with none. This replaces the old "pick one booster to top
/// up" sheet from the persistent-charge model.
class _LevelStartSheet extends StatelessWidget {
  const _LevelStartSheet({required this.goldKeyCount});

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
            const SizedBox(height: 10),
            Text(
              '*1 adet altın anahtar ile oyuna başla ve bölümü '
              'tamamlayıcılar ile oyna!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.paper.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            _StartChoiceButton(
              label: 'Altın Anahtar İle Oyuna Başla',
              subtitle: canUseKey
                  ? '$goldKeyCount Altın Anahtarın var'
                  : 'Altın Anahtarın yok',
              prominent: true,
              onTap: canUseKey
                  ? () => Navigator.of(context).pop(true)
                  : null,
            ),
            const SizedBox(height: 12),
            _StartChoiceButton(
              label: 'Anahtarsız Oyuna Başla',
              prominent: false,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// The prominent (Gold Key) vs. pale (no boosters) pair from the Level
/// Mode start sheet — deliberately different weights so the key option
/// visually reads as the "better" choice, per user instruction.
class _StartChoiceButton extends StatelessWidget {
  const _StartChoiceButton({
    required this.label,
    required this.prominent,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool prominent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SpringPressable(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: prominent ? GamePalette.recordGold : AppColors.navy,
            borderRadius: BorderRadius.circular(14),
            border: prominent
                ? null
                : Border.all(color: AppColors.paper.withValues(alpha: 0.18)),
            boxShadow: prominent
                ? [
                    BoxShadow(
                      color: GamePalette.recordGold.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: prominent
                      ? AppColors.ink
                      : AppColors.paper.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: prominent
                        ? AppColors.ink.withValues(alpha: 0.7)
                        : AppColors.paper.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetChoiceButton extends StatelessWidget {
  const _SheetChoiceButton({required this.label, required this.onTap});

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
          elevation: 4,
          shadowColor: Colors.black54,
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
