import 'dart:async';

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/routing/app_router.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/glass_panel.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/home/presentation/widgets/premium_game_button.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/rewarded_ad/presentation/widgets/watch_ad_confirm_sheet.dart';
import 'package:bb_block/features/settings/presentation/settings_sheet.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress =
        ref.watch(playerProgressControllerProvider).value ??
            const PlayerProgress();

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackground()),
          // A light dark fade at the very top — just enough to keep the
          // status bar icons legible over a busy photo, not to hide any
          // of the artwork itself.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black45, Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // All three top chips grouped together at the top-right
                  // (user instruction) — Coin balance, Ödüllü Reklam, then
                  // Ayarlar (now a labeled icon+text button, not icon-only).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _CoinChip(
                        goldKeyCount: progress.goldKeyCount,
                        onTap: () => _showGoldKeyProgress(context, ref),
                      ),
                      const SizedBox(width: 10),
                      _TopChip(
                        icon: PhosphorIcons.filmSlate,
                        label: l10n.rewardedAdChip,
                        onTap: () => confirmAndWatchAd(context),
                      ),
                      const SizedBox(width: 10),
                      _TopChip(
                        icon: PhosphorIcons.gear,
                        label: l10n.settingsTitle,
                        onTap: () => SettingsSheet.show(context),
                      ),
                    ],
                  ),
                  // No separate "BB Block" title here — the artwork
                  // already carries its own large title graphic near the
                  // top, and stacking our own text right under it read as
                  // two competing titles. The scoreboard has moved to
                  // Settings (user instruction).
                  const Spacer(),
                  // Klasik Mod above, Level Mod below (user instruction —
                  // reversed from the earlier order).
                  PremiumGameButton(
                    label: l10n.classicModeButton,
                    // Crown (user instruction) — replaces the earlier
                    // puzzle-piece icon.
                    icon: PhosphorIconsFill.crown,
                    // Orange (user instruction, reference image) — was
                    // blue; Level Mod keeps green, so the pair now reads
                    // orange/green the same way the reference pill trio
                    // does.
                    glossTop: const Color(0xFFFFE29A),
                    glossMid: const Color(0xFFFF9F1C),
                    glossDeep: const Color(0xFFD97706),
                    onTap: () => _startClassic(context, ref),
                  ),
                  const SizedBox(height: 14),
                  PremiumGameButton(
                    label: l10n.levelLabel(progress.currentLevel),
                    icon: PhosphorIconsFill.flagCheckered,
                    glossTop: const Color(0xFF8DE25C),
                    glossMid: const Color(0xFF5DBE38),
                    glossDeep: const Color(0xFF3C9626),
                    onTap: () => _startLevel(context, ref),
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

  Future<void> _startClassic(BuildContext context, WidgetRef ref) async {
    // Board size (framed 8x8 / frameless 10x10) is a persistent Settings
    // choice (user instruction) — the every-launch confirmation sheet was
    // removed (user instruction), so this reads the fresh value and starts
    // (or resumes) the round directly.
    final progress = await ref.read(playerProgressControllerProvider.future);
    if (!context.mounted) return;
    final hasFrame = progress.classicHasFrame;

    final savedRound = ref.read(roundSaveRepositoryProvider).load(
          GameModeType.classic,
          classicHasFrame: hasFrame,
        );
    if (savedRound != null) {
      await context.push(AppRoutes.game, extra: savedRound.config);
      return;
    }

    await context.push(
      AppRoutes.game,
      extra: GameLaunchConfig(
        mode: GameModeType.classic,
        classicHasFrame: hasFrame,
      ),
    );
  }

  Future<void> _showGoldKeyProgress(BuildContext context, WidgetRef ref) async {
    // Same staleness concern as `_startLevel`: re-read fresh rather than
    // trust whatever `progress` the chip was built with.
    final progress = await ref.read(playerProgressControllerProvider.future);
    if (!context.mounted) return;
    await _GoldKeyProgressSheet.show(context, progress);
  }

  Future<void> _startLevel(BuildContext context, WidgetRef ref) async {
    // The start-of-round Gold Key choice sheet was removed (user
    // instruction) — every Level Mode round now starts with a free set of
    // booster charges (see `BoosterConstants`), so this just resumes a
    // saved round if there is one, or starts fresh.
    final savedRound = ref.read(roundSaveRepositoryProvider).load(
          GameModeType.level,
        );
    if (savedRound != null) {
      await context.push(AppRoutes.game, extra: savedRound.config);
      return;
    }

    await context.push(
      AppRoutes.game,
      extra: const GameLaunchConfig(mode: GameModeType.level),
    );
  }
}

/// The provided home screen artwork, shown full-bleed and unzoomed — the
/// user explicitly wants the whole scene visible, matching the original
/// image, not a cropped-in close-up. Its aspect ratio is close enough to a
/// modern phone screen's that plain `BoxFit.cover` barely crops anything
/// on its own.
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    // Decodes to the actual screen resolution rather than the source PNG's
    // full native size (853x1844, 3.8MB) — same crop/fit, cheaper decode.
    // Safe here because this widget is always used inside a
    // `Positioned.fill`, so the screen's physical size is the render size.
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      'assets/images/home_background.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: (size.width * dpr).round(),
      cacheHeight: (size.height * dpr).round(),
    );
  }
}

