import 'dart:math' as math;

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/wood_background.dart';
import 'package:bb_block/features/game/application/game_controller.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/booster_bar.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_tray.dart';
import 'package:bb_block/features/game_engine/domain/game_session.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/settings/presentation/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

enum _ArmedBooster { rotate, remove }

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({required this.config, super.key});

  final GameLaunchConfig config;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  _ArmedBooster? _armed;
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
    final wentToBackground = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Header(
                      config: config,
                      session: session,
                      progress: progress,
                      onPause: () => setState(() => _isPaused = true),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Cap the board to the smaller of the available
                          // width and a height budget that leaves room for
                          // the tray (and the booster bar, when shown)
                          // below it, so nothing overflows on any screen.
                          final reservedHeight =
                              _boostersVisible ? 88.0 : 0.0;
                          final boardSide = math.min(
                            constraints.maxWidth,
                            (constraints.maxHeight - reservedHeight) * 0.74,
                          );
                          final cellSize = boardSide / session.board.size;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: boardSide,
                                height: boardSide,
                                child: BoardGrid(
                                  board: session.board,
                                  tray: session.tray,
                                  removalArmed:
                                      _armed == _ArmedBooster.remove,
                                  onCellTap: (position) {
                                    controller.removeCell(position);
                                    setState(() => _armed = null);
                                  },
                                  onPlace: (trayIndex, anchor) =>
                                      controller.placePiece(
                                    trayIndex: trayIndex,
                                    anchor: anchor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: boardSide,
                                height: cellSize * 2.2,
                                child: PieceTray(
                                  tray: session.tray,
                                  dragCellSize: cellSize,
                                  rotateArmed: _armed == _ArmedBooster.rotate,
                                  onPieceTap: (trayIndex) {
                                    controller.rotatePiece(trayIndex);
                                    setState(() => _armed = null);
                                  },
                                ),
                              ),
                              if (_boostersVisible) ...[
                                const SizedBox(height: 16),
                                BoosterBar(
                                  rotateCharges: session.rotateCharges,
                                  swapCharges: session.swapCharges,
                                  singleCellRemoveCharges:
                                      session.singleCellRemoveCharges,
                                  goldKeyCount: progress.goldKeyCount,
                                  rotateArmed: _armed == _ArmedBooster.rotate,
                                  removalArmed:
                                      _armed == _ArmedBooster.remove,
                                  onRotateTap: () => setState(
                                    () => _armed =
                                        _armed == _ArmedBooster.rotate
                                            ? null
                                            : _ArmedBooster.rotate,
                                  ),
                                  onSwapTap: () {
                                    controller.swapTray();
                                    setState(() => _armed = null);
                                  },
                                  onRemovalTap: () => setState(
                                    () => _armed =
                                        _armed == _ArmedBooster.remove
                                            ? null
                                            : _ArmedBooster.remove,
                                  ),
                                  onRefill: (kind) => ref
                                      .read(
                                        playerProgressControllerProvider
                                            .notifier,
                                      )
                                      .refillBooster(kind),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
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

/// The crown-badged high-score chip from the reference mockups — only
/// meaningful in Classic Mode, where there's a persistent best to compare
/// against (Level Mode already shows progress toward the 1000-point goal).
class _RecordBadge extends StatelessWidget {
  const _RecordBadge({required this.highScore});

  final int highScore;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(10),
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
                color: GamePalette.recordGold,
                fontWeight: FontWeight.bold,
              ),
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
          child: Icon(icon, color: AppColors.paper, size: 20),
        ),
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
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppColors.paper),
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

/// A thin line + threshold tick, matching the reference mockups, instead of
/// a stock Material [LinearProgressIndicator].
class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    const target = LevelModeConstants.targetScore;
    const thresholdFraction =
        LevelModeConstants.frameRemovalThreshold / target;
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
        const SizedBox(height: 8),
        SizedBox(
          key: const Key('level-progress-bar'),
          height: 10,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 3.5),
                      decoration: BoxDecoration(
                        color: GamePalette.recordGold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * thresholdFraction - 1,
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

class _RoundOverlay extends ConsumerWidget {
  const _RoundOverlay({required this.config, required this.session});

  final GameLaunchConfig config;
  final GameSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
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
                  _title(session.outcome),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppColors.paper),
                ),
                const SizedBox(height: 12),
                Text(
                  'Skor: ${session.score}',
                  style: const TextStyle(color: AppColors.paper, fontSize: 18),
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
        RoundOutcomeOngoing() =>
          'Tekrar Oyna',
      };
}
