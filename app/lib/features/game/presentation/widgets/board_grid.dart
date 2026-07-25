import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_dust_effect.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';
import 'package:newton_particles/newton_particles.dart';

/// The 9×9 play surface. Renders the current [board], accepts pieces dragged
/// from the tray (identified by their tray index), shows a live ghost preview
/// of where the piece would land, and calls [onPlace] on a valid drop.
///
/// When [removalArmed] is true (the Single Cell Remove booster is active),
/// dragging is bypassed and tapping any filled cell calls [onCellTap]
/// instead — frame cells are never tappable, matching the engine's own
/// refusal to remove them.
class BoardGrid extends StatefulWidget {
  const BoardGrid({
    required this.board,
    required this.tray,
    required this.onPlace,
    this.removalArmed = false,
    this.onCellTap,
    super.key,
  });

  final Board board;
  final List<TrayPiece> tray;
  final void Function(int trayIndex, GridPosition anchor) onPlace;
  final bool removalArmed;
  final void Function(GridPosition position)? onCellTap;

  @override
  State<BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<BoardGrid> {
  static const PlacementValidator _validator = DefaultPlacementValidator();
  static const Duration _fillPopDuration = Duration(milliseconds: 260);
  static const Duration _clearBreakDuration = Duration(milliseconds: 320);
  static const Duration _frameBreakDuration = Duration(milliseconds: 520);

  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey<NewtonState> _newtonKey = GlobalKey<NewtonState>();
  _Preview? _preview;

  // Bumped for a position exactly when it transitions to filled, so the
  // TweenAnimationBuilder keyed on it below plays its pop-in once per
  // placement and then holds steady — never replaying on unrelated rebuilds.
  final Map<GridPosition, int> _fillGeneration = {};

  // Cells mid line-clear: the board already reports them empty, but we keep
  // rendering their wood tile here — fading and bursting outward — for one
  // more animation cycle instead of having them vanish instantly.
  final Set<GridPosition> _clearingCells = {};
  final Map<GridPosition, int> _clearGeneration = {};

  // Same idea for the one-time Level Mode frame teardown (decision #4 in
  // CLAUDE.md: a distinct effect from ordinary line clears, not the same
  // animation) — bigger, slower, and staggered into an outward wave instead
  // of every border cell fading uniformly at once.
  final Set<GridPosition> _frameClearingCells = {};
  final Map<GridPosition, int> _frameClearGeneration = {};

  @override
  void didUpdateWidget(covariant BoardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
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
            GamePalette.placedBlock,
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
    final delayFraction = ((position.row + position.column) /
            (2 * widget.board.size))
        .clamp(0.0, 0.5);
    Future.delayed(_frameBreakDuration * delayFraction, () {
      if (mounted) fire();
    });
  }

  @override
  Widget build(BuildContext context) {
    // A light-wood bezel frames the dark recessed grid — echoing the
    // reference mockups' margin between the board and the surrounding
    // table, instead of the grid floating as a flat dark rectangle.
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GamePalette.bezelLight, GamePalette.bezelDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GamePalette.boardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: DragTarget<int>(
                onMove: _onDragMove,
                onLeave: (_) => setState(() => _preview = null),
                onAcceptWithDetails: (_) => _commitPreview(),
                builder: (context, _, _) => LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize =
                        constraints.maxWidth / widget.board.size;
                    return Newton(
                      key: _newtonKey,
                      child: Container(
                        key: _gridKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var row = 0; row < widget.board.size; row++)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var col = 0;
                                      col < widget.board.size;
                                      col++)
                                    _cell(
                                      GridPosition(row: row, column: col),
                                      cellSize,
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(GridPosition position, double cellSize) {
    final state = widget.board.cellAt(position);
    final previewColor = _previewColorFor(position);
    final removable = widget.removalArmed && state == CellState.filled;

    return GestureDetector(
      onTap: removable ? () => widget.onCellTap?.call(position) : null,
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: Stack(
          fit: StackFit.expand,
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
          ],
        ),
      ),
    );
  }

  Widget _baseCell(GridPosition position, CellState state, double cellSize) {
    switch (state) {
      case CellState.filled:
        return TweenAnimationBuilder<double>(
          key: ValueKey(
            'fill-$position-${_fillGeneration[position] ?? 0}',
          ),
          tween: Tween(begin: 0.5, end: 1),
          duration: _fillPopDuration,
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: WoodTile(size: cellSize),
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

  /// Renders a fading, outward-bursting wood tile for a cell that was just
  /// cleared, then removes itself from [_clearingCells] once the animation
  /// finishes so the (already-empty) base cell shows through permanently.
  Widget _clearingOverlay(GridPosition position, double cellSize) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('clear-$position-${_clearGeneration[position] ?? 0}'),
      tween: Tween(begin: 0, end: 1),
      duration: _clearBreakDuration,
      curve: Curves.easeOut,
      onEnd: () {
        if (mounted) setState(() => _clearingCells.remove(position));
      },
      builder: (context, t, child) => Opacity(
        opacity: 1 - t,
        child: Transform.scale(scale: 1 + t * 0.35, child: child),
      ),
      child: WoodTile(size: cellSize),
    );
  }

  /// The Level Mode 900-point frame teardown. Deliberately bigger, slower
  /// and staggered (via an [Interval] keyed to distance from the top-left
  /// corner) into an outward wave, so the whole border shattering reads as
  /// a distinct, larger event rather than a big line clear.
  Widget _frameClearingOverlay(GridPosition position, double cellSize) {
    final delayFraction = ((position.row + position.column) /
            (2 * widget.board.size))
        .clamp(0.0, 0.5);

    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'frame-clear-$position-${_frameClearGeneration[position] ?? 0}',
      ),
      tween: Tween(begin: 0, end: 1),
      duration: _frameBreakDuration,
      curve: Interval(delayFraction, 1, curve: Curves.easeOut),
      onEnd: () {
        if (mounted) setState(() => _frameClearingCells.remove(position));
      },
      builder: (context, t, child) => Opacity(
        opacity: 1 - t,
        child: Transform.scale(scale: 1 + t * 0.6, child: child),
      ),
      child: WoodTile(size: cellSize, isFrame: true),
    );
  }

  Color? _previewColorFor(GridPosition position) {
    final preview = _preview;
    if (preview == null || !preview.cells.contains(position)) return null;
    return preview.isValid
        ? GamePalette.previewValid
        : GamePalette.previewInvalid;
  }

  void _onDragMove(DragTargetDetails<int> details) {
    final anchor = _anchorFrom(details.offset, details.data);
    if (anchor == null) return;

    final shape = widget.tray[details.data].shape;
    final cells = {
      for (final offset in shape.cells) anchor.offsetBy(offset),
    };
    final isValid = _validator.canPlace(
      board: widget.board,
      shape: shape,
      anchor: anchor,
    );

    setState(() {
      _preview = _Preview(
        trayIndex: details.data,
        anchor: anchor,
        cells: cells,
        isValid: isValid,
      );
    });
  }

  /// Maps the dragged piece's top-left global position to a board anchor,
  /// clamped so the whole shape stays on the grid.
  GridPosition? _anchorFrom(Offset globalOffset, int trayIndex) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final local = box.globalToLocal(globalOffset);
    final cellSize = box.size.width / widget.board.size;
    final shape = widget.tray[trayIndex].shape;

    final shapeRows =
        shape.cells.map((cell) => cell.row).fold(0, _maxInt) + 1;
    final shapeColumns =
        shape.cells.map((cell) => cell.column).fold(0, _maxInt) + 1;

    final row = (local.dy / cellSize)
        .floor()
        .clamp(0, widget.board.size - shapeRows);
    final column = (local.dx / cellSize)
        .floor()
        .clamp(0, widget.board.size - shapeColumns);

    return GridPosition(row: row, column: column);
  }

  /// Always forwards the drop to `widget.onPlace`, valid or not — the
  /// engine is the single source of truth for placement validity (it
  /// re-checks independently and reports `GameEvent.invalidMove` for a
  /// rejected drop, which is what drives the invalid-move haptic/SFX). The
  /// local `_validator` here only paints the ghost preview color while
  /// dragging; it must never gate the actual action, or a rejected drop
  /// would give the player no feedback at all once they lift their finger.
  void _commitPreview() {
    final preview = _preview;
    if (preview != null) {
      widget.onPlace(preview.trayIndex, preview.anchor);
    }
    setState(() => _preview = null);
  }

  static int _maxInt(int a, int b) => a > b ? a : b;
}

class _Preview {
  const _Preview({
    required this.trayIndex,
    required this.anchor,
    required this.cells,
    required this.isValid,
  });

  final int trayIndex;
  final GridPosition anchor;
  final Set<GridPosition> cells;
  final bool isValid;
}
