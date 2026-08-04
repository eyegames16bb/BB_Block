import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';

/// Maps an engine event to the haptic pulse it should produce, or `null` if
/// it shouldn't buzz at all. Pure and Riverpod-free so the mapping itself is
/// trivially unit-testable — `GameController` just calls this and forwards
/// the result to [HapticsService].
HapticIntensity? hapticIntensityFor(GameEvent event) => switch (event) {
      // "Soft Haptic" for a rejected drop (user instruction).
      GameEventInvalidMove() => HapticIntensity.light,
      // "Medium Impact" on a correct placement (user instruction — reverses
      // an earlier session's decision to keep placement silent; the newer,
      // explicit instruction wins).
      GameEventPiecePlaced() => HapticIntensity.medium,
      // "Heavy Impact" for completing a line, single or multi (user
      // instruction) — `FeedbackOrchestrator` layers an extra short pulse
      // on top for a multi-line combo specifically, so the *base* intensity
      // here stays heavy either way rather than branching on line count.
      GameEventLinesCleared() => HapticIntensity.heavy,
      // Always co-occurs with a piecePlaced/linesCleared event in the same
      // turn — that one already buzzed, so this stays silent to avoid a
      // redundant double-pulse.
      GameEventTrayRefilled() => null,
      GameEventFrameDestroyed() => HapticIntensity.heavy,
      GameEventTrayRotated() => HapticIntensity.selection,
      GameEventTraySwapped() => HapticIntensity.medium,
      GameEventCellRemoved() => HapticIntensity.medium,
      GameEventRoundEnded() => HapticIntensity.heavy,
    };
