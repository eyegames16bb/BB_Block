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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopChip(
                        icon: PhosphorIcons.filmSlate,
                        label: l10n.rewardedAdChip,
                        onTap: () => _confirmWatchAd(context),
                      ),
                      Row(
                        children: [
                          _CoinChip(
                            goldKeyCount: progress.goldKeyCount,
                            onTap: () => _showGoldKeyProgress(context, ref),
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
                  // No separate "BB Block" title here — the artwork
                  // already carries its own large title graphic near the
                  // top, and stacking our own text right under it read as
                  // two competing titles. The best-score readout moves
                  // down near the buttons instead of floating over the
                  // character's face.
                  const Spacer(),
                  _BestScores(progress: progress),
                  const SizedBox(height: 16),
                  PremiumGameButton(
                    label: l10n.levelLabel(progress.currentLevel),
                    icon: PhosphorIconsFill.mountains,
                    glossTop: const Color(0xFF8DE25C),
                    glossMid: const Color(0xFF5DBE38),
                    glossDeep: const Color(0xFF3C9626),
                    onTap: () => _startLevel(context, ref),
                  ),
                  const SizedBox(height: 14),
                  PremiumGameButton(
                    label: l10n.classicModeButton,
                    icon: PhosphorIconsFill.crown,
                    glossTop: const Color(0xFF6FD1F5),
                    glossMid: const Color(0xFF2E9FE0),
                    glossDeep: const Color(0xFF1B6FA8),
                    onTap: () => _startClassic(context, ref),
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
    // Revised user instruction: the Çerçeve Var/Yok sheet is always shown
    // now, every time — it's no longer skipped even if a round is already
    // in progress. What DOES persist per variant is the round itself: once
    // the player picks a frame option, whichever round (if any) was saved
    // for *that specific variant* resumes exactly as it was; each variant
    // keeps a fully independent in-progress round (and, as before, its own
    // separate high score).
    final hasFrame = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FrameChoiceSheet(),
    );
    if (hasFrame == null || !context.mounted) return;

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

  /// Warning dialog shown before actually navigating to the (test) rewarded
  /// ad — user instruction: confirm the +100 Coin reward up front, with a
  /// single gold "Reklam İzle" button, rather than jumping straight into
  /// the ad screen.
  Future<void> _confirmWatchAd(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const _WatchAdConfirmDialog(),
    );
    if (confirmed == true && context.mounted) {
      await context.push(AppRoutes.rewardedAd);
    }
  }

  Future<void> _showGoldKeyProgress(BuildContext context, WidgetRef ref) async {
    // Same staleness concern as `_startLevel`: re-read fresh rather than
    // trust whatever `progress` the chip was built with.
    final progress = await ref.read(playerProgressControllerProvider.future);
    if (!context.mounted) return;
    await _GoldKeyProgressSheet.show(context, progress);
  }

  Future<void> _startLevel(BuildContext context, WidgetRef ref) async {
    // Same "resume exactly as it was" rule as Classic Mode — a round still
    // in progress takes priority over the Gold Key choice sheet/lock-in
    // logic below entirely, since that choice was already made for it.
    final savedRound = ref.read(roundSaveRepositoryProvider).load(
          GameModeType.level,
        );
    if (savedRound != null) {
      await context.push(AppRoutes.game, extra: savedRound.config);
      return;
    }

    final controller = ref.read(playerProgressControllerProvider.notifier);
    // Re-read fresh after the load settles rather than trusting whatever
    // `progress` the calling button was built with — the load may still
    // have been in flight (falling back to a default PlayerProgress) at
    // the moment that widget was built.
    final progress = await ref.read(playerProgressControllerProvider.future);
    if (!context.mounted) return;

    // A choice already locked in for this exact level (either a fresh
    // attempt just chose one, or a previous attempt at the same level
    // failed and is being retried) skips the sheet entirely and reuses it
    // — no re-asking, no re-spending. See PlayerProgress's doc comment.
    if (progress.pendingLevelChoiceLevel == progress.currentLevel) {
      await context.push(
        AppRoutes.game,
        extra: GameLaunchConfig(
          mode: GameModeType.level,
          levelBoostersUnlocked: progress.pendingLevelBoostersUnlocked,
        ),
      );
      return;
    }

    // Playing without a key is no longer offered — the sheet's only button
    // spends one. `null` means it was dismissed instead (or the player had
    // no key to spend), so no round starts.
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _LevelStartSheet(goldKeyCount: progress.goldKeyCount),
    );
    if (confirmed != true || !context.mounted) return;

    final boostersUnlocked = await controller.spendGoldKeyForBoosters();
    if (!context.mounted) return;
    await controller.setPendingLevelChoice(
      level: progress.currentLevel,
      boostersUnlocked: boostersUnlocked,
    );
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

/// A frosted-glass stat row instead of stacked plain text lines — three
/// compact stat cells (framed best, frameless best, level) separated by
/// thin dividers, sitting just above the mode buttons rather than floating
/// mid-screen over the artwork.
class _BestScores extends StatelessWidget {
  const _BestScores({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      borderRadius: 18,
      opacity: 0.4,
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: PhosphorIconsFill.crown,
              value: '${progress.classicHighScoreFramed}',
              label: l10n.statFramed,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: PhosphorIconsFill.crown,
              value: '${progress.classicHighScoreFrameless}',
              label: l10n.statFrameless,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: PhosphorIconsFill.mountains,
              value: '${progress.currentLevel}',
              label: l10n.statLevel,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: GamePalette.recordGold, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.paper,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.paper.withValues(alpha: 0.65),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: Colors.white.withValues(alpha: 0.16),
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

/// The "watch ad, earn +100 Coin" warning dialog (user instruction) — a
/// centered alert rather than a bottom sheet, since the request was
/// specifically for a "uyarı penceresi". Single gold button; tapping outside
/// the dialog dismisses it without navigating anywhere (no separate cancel
/// button was requested).
class _WatchAdConfirmDialog extends StatelessWidget {
  const _WatchAdConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: GlassPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              PhosphorIconsFill.coin,
              color: GamePalette.recordGold,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.watchAdConfirmMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.paper,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _StartChoiceButton(
              label: Text(l10n.watchAdConfirmButton),
              prominent: true,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
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
          iconColor: GamePalette.recordGold,
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

class _FrameChoiceSheet extends StatelessWidget {
  const _FrameChoiceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.frameSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.paper),
              ),
              const SizedBox(height: 16),
              _SheetChoiceButton(
                label: l10n.frameChoiceWithFrame,
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 12),
              _SheetChoiceButton(
                label: l10n.frameChoiceWithoutFrame,
                onTap: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Level Mode's start-of-round confirmation: spend
/// [GoldKeyConstants.actionCostCoins] Gold Coins to play this round with one
/// charge of every booster (never refillable, never carried to the next
/// level — see `PlayerProgress`'s doc comment). Playing without spending is
/// no longer offered (user instruction) — with an insufficient balance the
/// button just stays disabled with an explanatory subtitle, and dismissing
/// the sheet returns to the home menu without starting a round.
class _LevelStartSheet extends StatelessWidget {
  const _LevelStartSheet({required this.goldKeyCount});

  final int goldKeyCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canUseKey = goldKeyCount >= GoldKeyConstants.actionCostCoins;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.levelSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.paper),
              ),
              const SizedBox(height: 10),
              // The star-bonus hint (user instruction) — deliberately a
              // tick smaller than the button's own 16px label below it.
              Text(
                l10n.levelSheetHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.paper.withValues(alpha: 0.75),
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              _StartChoiceButton(
                label: _CoinCostLabel(
                  prefix: l10n.startWithBoostersPrefix,
                  textColor: AppColors.ink,
                ),
                subtitle: canUseKey
                    ? l10n.startWithKeySubtitleHave(goldKeyCount)
                    : l10n.startWithKeySubtitleNone,
                prominent: true,
                onTap: canUseKey
                    ? () => Navigator.of(context).pop(true)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The prominent (spend-coins) vs. pale (no boosters) pair from the Level
/// Mode start sheet — deliberately different weights so the paid option
/// visually reads as the "better" choice, per user instruction. [label] is
/// a `Widget` (not a plain string) so it can be a coin-cost `Row` — see
/// `_CoinCostLabel` — while still inheriting this button's own text style
/// via `DefaultTextStyle.merge`.
class _StartChoiceButton extends StatelessWidget {
  const _StartChoiceButton({
    required this.label,
    required this.prominent,
    required this.onTap,
    this.subtitle,
  });

  final Widget label;
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
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: prominent
                      ? AppColors.ink
                      : AppColors.paper.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                child: label,
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

/// "`prefix` (100 [coin icon])" — user instruction: the button's own
/// translated text, then a fixed count and the Gold Coin icon embedded
/// inline, then a closing paren. Inherits its text style from whatever
/// `DefaultTextStyle` it's placed inside (see `_StartChoiceButton`), so it
/// automatically matches the surrounding button's color/weight/size.
class _CoinCostLabel extends StatelessWidget {
  const _CoinCostLabel({required this.prefix, required this.textColor});

  final String prefix;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    // `Wrap` rather than `Row`: the translated prefix is long enough (TR
    // especially) to overflow a `Row` on narrower screens — this was a
    // real overflow bug caught by the widget test suite. `Wrap` just flows
    // the icon/closing-paren onto a second line instead of erroring.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: style),
        const SizedBox(width: 4),
        Icon(
          PhosphorIconsFill.coin,
          color: textColor,
          size: (style.fontSize ?? 16) + 2,
        ),
        Text(')', style: style),
      ],
    );
  }
}

class _SheetChoiceButton extends StatelessWidget {
  const _SheetChoiceButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SpringPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.paper,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
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
