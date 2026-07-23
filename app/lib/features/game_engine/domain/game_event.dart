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
  const factory GameEvent.linesCleared({
    required List<int> rows,
    required List<int> columns,
    required int linePoints,
  }) = GameEventLinesCleared;

  /// The tray emptied and was refilled with a fresh batch.
  const factory GameEvent.trayRefilled() = GameEventTrayRefilled;

  /// Level Mode passed 900 points and the border frame was torn down.
  const factory GameEvent.frameDestroyed() = GameEventFrameDestroyed;

  /// A tray piece was rotated by the Rotate booster.
  const factory GameEvent.pieceRotated({
    required int trayIndex,
  }) = GameEventPieceRotated;

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
