import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/game_feel/screen_shake.dart';
import 'package:bb_block/core/game_feel/spring_pressable.dart';
import 'package:bb_block/core/providers/game_feel_providers.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/glass_panel.dart';
import 'package:bb_block/core/theme/image_background.dart';
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
import 'package:bb_block/l10n/app_localizations.dart';
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
        body: ImageBackground(
          assetPath: 'assets/images/game_background.png',
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
      body: ImageBackground(
        assetPath: 'assets/images/game_background.png',
        child: SafeArea(
          child: Stack(
            children: [
              ScreenShake(
                controller: ref.watch(screenShakeControllerProvider),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  // Transparent Glass Panel redesign (user instruction —
                  // visual only, see the doc comment on `_GlassGamePanel`
                  // for the full reasoning). Everything that used to be
                  // laid out directly inside the old opaque `Container`
                  // below is now the unmodified `child` of this glass
                  // wrapper instead — same padding, same Column, same
                  // children, same order.
                  child: _GlassGamePanel(
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
                                      starTargetRow: session.starTargetRow,
                                      starTargetColumn:
                                          session.starTargetColumn,
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
                                    // Roomy enough for a 5-tall vertical
                                    // line piece to render at a legible
                                    // size in its own slot without
                                    // clipping (user report) — PieceTray's
                                    // own per-slot fit-to-box logic is the
                                    // real fix; this just gives it enough
                                    // room to work with before it has to
                                    // shrink a piece down.
                                    height: cellSize * 2.6,
                                    child: PieceTray(
                                      tray: session.tray,
                                      dragCellSize: cellSize,
                                      board: session.board,
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
                _RoundOverlay(
                  config: config,
                  session: session,
                  goldKeyCount: progress.goldKeyCount,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Transparent Glass Panel" redesign (user instruction — visual only,
/// the game's forest background should read through the main HUD card
/// instead of being fully hidden behind an opaque wood panel). Replaces the
/// old plain opaque `Container` (solid `bezelLight`/`bezelDark` gradient)
/// that used to wrap the whole card — everything *inside* it (header,
/// board, controls, tray, footer) is unchanged, passed straight through as
/// [child]; only how the card's own background is painted changed.
///
/// Structure, innermost first:
///  - A real `BackdropFilter` blur (sigma 20, within the requested
///    18-24px range) of whatever's actually behind the panel — the forest
///    `ImageBackground` — clipped to just this panel's rounded rect (never
///    the whole screen), so this is the *only* place any blur happens.
///  - A semi-transparent wood gradient fill (`bezelLight`/`bezelDark` at
///    ~0.62 alpha, within the requested 0.55-0.70 range) over the blur —
///    keeps the existing wood-theme colors, just no longer opaque.
///  - A thin inner white highlight border for a soft "glass edge" sheen
///    (user instruction: "hafif beyaz highlight ve çok ince kenar
///    parlaklığı"), nested just inside the existing solid wood frame
///    border (which stays close to opaque — a frame's edge reads as
///    definition, not something that needs to be see-through).
///  - The drop shadow lives on an *outer, unclipped* wrapper — shadows
///    painted inside a `ClipRRect` get clipped away entirely, a common
///    glassmorphism pitfall, so it has to sit outside the blur/clip pair.
///
/// Nothing inside [child] (`BoardGrid`, `PieceTray`'s own dark panel,
/// booster/header/footer chrome) changed opacity at all — the board frame,
/// grid, blocks, buttons, icons, and text all stay fully opaque exactly as
/// before; only this outer card's own fill became see-through.
///
/// Performance (user instruction: no FPS drop, low-end devices too):
/// wrapped in its own `RepaintBoundary` so this panel's blur/composite
/// work is isolated into one layer — repaints from sibling overlays
/// (`_ScorePopup`, `_PauseOverlay`, `_RoundOverlay`) or the `ScreenShake`
/// wrapper above it don't force this layer to redo its blur pass, and vice
/// versa.
class _GlassGamePanel extends StatelessWidget {
  const _GlassGamePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;
    return RepaintBoundary(
      child: Container(
        // Shadow only — deliberately outside the ClipRRect/BackdropFilter
        // below, or it would be clipped away.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    GamePalette.bezelLight.withValues(alpha: 0.62),
                    GamePalette.bezelDark.withValues(alpha: 0.62),
                  ],
                ),
                border: Border.all(
                  color: GamePalette.panelDark.withValues(alpha: 0.85),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(1),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  borderRadius: BorderRadius.circular(radius - 3),
                ),
                child: child,
              ),
            ),
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
              ? _LevelProgress(
                  score: session.score,
                  level: progress.currentLevel,
                )
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
                    PhosphorIconsFill.coin,
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
          Text(
            AppLocalizations.of(context)!.goldKeyFooterLabel,
            style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: GlassPanel(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  PhosphorIconsFill.pauseCircle,
                  color: GamePalette.recordGold,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.pausedTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: AppColors.paper),
                ),
                const SizedBox(height: 20),
                _OverlayPrimaryButton(
                  label: Text(l10n.resumeButton),
                  onTap: onResume,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    l10n.mainMenuButton,
                    style: const TextStyle(color: AppColors.paper),
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

/// The prominent action button shared by the pause and round-over
/// overlays — a gold pill on `SpringPressable`, matching the rest of the
/// HUD's wood-chrome family instead of the theme's default `FilledButton`.
class _OverlayPrimaryButton extends StatelessWidget {
  const _OverlayPrimaryButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  // A `Widget` (not a plain string) so it can be a coin-cost `Row` — see
  // `_CoinCostLabel` — while still inheriting this button's own text style
  // via `DefaultTextStyle.merge`.
  final Widget label;
  final VoidCallback onTap;
  // Dims the button rather than hiding it — used by the Gold Coin continue
  // option when the player doesn't have enough to spend, so it's still
  // visible as an available *feature* (the button reappears at full
  // strength the moment they earn enough) rather than silently
  // disappearing.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SpringPressable(
        onTap: enabled ? onTap : () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [GamePalette.progressFillLight, GamePalette.recordGold],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: GamePalette.recordGold.withValues(alpha: 0.4),
                blurRadius: 14,
              ),
            ],
          ),
          child: DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            child: label,
          ),
        ),
      ),
    );
  }
}

/// "`prefix` (100 [coin icon])" — user instruction: the button's own
/// translated text, then a fixed count and the Gold Coin icon embedded
/// inline, then a closing paren. Inherits its text style from whatever
/// `DefaultTextStyle` it's placed inside (see `_OverlayPrimaryButton`), so
/// it automatically matches the surrounding button's color/weight/size.
class _CoinCostLabel extends StatelessWidget {
  const _CoinCostLabel({required this.prefix, required this.textColor});

  final String prefix;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    // `Wrap` rather than `Row`: the translated prefix is long enough to
    // overflow a `Row` on narrower screens — a real overflow bug caught by
    // the widget test suite (see the identical fix/comment on
    // `home_screen.dart`'s copy of this widget).
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
/// the 750-point frame-removal mark, which has no equivalent in the
/// reference but is real game information worth keeping visible.
class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.score, required this.level});

  final int score;
  final int level;

  @override
  Widget build(BuildContext context) {
    const target = LevelModeConstants.targetScore;
    const thresholdFraction = LevelModeConstants.frameRemovalThreshold / target;
    final fraction = (score / target).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.levelLabel(level),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.paper.withValues(alpha: 0.75),
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
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
  const _RoundOverlay({
    required this.config,
    required this.session,
    required this.goldKeyCount,
  });

  final GameLaunchConfig config;
  final GameSession session;
  final int goldKeyCount;

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
    final l10n = AppLocalizations.of(context)!;
    final content = ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVictory) const _VictoryFlash(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: GlassPanel(
                  padding: const EdgeInsets.all(28),
                  opacity: _isVictory ? 0.5 : 0.55,
                  child: DecoratedBox(
                    decoration: _isVictory
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: GamePalette.recordGold,
                              width: 2,
                            ),
                          )
                        : const BoxDecoration(),
                    child: Padding(
                      padding: _isVictory
                          ? const EdgeInsets.all(6)
                          : EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _title(l10n, session.outcome),
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
                              l10n.scoreLabel(value),
                              style: const TextStyle(
                                color: AppColors.paper,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Level Complete drops straight to a single gold
                          // "Main Menu" button — no "Next Level" (user
                          // instruction): the player picks their next
                          // Gold-Key choice fresh from the home screen
                          // rather than continuing straight through.
                          if (_isVictory)
                            _OverlayPrimaryButton(
                              label: Text(l10n.mainMenuButton),
                              onTap: () => context.pop(),
                            )
                          else if (session.outcome
                              is RoundOutcomeClassicGameOver) ...[
                            // User instruction: a prominent gold "spend
                            // coins and continue" option, with the existing
                            // Play Again/Main Menu pair kept but demoted to
                            // plain text so this new option reads as the
                            // primary path forward.
                            _OverlayPrimaryButton(
                              label: _CoinCostLabel(
                                prefix: l10n.continueWithCoinsPrefix,
                                textColor: AppColors.ink,
                              ),
                              enabled:
                                  widget.goldKeyCount >=
                                  GoldKeyConstants.actionCostCoins,
                              onTap: () => ref
                                  .read(
                                    gameControllerProvider(config).notifier,
                                  )
                                  .continueWithGoldKey(),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => ref.invalidate(
                                gameControllerProvider(config),
                              ),
                              child: Text(
                                _buttonLabel(l10n, session.outcome),
                                style: const TextStyle(color: AppColors.paper),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.pop(),
                              child: Text(
                                l10n.mainMenuButton,
                                style: const TextStyle(color: AppColors.paper),
                              ),
                            ),
                          ] else ...[
                            _OverlayPrimaryButton(
                              label: Text(_buttonLabel(l10n, session.outcome)),
                              onTap: () => ref.invalidate(
                                gameControllerProvider(config),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => context.pop(),
                              child: Text(
                                l10n.mainMenuButton,
                                style: const TextStyle(color: AppColors.paper),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    // Confetti (`Newton`) only ever fires for the victory case (see
    // `initState` above) — mounting a whole particle system + its own
    // always-running `Ticker` for game-over/level-failed overlays that will
    // never call `addEffect` was pure waste, so it's only wrapped here.
    return _isVictory ? Newton(key: _newtonKey, child: content) : content;
  }

  String _title(AppLocalizations l10n, RoundOutcome outcome) =>
      switch (outcome) {
        RoundOutcomeLevelComplete() => l10n.levelCompleteTitle,
        RoundOutcomeLevelFailed() => l10n.levelFailedTitle,
        RoundOutcomeClassicGameOver() => l10n.classicGameOverTitle,
        RoundOutcomeOngoing() => '',
      };

  // Only called for the non-victory branch now — Level Complete shows a
  // single "Main Menu" button directly (see `build`), never this one.
  String _buttonLabel(AppLocalizations l10n, RoundOutcome outcome) =>
      switch (outcome) {
        RoundOutcomeLevelComplete() => throw StateError(
          'Level Complete never reaches _buttonLabel',
        ),
        RoundOutcomeLevelFailed() ||
        RoundOutcomeClassicGameOver() ||
        RoundOutcomeOngoing() => l10n.playAgainButton,
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
    _controller.forward();
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
