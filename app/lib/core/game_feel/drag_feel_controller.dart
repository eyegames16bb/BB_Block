import 'package:flutter/widgets.dart';

/// Bridges live drag state from `BoardGrid` to the piece's own floating drag
/// image (`_GrabbedPiece` in `piece_tray.dart`), which is rendered by
/// `Draggable`'s `Overlay` entry and has no direct reference to the board
/// otherwise. Mirrors `ScreenShakeController`'s existing shape: a plain
/// `ChangeNotifier` event/state bus, one instance per app (see
/// `game_feel_providers.dart`), read via `ref.watch` on both ends rather
/// than plumbed through constructors.
///
/// [tiltRadians] is the *only* thing this drives now: a small lean in the
/// direction of recent horizontal movement — the same "the piece has a
/// little weight to it" cue a lot of casual puzzle games use, derived from
/// how far the pointer moved between consecutive drag-move events rather
/// than true velocity (no extra timing plumbing needed for something this
/// subtle). It is deliberately independent of the board/grid entirely —
/// purely a function of raw pointer deltas — so it can never make the piece
/// feel "caught" on anything.
///
/// **What this controller does *not* do (user instruction, "Drag Motion &
/// Placement Pipeline Refactor")**: it used to also apply a continuous
/// "magnetic snap" pull toward the hovered cell's exact pixel position
/// while dragging. That was removed outright — it was the actual root
/// cause of a reported "the block feels like it's magnetically caught on
/// grid cells" bug: the pull vector jumps discontinuously every time the
/// drag crosses a cell boundary (its target, the new cell's pixel origin,
/// changes by a whole cell size), and that discontinuity is exactly what
/// read as a micro stutter/snap right when passing over a cell — not an
/// actual dropped frame, a real (if small) jump in the piece's rendered
/// position. The fix is architectural, not a tuning knob: grid detection
/// and placement validation (still computed every move, in `BoardGrid`)
/// are only ever allowed to *read* the drag position to decide what the
/// ghost preview shows — they must never feed anything back into the
/// piece's own on-screen position while the drag is still in progress.
/// "Snap" now only ever happens at the one moment it should: the engine
/// placing the piece exactly into its cell the instant the finger lifts,
/// which is where `PlaceSequence`'s spring pop-in already reads as a
/// satisfying, sharp "settle" — no separate mid-drag mechanic needed for
/// that feel.
///
/// Resets to zero the instant a drag ends (or a fresh one starts) — see
/// [reset] — so nothing leaks from one drag into the next.
class DragFeelController extends ChangeNotifier {
  double tiltRadians = 0;

  static const double maxTiltRadians = 0.06;

  void update({double tiltRadians = 0}) {
    if (this.tiltRadians == tiltRadians) return;
    this.tiltRadians = tiltRadians;
    notifyListeners();
  }

  void reset() => update();
}
