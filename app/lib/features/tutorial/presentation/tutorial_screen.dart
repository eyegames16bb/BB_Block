import 'dart:async';
import 'dart:math' as math;

import 'package:bb_block/core/game_feel/screen_shake.dart';
import 'package:bb_block/core/providers/game_feel_providers.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/image_background.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/board/domain/services/line_clear_resolver.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_tray.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// One interactive step: a hand-built board and [shape], with exactly one
/// anchor ([anchor]) that counts as "correct" — enforced by `_onPlace`
/// checking the anchor directly, not by making every other spot on the
/// board structurally impossible. That keeps each board simple (mostly
/// empty, with just the cells the step actually cares about filled) instead
/// of needing a fully-packed board where a stray already-complete row or
/// column elsewhere would clear right along with the intended one — a real
/// bug this design deliberately avoids (an earlier "fill everything except
/// the gap" version accidentally left most other rows/columns already
/// complete, so the very first placement swept the whole board).
class _TutorialStep {
  const _TutorialStep({
    required this.board,
    required this.shape,
    required this.anchor,
  });

  final Board board;
  final PieceShape shape;
  final GridPosition anchor;
}

const _boardSize = 10;

Board _boardWithFilled(Set<GridPosition> filled) {
  final cells = [
    for (var row = 0; row < _boardSize; row++)
      for (var column = 0; column < _boardSize; column++)
        filled.contains(GridPosition(row: row, column: column))
            ? CellState.filled
            : CellState.empty,
  ];
  return Board(size: _boardSize, cells: cells);
}

/// The empty cells for step 2's board — the 2x2 square anchor at (4,4) plus
/// one isolated single-cell gap in each of its two rows/columns so placing
/// the square can't accidentally complete four lines at once. See the doc
/// comment on `step2Filled` in `_buildSteps` for the full reasoning.
bool _isStep2Gap(int row, int column) {
  const anchorRow = 4;
  const anchorColumn = 4;
  final inAnchorSquare =
      row >= anchorRow &&
      row <= anchorRow + 1 &&
      column >= anchorColumn &&
      column <= anchorColumn + 1;
  if (inAnchorSquare) return true;
  final extraGaps = {
    const GridPosition(row: anchorRow, column: 0),
    const GridPosition(row: anchorRow + 1, column: 9),
    const GridPosition(row: 0, column: anchorColumn),
    const GridPosition(row: 9, column: anchorColumn + 1),
  };
  return extraGaps.contains(GridPosition(row: row, column: column));
}

List<_TutorialStep> _buildSteps() {
  final horizontalTriomino = PieceShapeCatalog.all.firstWhere(
    (shape) => shape.id == PieceShapeId.triominoLineHorizontal,
  );
  final square = PieceShapeCatalog.all.firstWhere(
    (shape) => shape.id == PieceShapeId.square,
  );
  final single = PieceShapeCatalog.all.firstWhere(
    (shape) => shape.id == PieceShapeId.single,
  );

  // Step 1 — a single row clear. Row 5 is filled everywhere except columns
  // 3-5; the rest of the board is empty, so nothing else is anywhere near
  // complete and this placement clears exactly that one row.
  const step1Anchor = GridPosition(row: 5, column: 3);
  final step1Filled = <GridPosition>{
    for (var column = 0; column < _boardSize; column++)
      if (column < 3 || column > 5) GridPosition(row: 5, column: column),
  };

  // Step 2 — just a bigger piece, no line clear (the GDD doesn't ask for
  // one here — combos are step 3's reveal). User feedback on an earlier
  // version of this step ("diğer bloklar yok" — a scattering of decorative
  // cells elsewhere, but the board was still almost entirely empty) asked
  // for the same structural puzzle language steps 1 and 3 already use: the
  // board itself should make the 2x2 anchor the *only* spot the square can
  // go, not just a mostly-empty board with a hint pointing somewhere.
  //
  // So the board here is filled everywhere *except*: the anchor's own 2x2
  // (obviously), plus exactly one extra single-cell gap in each of the
  // anchor's two rows and two columns — (4,0), (5,9), (0,4), (9,5). Without
  // those four extra gaps, placing the square would complete rows 4 *and*
  // 5 *and* columns 4 *and* 5 all at once (a quadruple clear this step
  // deliberately isn't supposed to have — that combo moment is step 3's).
  // Each gap is a single isolated cell (every neighbor around it is
  // filled), so none of them combine into a second empty 2x2 the square
  // could also fit into — the anchor really is the only valid placement.
  const step2Anchor = GridPosition(row: 4, column: 4);
  final step2Filled = <GridPosition>{
    for (var row = 0; row < _boardSize; row++)
      for (var column = 0; column < _boardSize; column++)
        if (!_isStep2Gap(row, column)) GridPosition(row: row, column: column),
  };

  // Step 3 — row 5 and column 5 are both filled everywhere except their
  // shared cell (5,5): placing the single block there completes both at
  // once, the first combo moment. Everything off that row/column stays
  // empty.
  const step3Anchor = GridPosition(row: 5, column: 5);
  final step3Filled = <GridPosition>{
    for (var column = 0; column < _boardSize; column++)
      if (column != 5) GridPosition(row: 5, column: column),
    for (var row = 0; row < _boardSize; row++)
      if (row != 5) GridPosition(row: row, column: 5),
  };

  return [
    _TutorialStep(
      board: _boardWithFilled(step1Filled),
      shape: horizontalTriomino,
      anchor: step1Anchor,
    ),
    _TutorialStep(
      board: _boardWithFilled(step2Filled),
      shape: square,
      anchor: step2Anchor,
    ),
    _TutorialStep(
      board: _boardWithFilled(step3Filled),
      shape: single,
      anchor: step3Anchor,
    ),
  ];
}

