import 'dart:async';
import 'dart:math' as math;

import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/game_feel_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/services/placement_validator.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_view.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three-piece tray. Each unused piece is draggable onto the board; the
/// dragged feedback is rendered at [dragCellSize] so it matches the board's
/// scale. The resting tray instead fits each piece to its own slot — a fixed
/// resting cell size used to clip the 4/5-cell straight line pieces (user
/// report), since a slot sized for the common 1-3 cell shapes is too small
/// for a 5-tall vertical line at that same fixed size. [trayMaxCellSize]
/// caps how large a resting piece can render; anything that wouldn't fit
/// its slot at that size shrinks down until it does.
///
/// [board] is used purely for a visual hint (user instruction): a piece
/// that currently has no valid spot anywhere on the board renders dimmed,
/// so the player can tell at a glance it's a dead end without having to
/// drag it around first. It's still fully draggable — dimming is advisory,
/// never a restriction, since the engine is the single source of truth for
/// what's actually placeable.
class PieceTray extends ConsumerWidget {
  const PieceTray({
    required this.tray,
    required this.dragCellSize,
    required this.board,
    // The display *area* stays the same size (user instruction, revised) —
    // only the pieces rendered inside it shrink, so all three comfortably
    // fit with room to spare instead of crowding/clipping the slot.
    this.trayMaxCellSize = 20,
    super.key,
  });

  final List<TrayPiece> tray;
  final double dragCellSize;
  final Board board;
  final double trayMaxCellSize;

