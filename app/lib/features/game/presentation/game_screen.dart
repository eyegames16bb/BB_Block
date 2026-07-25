import 'dart:async';
import 'dart:math' as math;

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/game_feel/screen_shake.dart';
import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/providers/game_feel_providers.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/wood_background.dart';
import 'package:bb_block/features/game/application/game_controller.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/booster_bar.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_tray.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_dust_effect.dart';
import 'package:bb_block/features/game_engine/domain/game_session.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/settings/presentation/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:newton_particles/newton_particles.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({required this.config, super.key});

  final GameLaunchConfig config;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  // Single Cell Remove still targets a board cell, so it keeps an
  // arm-then-tap flow. Rotate no longer does — it applies to the whole
  // tray instantly on tap, the same as Swap.
  bool _removalArmed = false;
  bool _isPaused = false;

  // Bumped every time the score goes up, so the keyed `_ScorePopup` below
  // plays a fresh "+N" rise-and-fade each time instead of only once.
  int _scorePopupGeneration = 0;
  int _scorePopupDelta = 0;

  bool get _boostersVisible => widget.config.mode == GameModeType.level;

  @override
  void initState() {
    super.initState();
    // Backgrounding mid-round (a call, switching apps, the OS lock screen)
    // pauses the round rather than leaving the board live and exposed to
    // phantom touches on return — the player must explicitly resume.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wentToBackground =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (!wentToBackground || !mounted) return;

    final session = ref.read(gameControllerProvider(widget.config));
    if (session.isOver) return;
    setState(() => _isPaused = true);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final progressAsync = ref.watch(playerProgressControllerProvider);

    // GameController seeds Level Mode's persistent booster charges from
    // PlayerProgress synchronously the instant it first builds — wait for
    // that load to actually finish before creating it, or a cold
    // navigation could seed a fresh engine with fallback defaults instead
    // of the player's real saved charges (which never gets corrected
    // afterwards, since the engine is only built once per round).
    if (config.mode == GameModeType.level && !progressAsync.hasValue) {
      return const Scaffold(
        body: WoodBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.paper),
          ),
        ),
      );
    }

    final session = ref.watch(gameControllerProvider(config));
    final controller = ref.read(gameControllerProvider(config).notifier);
    final progress = progressAsync.value ?? const PlayerProgress();

    ref.listen<GameSession>(gameControllerProvider(config), (previous, next) {
      if (previous != null && next.score > previous.score) {
        setState(() {
          _scorePopupDelta = next.score - previous.score;
          _scorePopupGeneration++;
        });
      }
    });

    return Scaffold(
      body: WoodBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ScreenShake(
                controller: ref.watch(screenShakeControllerProvider),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [GamePalette.bezelLight, GamePalette.bezelDark],
                      ),
                      border: Border.all(
                        color: GamePalette.panelDark,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _Header(
                          config: config,
                          session: session,
                          progress: progress,
                          onPause: () => setState(() => _isPaused = true),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Cap the board to the smaller of the available
                              // width and a height budget that leaves room for
                              // the controls row (when shown) and the tray
                              // below it, so nothing overflows on any screen.
                              final reservedHeight = _boostersVisible
                                  ? 118.0
                                  : 0.0;
                              final boardSide = math.min(
                                constraints.maxWidth,
                                (constraints.maxHeight - reservedHeight) * 0.74,
                              );
                              final cellSize = boardSide / session.board.size;

                              // Board → controls row → piece dock, matching
                              // the reference mockup's `.grid-container` →
                              // `.controls` → `.piece-dock` order (this HUD
                              // previously showed the tray above the booster
                              // row instead).
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: boardSide,
                                    height: boardSide,
                                    child: BoardGrid(
                                      board: session.board,
                                      tray: session.tray,
                                      removalArmed: _removalArmed,
                                      onCellTap: (position) {
                                        controller.removeCell(position);
                                        setState(() => _removalArmed = false);
                                      },
                                      onPlace: (trayIndex, anchor) =>
                                          controller.placePiece(
                                            trayIndex: trayIndex,
                                            anchor: anchor,
                                          ),
                                    ),
                                  ),
                                  if (_boostersVisible) ...[
                                    const SizedBox(height: 12),
                                    BoosterBar(
                                      rotateCharges: session.rotateCharges,
                                      swapCharges: session.swapCharges,
                                      singleCellRemoveCharges:
                                          session.singleCellRemoveCharges,
                                      removalArmed: _removalArmed,
                                      onRotateTap: controller.rotateTray,
                                      onSwapTap: controller.swapTray,
                                      onRemovalTap: () => setState(
                                        () => _removalArmed = !_removalArmed,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: boardSide,
                                    height: cellSize * 2.2,
                                    child: PieceTray(
                                      tray: session.tray,
                                      dragCellSize: cellSize,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Footer(goldKeyCount: progress.goldKeyCount),
                      ],
                    ),
                  ),
                ),
              ),
              if (_scorePopupGeneration > 0)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: _ScorePopup(
                        key: ValueKey(_scorePopupGeneration),
                        delta: _scorePopupDelta,
                      ),
                    ),
                  ),
                ),
              if (_isPaused && !session.isOver)
                _PauseOverlay(
                  onResume: () => setState(() => _isPaused = false),
                ),
              if (session.isOver)
                _RoundOverlay(config: config, session: session),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.config,
    required this.session,
    required this.progress,
    required this.onPause,
  });

  final GameLaunchConfig config;
  final GameSession session;
  final PlayerProgress progress;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final isLevel = config.mode == GameModeType.level;
    // The badge must read as "your best" the instant this round beats it,
    // not lag behind until the async persistence write lands — see
    // GameController._apply, which is what actually saves the new best.
    final persistedBest = config.classicHasFrame
        ? progress.classicHighScoreFramed
        : progress.classicHighScoreFrameless;
    final highScore = math.max(persistedBest, session.score);

    return Row(
      children: [
        _RoundIconButton(
          icon: PhosphorIcons.arrowLeft,
          onTap: () => context.pop(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: isLevel
              ? _LevelProgress(score: session.score)
              : Row(
                  children: [
                    _RecordBadge(highScore: highScore),
                    const SizedBox(width: 12),
                    Text(
                      '${session.score}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.paper,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 8),
        _RoundIconButton(icon: PhosphorIcons.pause, onTap: onPause),
        const SizedBox(width: 8),
        _RoundIconButton(
          icon: PhosphorIcons.gear,
          onTap: () => SettingsSheet.show(context),
        ),
      ],
    );
  }
}

/// The crown-badged high-score chip from the reference mockup's `.score`
/// pill — only meaningful in Classic Mode, where there's a persistent best
/// to compare against (Level Mode already shows progress toward the
/// 1000-point goal).
class _RecordBadge extends StatelessWidget {
  const _RecordBadge({required this.highScore});

  final int highScore;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GamePalette.panelDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GamePalette.panelDarkBorder, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              PhosphorIcons.crownFill,
              color: GamePalette.recordGold,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              '$highScore',
              style: const TextStyle(
                color: AppColors.paper,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.footer` from the reference mockup — the game title on the left,
/// mirrored by [_GoldKeyFooterBadge] on the right in the `.shop-btn` spot.
/// This game has no coin/shop economy, so the badge shows the real Gold Key
/// balance instead of fabricating a currency display that leads nowhere.
class _Footer extends StatelessWidget {
  const _Footer({required this.goldKeyCount});

  final int goldKeyCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BB Block',
              style: TextStyle(
                color: AppColors.paper.withValues(alpha: 0.85),
                fontSize: 14,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
            Text(
              'PUZZLE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.paper,
                letterSpacing: 1,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
        _GoldKeyFooterBadge(count: goldKeyCount),
      ],
    );
  }
}

class _GoldKeyFooterBadge extends StatelessWidget {
  const _GoldKeyFooterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GamePalette.woodButtonLight, GamePalette.woodButtonDark],
        ),
        border: Border.all(color: GamePalette.woodButtonBorder, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: GamePalette.buttonLedge, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: GamePalette.panelDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIcons.keyFill,
                    color: GamePalette.recordGold,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Anahtar',
            style: TextStyle(
              color: AppColors.paper,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded-square wood button with a solid drop "ledge" beneath it —
/// `.icon-btn`'s gradient/border/box-shadow from the reference mockup,
/// replacing the earlier flat navy circle. [SpringPressable] adds the
/// press-down feedback the reference's chunky 3D chrome implies.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringPressable(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GamePalette.woodButtonLight, GamePalette.woodButtonDark],
          ),
          border: Border.all(color: GamePalette.woodButtonBorder, width: 2),
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [
            BoxShadow(color: GamePalette.buttonLedge, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: AppColors.ink, size: 20),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Card(
          color: AppColors.navy,
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Duraklatıldı',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: AppColors.paper),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onResume,
                  child: const Text('Devam Et'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Ana Menü',
                    style: TextStyle(color: AppColors.paper),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A "+N" that rises and fades over the header when the score jumps —
/// covers both a plain placement and a placement-plus-line-clear turn,
/// since the controller republishes state once per turn with the combined
/// total already applied.
class _ScorePopup extends StatelessWidget {
  const _ScorePopup({required this.delta, super.key});

  final int delta;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: 1 - t,
        child: Transform.translate(
          offset: Offset(0, -28 * t),
          child: child,
        ),
      ),
      child: Text(
        '+$delta',
        style: const TextStyle(
          color: GamePalette.recordGold,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
        ),
      ),
    );
  }
}

/// A chunky rounded gradient bar over a dark track — `.progress-bar`/
/// `.progress-fill` from the reference mockup — plus a threshold tick at
/// the 900-point frame-removal mark, which has no equivalent in the
/// reference but is real game information worth keeping visible.
class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    const target = LevelModeConstants.targetScore;
    const thresholdFraction = LevelModeConstants.frameRemovalThreshold / target;
    final fraction = (score / target).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$score / $target',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.paper,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          key: const Key('level-progress-bar'),
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: GamePalette.progressTrack,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: GamePalette.panelDarkBorder),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            GamePalette.progressFillDark,
                            GamePalette.progressFillLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * thresholdFraction - 1,
                    top: 1,
                    child: Container(
                      width: 2,
                      height: 10,
                      color: AppColors.paper.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoundOverlay extends ConsumerStatefulWidget {
  const _RoundOverlay({required this.config, required this.session});

  final GameLaunchConfig config;
  final GameSession session;

  @override
  ConsumerState<_RoundOverlay> createState() => _RoundOverlayState();
}

class _RoundOverlayState extends ConsumerState<_RoundOverlay> {
  final _newtonKey = GlobalKey<NewtonState>();
  bool get _isVictory => widget.session.outcome is RoundOutcomeLevelComplete;

  @override
  void initState() {
    super.initState();
    // Level Complete's confetti — a golden flourish the game-over/level-
    // failed cases deliberately don't get, per the GDD's "Golden Glow /
    // Konfeti" spec for this specific moment. Staggered bursts read fuller
    // than a single one-shot puff.
    if (_isVictory) {
      for (final delayMs in [0, 140, 260]) {
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (!mounted) return;
          _newtonKey.currentState?.addEffect(
            confettiBurst(
              origin: Offset(0.2 + delayMs / 1000, 0),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final config = widget.config;
    return Newton(
      key: _newtonKey,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVictory) const _VictoryFlash(),
            Center(
              child: Card(
                color: AppColors.navy,
                margin: const EdgeInsets.all(32),
                shape: _isVictory
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: GamePalette.recordGold,
                          width: 2,
                        ),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _title(session.outcome),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: _isVictory
                                  ? GamePalette.recordGold
                                  : AppColors.paper,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: session.score),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          'Skor: $value',
                          style: const TextStyle(
                            color: AppColors.paper,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(gameControllerProvider(config)),
                        child: Text(_buttonLabel(session.outcome)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'Ana Menü',
                          style: TextStyle(color: AppColors.paper),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(RoundOutcome outcome) => switch (outcome) {
    RoundOutcomeLevelComplete() => 'Bölüm Tamamlandı!',
    RoundOutcomeLevelFailed() => 'Bölüm Başarısız',
    RoundOutcomeClassicGameOver() => 'Oyun Bitti',
    RoundOutcomeOngoing() => '',
  };

  // A completed level moves forward to the next one (mechanically just a
  // fresh session under decision #5 — every level plays the same), not a
  // repeat of the one just finished, so it gets its own label instead of
  // reusing "Tekrar Oyna" ("Play Again").
  String _buttonLabel(RoundOutcome outcome) => switch (outcome) {
    RoundOutcomeLevelComplete() => 'Sonraki Bölüm',
    RoundOutcomeLevelFailed() ||
    RoundOutcomeClassicGameOver() ||
    RoundOutcomeOngoing() => 'Tekrar Oyna',
  };
}

/// A brief golden screen flash for Level Complete — fades in fast and out
/// slow, like a camera flash rather than a slow cross-fade, per the GDD's
/// "Screen Flash" spec point.
class _VictoryFlash extends StatefulWidget {
  const _VictoryFlash();

  @override
  State<_VictoryFlash> createState() => _VictoryFlashState();
}

class _VictoryFlashState extends State<_VictoryFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    unawaited(_controller.forward());
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.55), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0), weight: 85),
    ]).animate(_controller);
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
        animation: _opacity,
        builder: (context, child) => Opacity(
          opacity: _opacity.value,
          child: Container(color: GamePalette.recordGold),
        ),
      ),
    );
  }
}