/// Opened from the header's Gold Key chip — shows the current balance and
/// progress toward the next milestone bonus (every
/// [GoldKeyConstants.levelsPerGoldKeyReward] completed levels grants one,
/// on top of the rewarded-ad source; see
/// `PlayerProgressController.advanceLevel`). Read-only — this is a
/// tracking view, not another choice sheet.
class _GoldKeyProgressSheet extends StatelessWidget {
  const _GoldKeyProgressSheet({required this.progress});

  final PlayerProgress progress;

  static Future<void> show(BuildContext context, PlayerProgress progress) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GoldKeyProgressSheet(progress: progress),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const perCycle = GoldKeyConstants.levelsPerGoldKeyReward;
    final completedLevels = progress.currentLevel - 1;
    final intoCycle = completedLevels % perCycle;
    final remaining = perCycle - intoCycle;
    final fraction = intoCycle / perCycle;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIconsFill.coin,
                    color: GamePalette.recordGold,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.goldKeySheetTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.paper),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${progress.goldKeyCount}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: GamePalette.recordGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.goldKeyCurrentBalance,
                style: TextStyle(
                  color: AppColors.paper.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.goldKeyMilestoneInfo(perCycle),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.paper,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 10,
                  backgroundColor: GamePalette.progressTrack,
                  color: GamePalette.recordGold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.goldKeyMilestoneProgress(intoCycle, perCycle, remaining),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.paper.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps the home header's coin `_TopChip` and adds a quick "+N" pop-up
/// animation whenever [goldKeyCount] increases (e.g. after watching a
/// rewarded ad) — kept local to this one widget so the effect never leaks
/// into any other coin-count display in the app (user instruction: "sadece
/// ana menüdeki coin sayısının belirtildiği pencerede gerçekleşsin").
class _CoinChip extends ConsumerStatefulWidget {
  const _CoinChip({required this.goldKeyCount, required this.onTap});

  final int goldKeyCount;
  final VoidCallback onTap;

  @override
  ConsumerState<_CoinChip> createState() => _CoinChipState();
}

class _CoinChipState extends ConsumerState<_CoinChip> {
  int? _gainAmount;
  int _gainGeneration = 0;

  @override
  void didUpdateWidget(covariant _CoinChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final diff = widget.goldKeyCount - oldWidget.goldKeyCount;
    if (diff > 0) {
      setState(() {
        _gainAmount = diff;
        _gainGeneration++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _TopChip(
          icon: PhosphorIconsFill.coin,
          label: '${widget.goldKeyCount}',
          onTap: widget.onTap,
        ),
        if (_gainAmount != null)
          Positioned(
            top: -16,
            right: 8,
            child: _CoinGainBadge(
              key: ValueKey(_gainGeneration),
              amount: _gainAmount!,
              onCompleted: () {
                if (mounted) setState(() => _gainAmount = null);
              },
            ),
          ),
      ],
    );
  }
}

/// A quick "+N" pop that scales/floats up and fades out on its own — user
/// instruction: "çok hızlı bir şekilde" ekleme animasyonu, so this runs in
/// under a second and needs no external driving beyond mounting.
class _CoinGainBadge extends StatefulWidget {
  const _CoinGainBadge({
    required super.key,
    required this.amount,
    required this.onCompleted,
  });

  final int amount;
  final VoidCallback onCompleted;

  @override
  State<_CoinGainBadge> createState() => _CoinGainBadgeState();
}

class _CoinGainBadgeState extends State<_CoinGainBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    unawaited(_controller.forward().whenComplete(widget.onCompleted));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final appear = (t / 0.15).clamp(0.0, 1.0);
          final fade = t < 0.5 ? 1.0 : 1 - ((t - 0.5) / 0.5).clamp(0.0, 1.0);
          return Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, -20 * t),
              child: Transform.scale(scale: 0.5 + 0.6 * appear, child: child),
            ),
          );
        },
        child: Text(
          '+${widget.amount}',
          style: const TextStyle(
            color: GamePalette.recordGold,
            fontWeight: FontWeight.bold,
            fontSize: 17,
            shadows: [Shadow(color: Colors.black87, blurRadius: 5)],
          ),
        ),
      ),
    );
  }
}

/// The three top-row chips (Coin, Ödüllü Reklam, Ayarlar) — restyled (user
/// instruction: "bizim tasarıma uygun yap") onto the same carved-wood pill
/// chrome every other button in the game now uses (`GamePalette`'s
/// wood-button gradient + solid drop "ledge" shadow, `SpringPressable`'s
/// press-and-bounce), replacing the old flat navy `Material` chip that
/// read as generic app-bar UI.
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
    return SpringPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GamePalette.woodButtonLight, GamePalette.woodButtonDark],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GamePalette.woodButtonBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(color: GamePalette.buttonLedge, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: GamePalette.recordGold, size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.paper,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.black38, blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
