import 'dart:async';

import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/providers/analytics_providers.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/glass_panel.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// The game's own "test ad" — user instruction: replace the real AdMob
/// rewarded ad with an in-house one (`AdMobAdsService` stays wired for
/// other future ad placements, just no longer called from this button —
/// see CLAUDE.md). A fixed view of `BB_Block_Test_Reklam.png` on a black
/// backdrop for `_adDuration` (6s → 20s, a more realistic rewarded-ad
/// length), with a rotating ring that drains in step with a numeric
/// countdown (user instruction) standing in for a real ad's playback, then
/// a close (X) button. Closing it is what counts as "watched" — the Gold
/// Key is granted right there, before the rating prompt, so skipping or
/// dismissing the rating afterward doesn't cost the reward.
class RewardedAdScreen extends ConsumerStatefulWidget {
  const RewardedAdScreen({super.key});

  @override
  ConsumerState<RewardedAdScreen> createState() => _RewardedAdScreenState();
}

enum _AdPhase { playing, closeable, rating }

class _RewardedAdScreenState extends ConsumerState<RewardedAdScreen>
    with SingleTickerProviderStateMixin {
  static const _adDuration = Duration(seconds: 20);

  late final AnimationController _spinController;
  late final Timer _closeableTimer;
  _AdPhase _phase = _AdPhase.playing;
  int _starRating = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: _adDuration);
    _spinController.forward();
    _closeableTimer = Timer(_adDuration, () {
      if (mounted) setState(() => _phase = _AdPhase.closeable);
    });
  }

  @override
  void dispose() {
    _closeableTimer.cancel();
    _spinController.dispose();
    super.dispose();
  }

  void _onAdClosed() {
    // Watching the (test) ad is what earns the reward — independent of
    // whatever happens in the rating prompt that follows.
    unawaited(
      ref.read(playerProgressControllerProvider.notifier).grantGoldKey(),
    );
    // Feeds the eyegames.net admin dashboard's ad-view counter — logged at
    // the exact same "watched" moment as the reward itself.
    unawaited(ref.read(analyticsServiceProvider).logRewardedAdView());
    setState(() => _phase = _AdPhase.rating);
  }

  void _finish() {
    // Navigator.pop rather than go_router's context.pop — this screen is
    // always pushed as a plain route (see AppRoutes.rewardedAd), and the
    // plain Navigator API works whether that route sits under go_router
    // (production) or a bare MaterialPageRoute (tests).
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _phase == _AdPhase.rating
            ? _RatingPrompt(
                l10n: l10n,
                rating: _starRating,
                onRatingChanged: (value) =>
                    setState(() => _starRating = value),
                onDone: _finish,
              )
            : _AdContent(
                spinController: _spinController,
                totalSeconds: _adDuration.inSeconds,
                phase: _phase,
                l10n: l10n,
                onClose: _onAdClosed,
              ),
      ),
    );
  }
}

class _AdContent extends StatelessWidget {
  const _AdContent({
    required this.spinController,
    required this.totalSeconds,
    required this.phase,
    required this.l10n,
    required this.onClose,
  });

  final AnimationController spinController;
  final int totalSeconds;
  final _AdPhase phase;
  final AppLocalizations l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/rewarded_ad_promo.png',
            width: 320,
            fit: BoxFit.cover,
            // The source PNG is 1536x1024 — decoding it at native
            // resolution for a 320-logical-pixel-wide box wastes memory on
            // every device. `cacheWidth` decodes straight to the display
            // size (scaled for DPR) instead.
            cacheWidth: (320 * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: 56,
          height: 56,
          child: phase == _AdPhase.playing
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // The ring itself both spins (so it plainly reads as a
                    // "loading" indicator, user instruction: "dönen
                    // yüklenen bir daire") and drains from a full circle
                    // down to nothing exactly in step with the countdown
                    // below (`value: 1 - spinController.value`) — a plain
                    // indeterminate spinner has no relationship to the
                    // actual wait time at all, this one is directly tied
                    // to it.
                    RotationTransition(
                      turns: spinController,
                      child: AnimatedBuilder(
                        animation: spinController,
                        builder: (context, _) => CircularProgressIndicator(
                          value: 1 - spinController.value,
                          color: GamePalette.recordGold,
                          backgroundColor: Colors.white24,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                    // The numeric countdown (user instruction: "kaç saniye
                    // ise bekleme süresi geri sayım ekle") — whatever
                    // `_adDuration` actually is, this always counts down
                    // from it rather than a hardcoded number, so it stays
                    // correct if the duration is ever tuned again.
                    AnimatedBuilder(
                      animation: spinController,
                      builder: (context, _) {
                        final remaining = (totalSeconds *
                                (1 - spinController.value))
                            .ceil()
                            .clamp(0, totalSeconds);
                        return Text(
                          '$remaining',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        );
                      },
                    ),
                  ],
                )
              : SpringPressable(
                  onTap: onClose,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: GamePalette.recordGold,
                    ),
                    child: const Icon(
                      PhosphorIconsBold.x,
                      color: AppColors.ink,
                      size: 28,
                    ),
                  ),
                ),
        ),
        if (phase == _AdPhase.playing) ...[
          const SizedBox(height: 14),
          Text(
            l10n.adSkipHint,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ],
    );
  }
}

/// The in-app "rate us" prompt shown right after the ad closes — user
/// instruction: don't drop straight back to the home menu, ask for a
/// rating first, but the Gold Key is already granted by this point
/// regardless of whether the player actually rates.
class _RatingPrompt extends StatelessWidget {
  const _RatingPrompt({
    required this.l10n,
    required this.rating,
    required this.onRatingChanged,
    required this.onDone,
  });

  final AppLocalizations l10n;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: GlassPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.rateUsTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.paper),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.rateUsBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.paper.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final filled = index < rating;
                return IconButton(
                  onPressed: () => onRatingChanged(index + 1),
                  icon: Icon(
                    filled ? PhosphorIconsFill.star : PhosphorIconsBold.star,
                    color: GamePalette.recordGold,
                    size: 30,
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            _PromptButton(
              label: l10n.rateUsSubmit,
              prominent: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.rateUsThanks)),
                );
                onDone();
              },
            ),
            const SizedBox(height: 8),
            _PromptButton(
              label: l10n.rateUsSkip,
              prominent: false,
              onTap: onDone,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptButton extends StatelessWidget {
  const _PromptButton({
    required this.label,
    required this.prominent,
    required this.onTap,
  });

  final String label;
  final bool prominent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: prominent ? GamePalette.recordGold : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: prominent
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: prominent ? AppColors.ink : AppColors.paper,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