  static const PlacementValidator _validator = DefaultPlacementValidator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The reference mockup's `.piece-dock` — a dark-wood panel grounding
    // the slots, instead of the pieces floating directly on the table
    // background with nothing behind them.
    //
    // Transparent Glass Panel redesign (user instruction, visual only):
    // this panel's fill is now semi-transparent, matching the main HUD
    // card it sits inside (`_GlassGamePanel` in `game_screen.dart`) —
    // deliberately just a translucent color here, with no *second*
    // `BackdropFilter` of its own: it already sits on top of the main
    // panel's own blur, so stacking another one would double the blur
    // cost for no visible benefit ("Blur yalnızca ana panelde çalışsın").
    // The pieces themselves (`WoodTile`s inside `PieceView`) are a
    // completely separate layer painted on top and never had their
    // opacity touched — still fully opaque.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GamePalette.panelDark.withValues(alpha: 0.62),
        border: Border.all(color: GamePalette.panelDarkBorder, width: 3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var index = 0; index < tray.length; index++)
            Expanded(child: _slot(ref, tray[index], index)),
        ],
      ),
    );
  }

  Widget _slot(WidgetRef ref, TrayPiece piece, int index) {
    if (piece.isUsed) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final rows =
            piece.shape.cells.map((cell) => cell.row).reduce(math.max) + 1;
        final columns =
            piece.shape.cells.map((cell) => cell.column).reduce(math.max) + 1;
        // A small inset so even the longest pieces never touch the slot's
        // edge, plus never rendering *larger* than trayMaxCellSize just
        // because a 1-2 cell piece has lots of spare room.
        const inset = 8.0;
        final restingCellSize = [
          trayMaxCellSize,
          (constraints.maxWidth - inset) / columns,
          (constraints.maxHeight - inset) / rows,
        ].reduce(math.min);

        final placeable = _validator.hasAnyValidPlacement(
          board: board,
          shape: piece.shape,
        );
        final resting = Center(
          child: PieceView(
            shape: piece.shape,
            cellSize: restingCellSize,
            opacity: placeable ? 1 : GamePalette.unplaceablePieceOpacity,
          ),
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: _draggable(ref, piece, index, resting),
        );
      },
    );
  }

  Widget _draggable(
    WidgetRef ref,
    TrayPiece piece,
    int index,
    Widget resting,
  ) {
    final rows = piece.shape.cells.map((cell) => cell.row).reduce(math.max) + 1;
    final columns =
        piece.shape.cells.map((cell) => cell.column).reduce(math.max) + 1;
    final feedbackWidth = columns * dragCellSize;
    final feedbackHeight = rows * dragCellSize;

    return Listener(
      // Touch Area Expansion (user instruction) — a real bug found while
      // building this: `Center`'s own render box *does* size itself to fill
      // this whole slot (bounded-but-loose constraints), but that alone
      // doesn't make the empty margin around a small piece tappable —
      // `RenderPositionedBox` (what `Center` builds) doesn't hit-test-catch
      // on its own, it only reports a hit where its *child* (the
      // shape-sized `PieceView`) actually occupies. Both this `Listener`'s
      // default `HitTestBehavior.deferToChild` and `Draggable`'s own default
      // (same) would therefore only start a drag when the finger lands on
      // the piece's own drawn cells — a 1-cell piece in a much bigger slot
      // would leave most of its "generous touch target" untappable despite
      // the slot visually being that big. `HitTestBehavior.opaque` on both
      // this `Listener` and the `Draggable` below makes the *entire*
      // `SizedBox`-bounded slot (see `_slot`) register a hit, drawn pixels
      // or not.
      behavior: HitTestBehavior.opaque,
      // "Block Grab" feedback moved from `onDragStarted` to the raw pointer
      // touch-down (user instruction: "Instant Selection" — selecting a
      // piece must read as instant, zero perceptible delay before it lifts).
      // `Draggable`'s `onDragStarted` only fires once Flutter's gesture
      // arena actually resolves the drag — which needs the first detected
      // pointer *move*, not just the initial touch — so there was always a
      // hidden, if usually tiny, gap between "finger touches the piece" and
      // "piece confirms it's picked up." A raw `Listener` never competes in
      // the gesture arena, so this fires at the literal instant of contact
      // regardless of whether a drag ends up happening.
      onPointerDown: (_) {
        unawaited(
          ref.read(audioServiceProvider).playEffect(SoundEffect.piecePickUp),
        );
        // "Selection Click" (user instruction) — the short, crisp haptic
        // used specifically for *picking a piece up*, distinct from the
        // heavier confirmation pulses placement/line-clears use.
        unawaited(
          ref.read(hapticsServiceProvider).trigger(HapticIntensity.selection),
        );
      },
      child: Draggable<int>(
        data: index,
        // See the `Listener` above — same "Touch Area Expansion" reasoning,
        // applied to `Draggable`'s own separate hit-test region.
        hitTestBehavior: HitTestBehavior.opaque,
        // The Hidden Anchor Point (HN) — user instruction. Every piece has
        // an invisible reference point at the bottom-center of its bounding
        // box; the player never sees it, only the drag/placement math ever
        // reads it. `BoardGrid._anchorFrom` treats the feedback widget's
        // reported top-left (`DragTargetDetails.offset`) as the shape's own
        // top-left cell corner — so pinning the finger to a *fixed* offset
        // from that top-left is equivalent to pinning it to a fixed offset
        // from the shape's HN, as long as that offset accounts for the
        // shape's actual pixel size. A shape-agnostic `Offset(0, liftPixels)`
        // (the previous version of this code) pinned the finger to the
        // shape's top-left corner specifically — correct vertically, but it
        // left wider pieces hanging entirely to the finger's right instead
        // of centered over it. This version derives the anchor from the
        // shape's own rendered width/height so HN is genuinely at the
        // bottom-center, `GamePalette.dragLiftPixels` above the raw finger,
        // for every shape:
        //
        //   anchorOffset = pointer→feedback.topLeft translation Flutter
        //   itself applies internally, so solving
        //     feedback.topLeft + (width/2, height) [HN, local]
        //         == pointer - (0, liftPixels)      [HN, desired world pos]
        //   for the anchor Flutter wants (feedback.topLeft == pointer -
        //   anchorOffset) gives anchorOffset = (width/2, liftPixels + height).
        //
        // No grid math anywhere reads the raw pointer directly — it only
        // ever sees `details.offset`, i.e. HN's position — satisfying the
        // "all placement math goes through HN" requirement.
        // "Blok Taşıma Hissiyatı" — user report: the projection reads as
        // slightly left-leaning relative to the finger. A smaller x anchor
        // offset shifts the projected shape right for the same pointer
        // position (see the math above) — `0.42` instead of an exact half
        // is a small, deliberate rightward nudge, not a full re-centering.
        dragAnchorStrategy: (draggable, context, position) => Offset(
          feedbackWidth * 0.42,
          GamePalette.dragLiftPixels + feedbackHeight,
        ),
        onDragStarted: () {
          // Fresh drag, fresh feel state — nothing from a previous drag
          // (tilt, snap pull) should carry over.
          ref.read(dragFeelControllerProvider).reset();
          // The layered "drag" sound (distinct from the touch-down pick-up
          // cue above) still only makes sense once a drag genuinely starts.
          unawaited(
            ref.read(audioServiceProvider).playEffect(SoundEffect.pieceDrag),
          );
        },
        onDragEnd: (_) => ref.read(dragFeelControllerProvider).reset(),
        // The piece itself is now fully invisible for the whole drag (user
        // instruction: from the moment it's picked up, nothing should
        // render on screen for it — only the board's own ghost preview,
        // built from `_onDragMove`'s reported HN position, shows where it
        // would land). This placeholder is otherwise real — its size still
        // matches the shape (matters for `dragAnchorStrategy`'s own HN math
        // above, which reasons about the feedback's geometry, not its
        // paint) — it's just fully transparent.
        feedback: IgnorePointer(
          child: SizedBox(width: feedbackWidth, height: feedbackHeight),
        ),
        childWhenDragging: Opacity(
          opacity: GamePalette.draggingSlotOpacity,
          child: resting,
        ),
        child: resting,
      ),
    );
  }
}
