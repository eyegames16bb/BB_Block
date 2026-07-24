import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';

/// Maps an engine event to the haptic pulse it should produce, or `null` if
/// it shouldn't buzz at all. Pure and Riverpod-free so the mapping itself is
/// trivially unit-testable — `GameController` just calls this and forwards
/// the result to [HapticsService].
HapticIntensity? hapticIntensityFor(GameEvent event) => switch (event) {
      GameEventInvalidMove() => HapticIntensity.light,
      GameEventPiecePlaced() => HapticIntensity.selection,
      GameEventLinesCleared(:final rows, :final columns) =>
        (rows.length + columns.length) >= 2
            ? HapticIntensity.heavy
            : HapticIntensity.medium,
      // Always co-occurs with a piecePlaced/linesCleared event in the same
      // turn — that one already buzzed, so this stays silent to avoid a
      // redundant double-pulse.
      GameEventTrayRefilled() => null,
      GameEventFrameDestroyed() => HapticIntensity.heavy,
      GameEventPieceRotated() => HapticIntensity.selection,
      GameEventTraySwapped() => HapticIntensity.medium,
      GameEventCellRemoved() => HapticIntensity.medium,
      GameEventRoundEnded() => HapticIntensity.heavy,
    };
