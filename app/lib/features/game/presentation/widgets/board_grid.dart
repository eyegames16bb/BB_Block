import 'dart:math' as math;

import 'package:bb_block/core/game_feel/drag_feel_controller.dart';
import 'package:bb_block/core/providers/game_feel_providers.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/board/domain/services/line_clear_resolver.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_view.dart';
import 'package:bb_block/features/game/presentation/widgets/place_sequence.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_dust_effect.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newton_particles/newton_particles.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// The 10×10 play surface. Renders the current [board], accepts pieces dragged
/// from the tray (identified by their tray index), shows a live ghost preview
/// of where the piece would land, and calls [onPlace] on a valid drop.
///
/// When [removalArmed] is true (the Single Cell Remove booster is active),
/// dragging is bypassed and tapping any filled cell calls [onCellTap]
/// instead — frame cells are never tappable, matching the engine's own
/// refusal to remove them.
///
/// [starTargetRow]/[starTargetColumn] (Level Mode only, user instruction) —
/// at most one is non-null — mark the two opposite frame points a star icon
/// renders on: `(starTargetRow, 0)` and `(starTargetRow, size-1)` for a row
/// target, or the equivalent top/bottom pair for a column target. Purely a
/// visual marker; the actual bonus is awarded by `GameEngine` regardless of
/// whether this widget ever renders it. The bonus is one-time per round: the
/// moment `GameEngine` earns it, both fields go back to `null`, and this
/// widget reacts to exactly that transition by animating the two star icons
/// breaking away (the frame itself is never touched by that animation).
class BoardGrid extends ConsumerStatefulWidget {
  const BoardGrid({
    required this.board,
    required this.tray,
    required this.onPlace,
    this.removalArmed = false,
    this.onCellTap,
    this.starTargetRow,
    this.starTargetColumn,
    this.enableParticles = true,
    super.key,
  });

  final Board board;
  final List<TrayPiece> tray;
  final void Function(int trayIndex, GridPosition anchor) onPlace;
  final bool removalArmed;
  final void Function(GridPosition position)? onCellTap;
  final int? starTargetRow;
  final int? starTargetColumn;

  /// Whether dust/sparkle bursts render at all (default on, for the real
  /// game). The tutorial (user report: freezes/stutters specifically during
  /// its step transitions) passes `false` — its board remounts on a fresh
  /// `ValueKey` every step (see `TutorialScreen`'s own doc comment on why),
  /// and `Newton`'s own always-running `Ticker` plus a brand-new particle
  /// system spinning up in the very same frame as that remount was already
  /// flagged (CLAUDE.md) as a plausible contributor to real, observed jank/
  /// crashes in this exact screen — the tutorial's hand-placed steps don't
  /// need the extra flourish the real game's `Newton` overlay adds, so
  /// skipping it here removes that whole subsystem from the transition
  /// entirely rather than trying to tune it. Every call site that fires an
  /// effect already goes through `_newtonKey.currentState?.addEffect(...)`,
  /// so when this is `false` (and no `Newton` is ever mounted) those calls
  /// simply no-op instead of needing a separate guard.
  final bool enableParticles;

