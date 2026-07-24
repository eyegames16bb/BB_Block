import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';

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

  final GlobalKey _gridKey = GlobalKey();
  _Preview? _preview;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GamePalette.boardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DragTarget<int>(
            onMove: _onDragMove,
            onLeave: (_) => setState(() => _preview = null),
            onAcceptWithDetails: (_) => _commitPreview(),
            builder: (context, _, _) => LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = constraints.maxWidth / widget.board.size;
                return Container(
                  key: _gridKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var row = 0; row < widget.board.size; row++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var col = 0; col < widget.board.size; col++)
                              _cell(GridPosition(row: row, column: col),
                                  cellSize),
                          ],
                        ),
                    ],
                  ),
                );
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
    final removable = widget.removalArmed && state == CellState.filled;

    return GestureDetector(
      onTap: removable ? () => widget.onCellTap?.call(position) : null,
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _baseCell(state, cellSize),
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

  Widget _baseCell(CellState state, double cellSize) {
    switch (state) {
      case CellState.filled:
        return WoodTile(size: cellSize);
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

  void _commitPreview() {
    final preview = _preview;
    if (preview != null && preview.isValid) {
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
