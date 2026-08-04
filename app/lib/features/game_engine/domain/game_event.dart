import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_event.freezed.dart';

/// A single observable thing that happened during one engine operation.
/// The engine returns an ordered list of these per call; the presentation
/// layer maps them to audio, haptics and animation without ever reaching
/// into engine internals. Nothing here drives game logic — these are
/// side-effect cues, not state.
@freezed
sealed class GameEvent with _$GameEvent {
  /// The requested move was rejected (occupied cells, out of bounds, or an
  /// already-used tray slot). No state changed.
  const factory GameEvent.invalidMove() = GameEventInvalidMove;

  /// A piece was placed; [placementPoints] equals its cell count.
  const factory GameEvent.piecePlaced({
    required int placementPoints,
  }) = GameEventPiecePlaced;

  /// One or more full lines cleared in the same move. [rows]/[columns] carry
  /// the cleared indices so the UI can animate exactly those lines.
  /// [starBonus] is true when this clear included Level Mode's star-marked
  /// row/column (see `LevelModeConstants.starLineBonus`) — [linePoints]
  /// already has that bonus folded in; this flag is purely for feedback
  /// (a distinct sound/haptic), not a second source of points. The star
  /// bonus is one-time per round (user instruction) — `GameEngine` clears
  /// the star target the instant this fires `true`, so it's structurally
  /// impossible for a later clear to set it `true` again this round.
  const factory GameEvent.linesCleared({
    required List<int> rows,
    required List<int> columns,
    required int linePoints,
    @Default(false) bool starBonus,
  }) = GameEventLinesCleared;

  /// The tray emptied and was refilled with a fresh batch.
  const factory GameEvent.trayRefilled() = GameEventTrayRefilled;

  /// Level Mode passed 750 points and the border frame was torn down.
  const factory GameEvent.frameDestroyed() = GameEventFrameDestroyed;

  /// Every unused tray piece was rotated 90° by the Rotate booster — it
  /// applies to the whole tray at once, the same as the Swap booster does.
  const factory GameEvent.trayRotated() = GameEventTrayRotated;

  /// The whole tray was replaced by the Swap booster.
  const factory GameEvent.traySwapped() = GameEventTraySwapped;

  /// A single filled cell was erased by the Single Cell Remove booster.
  const factory GameEvent.cellRemoved({
    required GridPosition position,
  }) = GameEventCellRemoved;

  /// The round reached a terminal state (game over / level failed /
  /// level complete).
  const factory GameEvent.roundEnded({
    required RoundOutcome outcome,
  }) = GameEventRoundEnded;
}