  @override
  ConsumerState<BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends ConsumerState<BoardGrid> {
  static const PlacementValidator _validator = DefaultPlacementValidator();
  static const LineClearResolver _lineClearResolver =
      DefaultLineClearResolver();
  static const Duration _clearBreakDuration = Duration(milliseconds: 480);
  static const Duration _frameBreakDuration = Duration(milliseconds: 650);

  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey<NewtonState> _newtonKey = GlobalKey<NewtonState>();
  OverlayEntry? _reachOverlayEntry;
  _Preview? _preview;

  // "Block Drag Animation" tilt (user instruction) — a small lean derived
  // from how far the drag moved horizontally between consecutive `onMove`
  // events, not true velocity (no extra timing plumbing needed for
  // something this subtle). `null` between drags so the very first move
  // of a new drag never reads a stale delta from the previous one.
  Offset? _lastDragLocalOffset;

  // "Invalid Placement" bounce (user instruction) — a short shake-and-fade
  // played exactly where a rejected drop landed, layered on top of (never
  // replacing) the engine's own `GameEvent.invalidMove` feedback. Purely
  // visual/local: `widget.onPlace` is still always called for every drop,
  // valid or not (see `_commitPreview`'s doc comment) — the engine remains
  // the single source of truth for whether the move actually happened.
  _RejectBounce? _rejectBounce;
  int _rejectBounceGeneration = 0;

  // Bumped for a position exactly when it transitions to filled, so the
  // TweenAnimationBuilder keyed on it below plays its pop-in once per
  // placement and then holds steady — never replaying on unrelated rebuilds.
  final Map<GridPosition, int> _fillGeneration = {};

  // Cells mid line-clear: the board already reports them empty, but we keep
  // rendering their wood tile here — fading and bursting outward — for one
  // more animation cycle instead of having them vanish instantly.
  final Set<GridPosition> _clearingCells = {};
  final Map<GridPosition, int> _clearGeneration = {};

  // Positions already `CellState.filled` the very first time this widget
  // built — normal gameplay boards (`Board.empty()`/`Board.framed()`) never
  // start with filled cells, only the tutorial's hand-built ones do (see
  // `tutorial_screen.dart`). `didUpdateWidget` only bumps `_fillGeneration`
  // on a genuine empty→filled *transition*, so without this a pre-filled
  // cell would still hit the `CellState.filled` branch below and play the
  // full "Block Place" pop-in — physically real gameplay never produces
  // more than one or two of those at once, but the tutorial's boards can
  // start with half a dozen, and mounting that many simultaneous spring
  // simulations turned out to be enough concurrent animation load to crash
  // a software-rendered (SwiftShader) emulator outright. These cells should
  // just already be there, not "just placed".
  late final Set<GridPosition> _initiallyFilled;

  @override
  void initState() {
    super.initState();
    _initiallyFilled = {
      for (var row = 0; row < widget.board.size; row++)
        for (var column = 0; column < widget.board.size; column++)
          if (widget.board.cellAt(GridPosition(row: row, column: column)) ==
              CellState.filled)
            GridPosition(row: row, column: column),
    };
    // Deferred one frame so `_gridKey`'s box is actually laid out before we
    // read its position — see `_insertReachOverlay`'s doc comment for why
    // this needs a real `Overlay` entry rather than a `Positioned` widget
    // nested inside this widget's own tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertReachOverlay());
  }

  @override
  void dispose() {
    _reachOverlayEntry?.remove();
    _reachOverlayEntry = null;
    super.dispose();
  }

  /// A real Flutter `Overlay` entry (the same mechanism `Draggable`'s own
  /// dragged feedback uses to render/hit-test anywhere on screen,
  /// regardless of its origin widget's box) hosting the invisible
  /// extra-reach `DragTarget` below the board.
  ///
  /// A `Positioned` widget nested inside this widget's *own* `Stack` was
  /// tried first (with `clipBehavior: Clip.none` to let it visually
  /// overflow) and turned out not to work at all once
  /// `GamePalette.dragLiftCellMultiplier` grew past `1` (user instruction —
  /// a much bigger, clearly visible gap between the finger and the piece):
  /// a `Positioned` child's *painting* can overflow its `Stack`'s own
  /// bounds, but `RenderBox.hitTest` still gates on `_size.contains
  /// (position)` for every ordinary ancestor first — including this
  /// widget's own allotted box from `GameScreen`/`TutorialScreen` (a plain
  /// `SizedBox(width: boardSide, height: boardSide, ...)`) — so a touch
  /// below that box was rejected before the overflowing strip was ever
  /// reached, no matter how tall the strip itself claimed to be. This only
  /// went unnoticed at the old, sub-1-cell lift because reaching the last
  /// row never actually required going past that box in the first place.
  /// An `Overlay` entry is inserted directly into the app's root overlay
  /// stack instead, sized to reach all the way to the bottom of the
  /// screen — genuinely reachable regardless of this widget's own box.
  void _insertReachOverlay() {
    if (!mounted) return;
    _reachOverlayEntry?.remove();
    _reachOverlayEntry = OverlayEntry(
      builder: (context) {
        final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) return const SizedBox.shrink();
        final topLeft = box.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.sizeOf(context).height;
        final top = topLeft.dy + box.size.height;
        return Positioned(
          left: topLeft.dx,
          top: top,
          width: box.size.width,
          height: (screenHeight - top).clamp(0.0, double.infinity),
          child: DragTarget<int>(
            onMove: _onDragMove,
            onLeave: (_) => _onDragLeave(),
            onAcceptWithDetails: (_) => _commitPreview(),
            builder: (context, _, _) => const SizedBox.expand(),
          ),
        );
      },
    );
    Overlay.of(context).insert(_reachOverlayEntry!);
  }

  // Same idea for the one-time Level Mode frame teardown (decision #4 in
  // CLAUDE.md: a distinct effect from ordinary line clears, not the same
  // animation) — bigger, slower, and staggered into an outward wave instead
  // of every border cell fading uniformly at once.
  final Set<GridPosition> _frameClearingCells = {};
  final Map<GridPosition, int> _frameClearGeneration = {};

  // The star bonus is one-time per round now (user instruction): the
  // instant `GameEngine` awards it, `starTargetRow`/`starTargetColumn` go
  // back to `null`. This mirrors that same transition to animate the two
  // star icons breaking away — reusing `_clearingOverlay`'s fall/rotate/
  // fade curve — while the frame cells underneath stay completely
  // untouched (this is a *separate* overlay layered on top of them, not a
  // replacement).
  final Set<GridPosition> _starClearingCells = {};
  final Map<GridPosition, int> _starClearGeneration = {};