/// The first-launch interactive onboarding (user instruction) — three short,
/// fully player-driven steps teaching drag-to-place, a bigger piece, and a
/// multi-line combo, each gated so the player must actually perform the
/// correct move before moving on. No video, no auto-play: every step reuses
/// the exact same `BoardGrid`/`PieceTray` widgets (and their real Game Feel
/// sound/haptic/particle wiring) the actual game uses, just fed a hand-built
/// board/tray instead of `GameEngine`'s randomized ones — the tutorial has
/// no score and no mode strategy, so a small local controller is enough
/// rather than standing up a whole `GameEngine` for it.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  static const PlacementValidator _validator = DefaultPlacementValidator();
  static const LineClearResolver _lineClearResolver =
      DefaultLineClearResolver();

  late final List<_TutorialStep> _steps;
  late int _stepIndex;
  late Board _board;
  late List<TrayPiece> _tray;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    _stepIndex = 0;
    _loadStep(0);
  }

  void _loadStep(int index) {
    final step = _steps[index];
    _board = step.board;
    _tray = [TrayPiece(shape: step.shape)];
  }

  void _onPlace(int trayIndex, GridPosition anchor) {
    final piece = _tray[trayIndex];
    final orchestrator = ref.read(feedbackOrchestratorProvider);

    // Beyond ordinary validity, a drop only "counts" at this step's one
    // intended anchor — the boards are mostly empty (see `_buildSteps`),
    // so plenty of other spots would technically fit the piece too, but
    // only the guided one teaches the mechanic this step is about.
    if (piece.isUsed ||
        anchor != _steps[_stepIndex].anchor ||
        !_validator.canPlace(
          board: _board,
          shape: piece.shape,
          anchor: anchor,
        )) {
      orchestrator.play(const GameEvent.invalidMove());
      return;
    }

    var board = _board.place(piece.shape, anchor);
    orchestrator.play(
      GameEvent.piecePlaced(placementPoints: piece.shape.cellCount),
    );

    final cleared = _lineClearResolver.findCompletedLines(board);
    if (!cleared.isEmpty) {
      board = _lineClearResolver.clearLines(board, cleared);
      orchestrator.play(
        GameEvent.linesCleared(
          rows: cleared.rows,
          columns: cleared.columns,
          linePoints: 0,
        ),
      );
    }

    setState(() {
      _board = board;
      _tray = [piece.copyWith(isUsed: true)];
    });

    unawaited(_advanceAfterDelay());
  }

  Future<void> _advanceAfterDelay() async {
    // Long enough for the placement + line-clear Game Feel sequences to
    // actually finish playing before the board resets under them.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (_stepIndex == _steps.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _stepIndex++;
      _loadStep(_stepIndex);
    });
  }

  void _finish() {
    // Bug fix (found while investigating the user's reported "short wait
    // before returning to the main menu"): this used to fire three
    // `confettiBurst` effects through `_newtonKey`, but no `Newton` widget
    // in this screen's tree was ever built with that key — the calls were
    // silent no-ops, so the old 1400ms wait held the player on a
    // completely static, unchanging screen with nothing actually happening
    // for over a second. Rather than wire up a real `Newton` overlay (the
    // exact per-frame particle-system cost `enableParticles: false` above
    // was just added to strip *out* of this screen for stability), the
    // dead effect is removed outright and the hold is cut to a brief,
    // deliberate beat — just long enough to register "done" — before
    // returning to the menu.
    setState(() => _finished = true);
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      unawaited(
        ref.read(playerProgressControllerProvider.notifier).completeTutorial(),
      );
      widget.onFinished();
    });
  }

  void _skip() {
    unawaited(
      ref.read(playerProgressControllerProvider.notifier).completeTutorial(),
    );
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = _steps[_stepIndex];

    return Scaffold(
      body: ImageBackground(
        assetPath: 'assets/images/game_background.png',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ScreenShake(
              controller: ref.watch(screenShakeControllerProvider),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [GamePalette.bezelLight, GamePalette.bezelDark],
                  ),
                  border: Border.all(color: GamePalette.panelDark, width: 4),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                            _steps.length,
                            (i) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i <= _stepIndex
                                      ? GamePalette.recordGold
                                      : Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _skip,
                          child: Text(
                            l10n.tutorialSkip,
                            style: const TextStyle(color: AppColors.paper),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boardSide = math.min(
                            constraints.maxWidth,
                            constraints.maxHeight * 0.74,
                          );
                          final cellSize = boardSide / _board.size;

                          const gap = 12.0;
                          final trayHeight = cellSize * 2.2;

                          return Center(
                            child: SizedBox(
                              width: boardSide,
                              height: boardSide + gap + trayHeight,
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: boardSide,
                                        height: boardSide,
                                        // Bug fix: without a step-scoped
                                        // key, `BoardGrid`'s State (and its
                                        // `_initiallyFilled` snapshot,
                                        // computed once in `initState`)
                                        // survives across step
                                        // transitions. Step 3's board alone
                                        // starts with 18 pre-filled cells
                                        // (the row+column cross) that step
                                        // 2's board never had —
                                        // `_initiallyFilled` stale from
                                        // step 1 wouldn't recognize any of
                                        // them, so the empty→filled diff
                                        // would fire 18 simultaneous
                                        // "Block Place" pop-in sequences
                                        // (54 AnimationControllers) the
                                        // instant step 3 loads, worse than
                                        // the original pre-filled-cell
                                        // crash this same mechanism was
                                        // built to prevent. A fresh key
                                        // per step forces a genuine
                                        // remount, so `_initiallyFilled`
                                        // is recomputed correctly for
                                        // whichever board just appeared.
                                        child: BoardGrid(
                                          key: ValueKey(_stepIndex),
                                          board: _board,
                                          tray: _tray,
                                          onPlace: _onPlace,
                                          enableParticles: false,
                                        ),
                                      ),
                                      const SizedBox(height: gap),
                                      SizedBox(
                                        width: boardSide,
                                        height: trayHeight,
                                        child: PieceTray(
                                          tray: _tray,
                                          dragCellSize: cellSize,
                                          board: _board,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Spans board + tray so it can animate
                                  // from "pick up the piece" to "drop it
                                  // here" — see `_GuideHand`'s doc comment.
                                  if (!_finished)
                                    _GuideHand(
                                      key: ValueKey(_stepIndex),
                                      anchor: step.anchor,
                                      shape: step.shape,
                                      cellSize: cellSize,
                                      boardSide: boardSide,
                                      trayCenterY: boardSide + gap +
                                          trayHeight / 2,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The guide hand demonstrates the whole gesture on a loop rather than just
/// pointing at a fixed spot (user instruction: it should first point at the
/// piece down in the tray, then — once it would have "picked it up" —
/// glide up onto the board to show exactly where to drop it). It never
/// touches the actual piece or board state; it is purely a hint overlay a
/// real drag can happen underneath at any time.
///
/// One continuous, looping timeline instead of two separate widgets:
///   0%-28%   — resting over the tray piece, a soft press-and-release pulse
///              (the "pick this up" beat).
///   28%-52%  — glides from the piece up to the target cell (eased, with a
///              slight arc rather than a straight linear cut).
///   52%-88%  — resting over the target cell, the same press pulse (the
///              "drop it here" beat).
///   88%-100% — fades out and jumps back to the tray to restart invisibly,
///              so the loop never shows a visible teleport.
///
/// The hand itself is a custom-shaded shape rather than a flat icon glyph —
/// a radial highlight plus a darker rim gives it a rounded, lit-from-above
/// look approximating real depth without a bitmap asset (no 3D-rendered
/// hand asset was supplied; if one becomes available later, swapping this
/// `Icon` for an `Image.asset` in `_HandGlyph` is a self-contained change).
class _GuideHand extends StatefulWidget {
  const _GuideHand({
    required this.anchor,
    required this.shape,
    required this.cellSize,
    required this.boardSide,
    required this.trayCenterY,
    super.key,
  });

  final GridPosition anchor;
  final PieceShape shape;
  final double cellSize;
  final double boardSide;
  final double trayCenterY;

  @override
  State<_GuideHand> createState() => _GuideHandState();
}

class _GuideHandState extends State<_GuideHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.shape.cells.map((c) => c.row).toList();
    final columns = widget.shape.cells.map((c) => c.column).toList();
    final targetCenter = Offset(
      (widget.anchor.column +
              (columns.reduce(math.min) + columns.reduce(math.max)) / 2 +
              0.5) *
          widget.cellSize,
      (widget.anchor.row +
              (rows.reduce(math.min) + rows.reduce(math.max)) / 2 +
              0.5) *
          widget.cellSize,
    );
    // Only one piece ever sits in the tutorial's tray, always in its one
    // slot's horizontal center.
    final pieceCenter = Offset(widget.boardSide / 2, widget.trayCenterY);
    final handSize = widget.cellSize * 1.7;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        const glideStart = 0.28;
        const glideEnd = 0.52;
        const fadeStart = 0.88;

        late final Offset position;
        late final double pulse;
        late final double opacity;

        if (t < glideStart) {
          position = pieceCenter;
          pulse = _pulseAt(t / glideStart);
          opacity = 1;
        } else if (t < glideEnd) {
          final glideT = Curves.easeInOutCubic
              .transform((t - glideStart) / (glideEnd - glideStart));
          // A slight upward arc (rather than a straight line) reads more
          // like a hand physically lifting and carrying the piece.
          final arc = math.sin(glideT * math.pi) * widget.cellSize * 0.6;
          position =
              Offset.lerp(pieceCenter, targetCenter, glideT)! -
              Offset(0, arc);
          pulse = 0;
          opacity = 1;
        } else if (t < fadeStart) {
          position = targetCenter;
          pulse = _pulseAt((t - glideEnd) / (fadeStart - glideEnd));
          opacity = 1;
        } else {
          position = targetCenter;
          pulse = 0;
          opacity = 1 - (t - fadeStart) / (1 - fadeStart);
        }

        return Positioned(
          left: position.dx - handSize / 2,
          top: position.dy - handSize * 0.32,
          width: handSize,
          height: handSize,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 1 - pulse * 0.12,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        );
      },
      child: _HandGlyph(size: handSize),
    );
  }

  /// A quick press-and-release bump — sharp down, gentle back up — repeated
  /// twice within the given local `t` (0-1) window, reading as two soft
  /// taps rather than one long breathing cycle.
  double _pulseAt(double t) {
    final cycle = (t * 2) % 1;
    return cycle < 0.35 ? cycle / 0.35 : 1 - (cycle - 0.35) / 0.65;
  }
}

/// A rounded, top-lit pointing hand built from layered shading instead of a
/// single flat glyph fill — a soft ground shadow, a warm gradient across the
/// glyph itself, and a bright rim highlight along its upper edge, so it
/// reads with some volume rather than a paper cutout.
class _HandGlyph extends StatelessWidget {
  const _HandGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft contact shadow grounding the hand, like it's pressing down
          // onto the surface below it.
          Positioned(
            bottom: size * 0.08,
            child: Container(
              width: size * 0.42,
              height: size * 0.14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF3C4),
                GamePalette.recordGold,
                Color(0xFF8A5A12),
              ],
              stops: [0, 0.55, 1],
            ).createShader(bounds),
            child: Icon(
              PhosphorIconsFill.handPointing,
              color: Colors.white,
              size: size,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