  Set<GridPosition> _starPointsFor(int? row, int? column) {
    if (row != null) {
      return {
        GridPosition(row: row, column: 0),
        GridPosition(row: row, column: widget.board.size - 1),
      };
    }
    if (column != null) {
      return {
        GridPosition(row: 0, column: column),
        GridPosition(row: widget.board.size - 1, column: column),
      };
    }
    return const {};
  }

  @override
  void didUpdateWidget(covariant BoardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldStarPoints = _starPointsFor(
      oldWidget.starTargetRow,
      oldWidget.starTargetColumn,
    );
    if (oldStarPoints.isNotEmpty &&
        widget.starTargetRow == null &&
        widget.starTargetColumn == null) {
      for (final position in oldStarPoints) {
        _starClearingCells.add(position);
        _starClearGeneration[position] =
            (_starClearGeneration[position] ?? 0) + 1;
      }
    }

    if (oldWidget.board == widget.board) return;

    for (var row = 0; row < widget.board.size; row++) {
      for (var column = 0; column < widget.board.size; column++) {
        final position = GridPosition(row: row, column: column);
        final oldState = oldWidget.board.cellAt(position);
        final newState = widget.board.cellAt(position);

        if (oldState != CellState.filled && newState == CellState.filled) {
          _fillGeneration[position] = (_fillGeneration[position] ?? 0) + 1;
        }
        if (oldState == CellState.filled && newState != CellState.filled) {
          _clearingCells.add(position);
          _clearGeneration[position] = (_clearGeneration[position] ?? 0) + 1;
          _burstDustAt(position);
        }
        if (oldState == CellState.frame && newState != CellState.frame) {
          _frameClearingCells.add(position);
          _frameClearGeneration[position] =
              (_frameClearGeneration[position] ?? 0) + 1;
          _burstDustAt(position, isFrame: true);
        }
      }
    }
  }

  /// The "Block Place" Game Feel sequence's final beat — see
  /// `place_sequence.dart`'s doc comment for the full chain. Fired by
  /// `PlaceSequence` itself once its hit-freeze hold ends, not from the
  /// board diff directly, so the sparks land exactly on that beat instead
  /// of at the instant the cell became filled.
  void _burstSparkleAt(GridPosition position) {
    _newtonKey.currentState?.addEffect(
      placementSparkle(
        origin: Offset(
          (position.column + 0.5) / widget.board.size,
          (position.row + 0.5) / widget.board.size,
        ),
      ),
    );
  }

  /// Fires a small wood-chip particle burst at [position] via the `Newton`
  /// overlay, on top of the existing scale/opacity overlay animation — see
  /// CLAUDE.md decision #4. Frame cells stagger their burst by the same
  /// distance-from-corner delay the visual teardown wave already uses
  /// (`_frameClearingOverlay`), so the dust and the shattering tiles read as
  /// one coordinated event instead of two out-of-sync effects.
  void _burstDustAt(GridPosition position, {bool isFrame = false}) {
    final origin = Offset(
      (position.column + 0.5) / widget.board.size,
      (position.row + 0.5) / widget.board.size,
    );
    final colors = isFrame
        ? const [
            GamePalette.frameBlock,
            GamePalette.frameBlockEdge,
            AppColors.woodDeep,
          ]
        : const [
            GamePalette.placedBlockGradientStart,
            GamePalette.placedBlockEdge,
            AppColors.woodDeep,
          ];

    void fire() => _newtonKey.currentState?.addEffect(
      woodDustBurst(
        origin: origin,
        colors: colors,
        particleCount: isFrame ? 5 : 7,
      ),
    );

    if (!isFrame) {
      fire();
      return;
    }
    final delayFraction =
        ((position.row + position.column) / (2 * widget.board.size)).clamp(
          0.0,
          0.5,
        );
    Future.delayed(_frameBreakDuration * delayFraction, () {
      if (mounted) fire();
    });
  }

  @override
  Widget build(BuildContext context) {
    // `.grid-container` from the reference mockup — sits directly on the
    // surrounding game-container panel's own gradient (see GameScreen's
    // outer card), not inside a separate light-wood bezel layer of its own.
    // The invisible extra-reach `DragTarget` (for the drag lift's bottom-row
    // reachability — see `_insertReachOverlay`'s doc comment) lives in a
    // real `Overlay` entry now, not nested here, so this only needs to
    // render the board itself.
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GamePalette.boardBackground,
          border: Border.all(
            color: GamePalette.gridBorder,
            width: 4,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DragTarget<int>(
            onMove: _onDragMove,
            onLeave: (_) => _onDragLeave(),
            onAcceptWithDetails: (_) => _commitPreview(),
            builder: (context, _, _) => LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = constraints.maxWidth / widget.board.size;
                final grid = Container(
                  key: _gridKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var row = 0; row < widget.board.size; row++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var col = 0; col < widget.board.size; col++)
                              _cell(
                                GridPosition(row: row, column: col),
                                cellSize,
                              ),
                          ],
                        ),
                    ],
                  ),
                );
                final content = widget.enableParticles
                    ? Newton(key: _newtonKey, child: grid)
                    : grid;

                // "Invalid Placement" bounce (user instruction) — spans
                // multiple cells at an arbitrary anchor, so unlike every
                // other transient overlay here (which lives inside a single
                // cell's own `Stack`) this needs a board-wide `Stack` to
                // position itself freely over the grid.
                if (_rejectBounce case final bounce?) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      content,
                      _rejectBounceOverlay(bounce, cellSize),
                    ],
                  );
                }
                return content;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(GridPosition position, double cellSize) {
    final state = widget.board.cellAt(position);
    final previewColor = _previewColorFor(position);
    final wouldClearColor = _wouldClearColorFor(position);
    final removable = widget.removalArmed && state == CellState.filled;

    // Performance (user instruction): a `RepaintBoundary` per cell means an
    // animating cell (a fill pop-in, a line-clear break, the preview ghost
    // changing color) repaints only its own small layer instead of forcing
    // the *whole* 100-cell grid through another paint pass on every frame
    // of that one animation. `RepaintBoundary` never clips — it's purely a
    // compositing boundary — so it doesn't interfere with the break/fall
    // overlays translating past this cell's own bounds below.
    return RepaintBoundary(
      child: GestureDetector(
        onTap: removable ? () => widget.onCellTap?.call(position) : null,
        child: SizedBox(
          width: cellSize,
          height: cellSize,
          child: Stack(
            fit: StackFit.expand,
            // The break/fall overlays translate well past this cell's own
            // bounds (see _clearingOverlay/_frameClearingOverlay) —
            // clipping here would just hide the fall after a few pixels.
            clipBehavior: Clip.none,
            children: [
              _baseCell(position, state, cellSize),
              if (_clearingCells.contains(position))
                _clearingOverlay(position, cellSize),
              if (_frameClearingCells.contains(position))
                _frameClearingOverlay(position, cellSize),
              if (previewColor != null)
                Padding(
                  padding: EdgeInsets.all(cellSize * 0.05),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: previewColor,
                      borderRadius: BorderRadius.circular(cellSize * 0.16),
                    ),
                  ),
                ),
              // Drawn on top of the ordinary green/red ghost tint — a line
              // this exact drop would complete reads as bold yellow across
              // its *whole* row/column, not just the piece's own cells.
              if (wouldClearColor != null)
                Padding(
                  padding: EdgeInsets.all(cellSize * 0.05),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: wouldClearColor,
                      borderRadius: BorderRadius.circular(cellSize * 0.16),
                    ),
                  ),
                ),
              if (removable)
                Padding(
                  padding: EdgeInsets.all(cellSize * 0.05),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: GamePalette.previewInvalid,
                      borderRadius: BorderRadius.circular(cellSize * 0.16),
                    ),
                  ),
                ),
              // The static icon shows only while NOT mid-breakaway — once
              // consumed, `_starClearingOverlay` below takes over rendering
              // the (animating, then vanishing) star instead.
              if (_isStarPoint(position) &&
                  !_starClearingCells.contains(position))
                Center(
                  child: Icon(
                    PhosphorIconsFill.star,
                    color: GamePalette.recordGold,
                    size: cellSize * 0.6,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 3),
                    ],
                  ),
                ),
              if (_starClearingCells.contains(position))
                _starClearingOverlay(position, cellSize),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether [position] is one of the round's two star frame points (user
  /// instruction) — the pair of opposite border cells at the ends of
  /// [BoardGrid.starTargetRow]/[BoardGrid.starTargetColumn]. Stays true
  /// (the star keeps showing) even after the frame is torn down at the
  /// 750-point threshold — the star marks a *line*, not the frame cells
  /// themselves. Once the bonus is earned (one-time — see `GameEngine`),
  /// `starTargetRow`/`starTargetColumn` both go back to `null`, so this
  /// stops matching either point — `_starClearingOverlay` is what animates
  /// that specific transition instead of the icons just vanishing outright.
  bool _isStarPoint(GridPosition position) {
    final row = widget.starTargetRow;
    if (row != null) {
      return position.row == row &&
          (position.column == 0 || position.column == widget.board.size - 1);
    }
    final column = widget.starTargetColumn;
    if (column != null) {
      return position.column == column &&
          (position.row == 0 || position.row == widget.board.size - 1);
    }
    return false;
  }

  Widget _baseCell(GridPosition position, CellState state, double cellSize) {
    switch (state) {
      case CellState.filled:
        // Already filled when this board first appeared (never went
        // through a real placement transition) — show it plainly, skip
        // the pop-in. See `_initiallyFilled`'s doc comment.
        if (_initiallyFilled.contains(position) &&
            _fillGeneration[position] == null) {
          return WoodTile(size: cellSize);
        }
        return PlaceSequence(
          key: ValueKey('fill-$position-${_fillGeneration[position] ?? 0}'),
          cellSize: cellSize,
          onSparkle: () => _burstSparkleAt(position),
        );
      case CellState.frame:
        return WoodTile(size: cellSize, isFrame: true);
      case CellState.empty:
        return Padding(
          padding: EdgeInsets.all(cellSize * 0.05),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GamePalette.emptySlot,
              borderRadius: BorderRadius.circular(cellSize * 0.16),
            ),
          ),
        );
    }
  }

  /// Renders a wood tile that cracks and tumbles downward off the board for
  /// a cell that was just cleared, then removes itself from [_clearingCells]
  /// once the animation finishes so the (already-empty) base cell shows
  /// through permanently. Horizontal drift and rotation are derived from
  /// the cell's own position (not `Random`) so the same cell always falls
  /// the same way on replay, and no state needs to be cached per-cell.
  Widget _clearingOverlay(GridPosition position, double cellSize) {
    final drift = _fallDrift(position);
    final spin = _fallSpin(position);

    return TweenAnimationBuilder<double>(
      key: ValueKey('clear-$position-${_clearGeneration[position] ?? 0}'),
      tween: Tween(begin: 0, end: 1),
      duration: _clearBreakDuration,
      curve: Curves.easeIn,
      onEnd: () {
        if (mounted) setState(() => _clearingCells.remove(position));
      },
      builder: (context, t, child) => Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: (1 - t * 1.2).clamp(0.0, 1.0),
            child: Transform.translate(
              // A quadratic fall (t*t) reads as gravity picking up speed,
              // rather than a constant-speed drift.
              offset: Offset(
                drift * cellSize * 0.4 * t,
                cellSize * 2.2 * t * t,
              ),
              child: Transform.rotate(
                angle: spin * t,
                child: Transform.scale(scale: 1 - t * 0.3, child: child),
              ),
            ),
          ),
          // The completing row/column's bold-yellow flash (user
          // instruction) — front-loaded into the break's first ~40% so it
          // reads as an instant "this line just cleared!" pulse rather than
          // a lingering tint riding along with the fall.
          IgnorePointer(
            child: Opacity(
              opacity: (1 - t * 2.5).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GamePalette.lineClearHighlight.withValues(
                    alpha: 0.75,
                  ),
                  borderRadius: BorderRadius.circular(cellSize * 0.16),
                ),
              ),
            ),
          ),
        ],
      ),
      child: WoodTile(size: cellSize),
    );
  }

  /// The Level Mode 750-point frame teardown. Deliberately bigger, slower,
  /// falls farther, and is staggered (via an [Interval] keyed to distance
  /// from the top-left corner) into an outward wave, so the whole border
  /// shattering reads as a distinct, larger event than an ordinary line
  /// break rather than the same animation.
  Widget _frameClearingOverlay(GridPosition position, double cellSize) {
    final delayFraction =
        ((position.row + position.column) / (2 * widget.board.size)).clamp(
          0.0,
          0.5,
        );
    final drift = _fallDrift(position);
    final spin = _fallSpin(position);

    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'frame-clear-$position-${_frameClearGeneration[position] ?? 0}',
      ),
      tween: Tween(begin: 0, end: 1),
      duration: _frameBreakDuration,
      curve: Interval(delayFraction, 1, curve: Curves.easeIn),
      onEnd: () {
        if (mounted) setState(() => _frameClearingCells.remove(position));
      },
      builder: (context, t, child) => Opacity(
        opacity: (1 - t * 1.15).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(drift * cellSize * 0.6 * t, cellSize * 3.2 * t * t),
          child: Transform.rotate(
            angle: spin * 1.4 * t,
            child: Transform.scale(scale: 1 - t * 0.35, child: child),
          ),
        ),
      ),
      child: WoodTile(size: cellSize, isFrame: true),
    );
  }

  /// The one-time star bonus's icon breaking away (user instruction,
  /// revised) — reuses the ordinary line-clear's fall/rotate/fade curve
  /// (see `_clearingOverlay`) but animates only the star `Icon` itself,
  /// layered *on top of* whatever the base frame cell already renders —
  /// the frame tile underneath is never touched by this overlay.
  Widget _starClearingOverlay(GridPosition position, double cellSize) {
    final drift = _fallDrift(position);
    final spin = _fallSpin(position);

    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'star-clear-$position-${_starClearGeneration[position] ?? 0}',
      ),
      tween: Tween(begin: 0, end: 1),
      duration: _clearBreakDuration,
      curve: Curves.easeIn,
      onEnd: () {
        if (mounted) setState(() => _starClearingCells.remove(position));
      },
      builder: (context, t, child) => Opacity(
        opacity: (1 - t * 1.2).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(drift * cellSize * 0.4 * t, cellSize * 2.2 * t * t),
          child: Transform.rotate(
            angle: spin * t,
            child: Transform.scale(scale: 1 - t * 0.3, child: child),
          ),
        ),
      ),
      child: Center(
        child: Icon(
          PhosphorIconsFill.star,
          color: GamePalette.recordGold,
          size: cellSize * 0.6,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
        ),
      ),
    );
  }

  /// A deterministic pseudo-random horizontal drift multiplier in [-1, 1]
  /// for the given cell, so falling tiles scatter instead of dropping in
  /// a perfectly straight column.
  double _fallDrift(GridPosition position) =>
      ((position.row * 7 + position.column * 13) % 5 - 2) / 2;

  /// A deterministic pseudo-random rotation (radians) for the given cell.
  double _fallSpin(GridPosition position) =>
      ((position.row * 11 + position.column * 5) % 3 - 1) * 0.7;

  /// The bright-yellow "this placement completes a line" highlight (user
  /// instruction) wins over the ordinary green/red ghost tint for any cell
  /// that's part of a line the current preview would actually clear —
  /// including cells the piece itself doesn't occupy (the rest of that
  /// row/column), so the whole soon-to-clear line reads as one unit.
  Color? _wouldClearColorFor(GridPosition position) {
    final preview = _preview;
    if (preview == null || !preview.wouldClearCells.contains(position)) {
      return null;
    }
    return GamePalette.lineClearHighlight.withValues(alpha: 0.55);
  }

  Color? _previewColorFor(GridPosition position) {
    final preview = _preview;
    if (preview == null || !preview.cells.contains(position)) return null;
    return preview.isValid
        ? GamePalette.previewValid
        : GamePalette.previewInvalid;
  }

  /// The whole Drag Motion & Placement Pipeline, deliberately in this order
  /// (user instruction — "Drag Motion & Placement Pipeline Refactor"):
  ///
  ///   Touch → HN update → **Block Position Update** (owned entirely by
  ///   `Draggable`'s own `Overlay`, *never* by this method) → Render (the
  ///   ghost preview below) → Grid Detection / Placement Validation
  ///   (background — the result only ever feeds the preview's *color* and
  ///   [DragFeelController]'s tilt, never the piece's actual position) →
  ///   next frame.
  ///
  /// The critical invariant this method must never violate: nothing in
  /// here reaches back into where the dragged piece is actually drawn.
  /// `Draggable`'s feedback already tracks the raw pointer 1:1 through
  /// Flutter's own `Overlay`, completely independently of this widget —
  /// this method only ever *reads* the reported position to figure out
  /// what to highlight and whether a drop here would be legal. See
  /// `DragFeelController`'s doc comment for the concrete bug this
  /// separation fixes (a previous version of this pipeline briefly fed a
  /// "magnetic snap" pull back into the piece's rendered position, which
  /// is exactly what made the piece feel caught on the grid).
  void _onDragMove(DragTargetDetails<int> details) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    // `details.offset` is `Draggable`'s reported global position of the
    // feedback widget's top-left — which, per `PieceTray`'s
    // `dragAnchorStrategy`, is exactly the dragged shape's own top-left
    // cell corner in world space. That makes `local` below the Hidden
    // Anchor Point (HN)'s position translated back to the shape's top-left
    // for grid math — every placement calculation in this widget reads
    // *only* this value, never the raw pointer position directly (user
    // instruction: all grid math goes through HN). It is read-only here —
    // Grid Detection never writes back to it.
    final cellSize = box.size.width / widget.board.size;
    final local = box.globalToLocal(details.offset);
    final shape = widget.tray[details.data].shape;
    final anchor = _anchorFromLocal(local, cellSize, shape);
    if (anchor == null) {
      // Board vs. tray separation (user instruction): the dragged piece's
      // own rectangle no longer overlaps the board at all — this is not a
      // board hover anymore (the player is most likely dragging the piece
      // back toward the tray to cancel it), so any stale ghost preview from
      // the last position that *was* still over the board must be cleared
      // instead of lingering on screen (and, critically, `_commitPreview`
      // below reads this same `_preview` — leaving it stale here was the
      // root cause of a drop-over-the-tray still being clamped onto the
      // board's own last row and treated as a placement attempt).
      if (_preview != null) setState(() => _preview = null);
      return;
    }

    // "Block Drag Animation" tilt — cheap (one subtraction), independent of
    // the board entirely (pure pointer-delta physicality), so it's safe to
    // update every move event rather than only on a cell change.
    _updateDragTilt(local);

    final isValid = _validator.canPlace(
      board: widget.board,
      shape: shape,
      anchor: anchor,
    );

    // The finger moves far more often than it crosses into a new cell —
    // skipping the rebuild when the preview hasn't actually changed keeps
    // every real cell-to-cell move feeling instant instead of competing
    // for frame budget with a flood of no-op rebuilds (user instruction:
    // faster, more responsive drag feedback). This is Placement
    // Validation/Grid Detection's *only* effect: what the ghost preview
    // renders — it never touches the dragged piece's own position.
    final current = _preview;
    if (current != null &&
        current.trayIndex == details.data &&
        current.anchor == anchor) {
      return;
    }

    final cells = {
      for (final offset in shape.cells) anchor.offsetBy(offset),
    };

    // User instruction: while dragging, if the current spot is valid *and*
    // would complete one or more lines, highlight that whole line in bold
    // yellow before the player even lets go — a preview of the clear, not
    // just of the placement.
    var wouldClearCells = const <GridPosition>{};
    if (isValid) {
      final hypotheticalBoard = widget.board.place(shape, anchor);
      final cleared = _lineClearResolver.findCompletedLines(hypotheticalBoard);
      if (!cleared.isEmpty) {
        wouldClearCells = {
          for (final row in cleared.rows)
            for (var column = 0; column < widget.board.size; column++)
              GridPosition(row: row, column: column),
          for (final column in cleared.columns)
            for (var row = 0; row < widget.board.size; row++)
              GridPosition(row: row, column: column),
        };
      }
    }

    setState(() {
      _preview = _Preview(
        trayIndex: details.data,
        anchor: anchor,
        cells: cells,
        wouldClearCells: wouldClearCells,
        isValid: isValid,
      );
    });
  }

  /// Publishes this move's "Block Drag Animation" tilt to the shared
  /// [DragFeelController] (read by the tray's floating drag image) — a
  /// plain `ChangeNotifier` update, not a `setState` on this widget, so
  /// this runs every move event at effectively zero rebuild cost to the
  /// 100-cell grid (user instruction: no unnecessary rebuilds). Derived
  /// purely from the pointer's own horizontal delta between consecutive
  /// moves — no board/grid state feeds into it, so it can never make the
  /// piece feel tied to a cell.
  void _updateDragTilt(Offset local) {
    final lastLocal = _lastDragLocalOffset;
    _lastDragLocalOffset = local;
    final dx = lastLocal == null ? 0.0 : local.dx - lastLocal.dx;
    const tiltSensitivity = 0.0015;
    final tilt = (dx * tiltSensitivity).clamp(
      -DragFeelController.maxTiltRadians,
      DragFeelController.maxTiltRadians,
    );

    ref.read(dragFeelControllerProvider).update(tiltRadians: tilt);
  }

  /// Called whenever the drag leaves this `DragTarget`'s hit area (either
  /// board region — see the main one in `build` and the extra-reach one in
  /// `_insertReachOverlay`) — clears the ghost preview and resets the drag
  /// feel state so a stale tilt/pull doesn't linger while hovering
  /// somewhere the board isn't tracking.
  void _onDragLeave() {
    _lastDragLocalOffset = null;
    ref.read(dragFeelControllerProvider).reset();
    setState(() => _preview = null);
  }

  /// Maps the dragged piece's HN-derived top-left [local] position to a
  /// board anchor cell, clamped so the whole shape stays on the grid — or
  /// `null` if the piece isn't actually over the board at all (see below).
  GridPosition? _anchorFromLocal(
    Offset local,
    double cellSize,
    PieceShape shape,
  ) {
    final shapeRows = shape.cells.map((cell) => cell.row).fold(0, _maxInt) + 1;
    final shapeColumns =
        shape.cells.map((cell) => cell.column).fold(0, _maxInt) + 1;

    // Board vs. tray separation (user instruction: "oyun alanı ve rastgele
    // verilen blok parçaları alanındaki ayrımı netleştir ve kesinleştir").
    // The real bug: the invisible extra-reach `DragTarget` below the board
    // (see `_insertReachOverlay`'s doc comment — it exists so the *lifted*
    // piece can still reach row 9 even once the raw finger has gone below
    // the board's own box) has no way to know where the piece tray
    // physically sits on screen, so it necessarily has to stay generous —
    // generous enough that dragging the piece all the way back down onto
    // the tray to cancel it *still* lands inside that same invisible
    // strip. Every row/column below used `.clamp()` unconditionally, so
    // *any* position that far down got silently projected onto the
    // board's own last row — exactly the "the piece looks like it's about
    // to drop at the bottom of the board" bug report.
    //
    // The fix doesn't need to know the tray's bounds at all: it uses the
    // one signal that's always unambiguous regardless of screen layout —
    // whether the *dragged piece's own rectangle* (not the raw pointer,
    // which is offset from it) still geometrically overlaps the board's
    // rectangle at all. Once the player has dragged the piece down far
    // enough that it no longer touches the board even a little, this
    // returns `null` — no anchor, no ghost preview, and (via
    // `_onDragMove`'s null-branch clearing `_preview`) no placement
    // attempt on drop, whichever `DragTarget` happened to receive the
    // event. The piece then simply reverts to its tray slot the same way
    // any `Draggable` does when nothing accepted it — no new "return to
    // tray" mechanism needed, just removing the over-eager clamp that was
    // masking the lack of one.
    final pieceRect = Rect.fromLTWH(
      local.dx,
      local.dy,
      shapeColumns * cellSize,
      shapeRows * cellSize,
    );
    final boardRect = Rect.fromLTWH(
      0,
      0,
      widget.board.size * cellSize,
      widget.board.size * cellSize,
    );
    if (!pieceRect.overlaps(boardRect)) return null;

    final row = (local.dy / cellSize).floor().clamp(
      0,
      widget.board.size - shapeRows,
    );
    final column = (local.dx / cellSize).floor().clamp(
      0,
      widget.board.size - shapeColumns,
    );

    return GridPosition(row: row, column: column);
  }

  /// Always forwards the drop to `widget.onPlace`, valid or not — the
  /// engine is the single source of truth for placement validity (it
  /// re-checks independently and reports `GameEvent.invalidMove` for a
  /// rejected drop, which is what drives the invalid-move haptic/SFX). The
  /// local `_validator` here only paints the ghost preview color while
  /// dragging; it must never gate the actual action, or a rejected drop
  /// would give the player no feedback at all once they lift their finger.
  ///
  /// It also decides — purely visually, from the same already-known
  /// [_Preview.isValid] — whether to play the "Invalid Placement" bounce
  /// (user instruction): a short shake-and-fade of the piece's shape right
  /// where it was dropped, layered on top of (never replacing) the engine's
  /// own rejection feedback.
  void _commitPreview() {
    final preview = _preview;
    if (preview != null) {
      if (!preview.isValid) {
        _rejectBounceGeneration++;
        _rejectBounce = _RejectBounce(
          anchor: preview.anchor,
          shape: widget.tray[preview.trayIndex].shape,
          generation: _rejectBounceGeneration,
        );
      }
      widget.onPlace(preview.trayIndex, preview.anchor);
    }
    _lastDragLocalOffset = null;
    ref.read(dragFeelControllerProvider).reset();
    setState(() => _preview = null);
  }

  /// The "Invalid Placement" bounce's visual: the rejected shape shakes
  /// left-right and fades out over a quarter-second, exactly where it was
  /// dropped — a short, local "denied" echo rather than a full journey back
  /// to the tray (which would need tracking the tray slot's live position
  /// across rebuilds — a lot of extra plumbing for an effect this brief).
  Widget _rejectBounceOverlay(_RejectBounce bounce, double cellSize) {
    final shapeRows =
        bounce.shape.cells.map((cell) => cell.row).fold(0, _maxInt) + 1;
    final shapeColumns =
        bounce.shape.cells.map((cell) => cell.column).fold(0, _maxInt) + 1;

    return Positioned(
      left: bounce.anchor.column * cellSize,
      top: bounce.anchor.row * cellSize,
      width: shapeColumns * cellSize,
      height: shapeRows * cellSize,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey('reject-${bounce.generation}'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          onEnd: () {
            if (mounted) setState(() => _rejectBounce = null);
          },
          builder: (context, t, child) {
            // A quick shake settles by 60% of the way through, then the
            // whole thing fades out over the remaining time.
            final shakeT = (t / 0.6).clamp(0.0, 1.0);
            final shakeDecay = 1 - shakeT;
            final dx =
                math.sin(shakeT * math.pi * 4) * cellSize * 0.15 * shakeDecay;
            final opacity = 1 - ((t - 0.4) / 0.6).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              ),
            );
          },
          child: PieceView(
            shape: bounce.shape,
            cellSize: cellSize,
            opacity: 0.85,
          ),
        ),
      ),
    );
  }

  static int _maxInt(int a, int b) => a > b ? a : b;
}

/// The rejected shape a bounce is currently playing for — see
/// `_BoardGridState._rejectBounceOverlay`. [generation] forces a fresh
/// `TweenAnimationBuilder` (and thus a fresh play-through) each time a new
/// rejection happens, even if it's the same shape at the same anchor as the
/// last one.
class _RejectBounce {
  const _RejectBounce({
    required this.anchor,
    required this.shape,
    required this.generation,
  });

  final GridPosition anchor;
  final PieceShape shape;
  final int generation;
}

class _Preview {
  const _Preview({
    required this.trayIndex,
    required this.anchor,
    required this.cells,
    required this.isValid,
    required this.wouldClearCells,
  });

  final int trayIndex;
  final GridPosition anchor;
  final Set<GridPosition> cells;
  final bool isValid;
  // Every cell in a row/column this exact placement would complete —
  // empty when the spot is invalid or wouldn't clear anything.
  final Set<GridPosition> wouldClearCells;
}
