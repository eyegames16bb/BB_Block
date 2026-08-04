import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';

/// A second [SoundEffect] layered on top of `soundEffectFor`'s primary one,
/// for events where a single tone reads as thin. Mirrors the GDD's "katmanlı
/// ses" request — a placed piece gets a soft thud *under* its snap, a line
/// clear gets a bigger break texture under its chime, and so on. Both the
/// primary and secondary effect are ordinary [SoundEffect]s played through
/// the same pooled players, just started together.
SoundEffect? secondarySoundEffectFor(GameEvent event) => switch (event) {
      // blockPlace (see game_audio.dart) is a single self-sufficient
      // recipe now — no secondary layer needed under it.
      GameEventPiecePlaced() => null,
      // The star bonus (user instruction) gets its own distinct layer
      // regardless of line count — a single-line star clear should still
      // read as a bigger moment than an ordinary single-line clear.
      GameEventLinesCleared(starBonus: true) => SoundEffect.goldenKey,
      GameEventLinesCleared(:final rows, :final columns) =>
        (rows.length + columns.length) >= 2
            ? SoundEffect.woodExplosion
            : SoundEffect.woodBreak,
      GameEventFrameDestroyed() => SoundEffect.woodExplosion,
      GameEventTraySwapped() => SoundEffect.woodMerge,
      GameEventRoundEnded(:final outcome) => switch (outcome) {
          RoundOutcomeLevelComplete() => SoundEffect.victory,
          RoundOutcomeClassicGameOver() ||
          RoundOutcomeLevelFailed() ||
          RoundOutcomeOngoing() =>
            null,
        },
      // A hollow "empty wood tap" layered under the primary invalidMove
      // tone (user instruction: "Invalid Placement" — a rejected drop
      // should read as knocking on solid wood, not just an error beep).
      GameEventInvalidMove() => SoundEffect.woodHit,
      GameEventTrayRefilled() ||
      GameEventTrayRotated() ||
      GameEventCellRemoved() =>
        null,
    };

/// How hard the board should shake for this event, in roughly logical
/// pixels of peak displacement — `null` means no shake at all. Scales with
/// impact: a lone placement barely nudges the screen, a multi-line clear or
/// the frame coming down should really land (GDD: "Kamera daha fazla
/// sallanmalı" for bigger multi-clears).
double? screenShakeMagnitudeFor(GameEvent event) => switch (event) {
      GameEventPiecePlaced() => 1.5,
      GameEventLinesCleared(starBonus: true, :final rows, :final columns) =>
        6 + (rows.length + columns.length - 1) * 2.5,
      GameEventLinesCleared(:final rows, :final columns) =>
        3 + (rows.length + columns.length - 1) * 2.5,
      GameEventFrameDestroyed() => 9,
      GameEventRoundEnded(:final outcome) => switch (outcome) {
          RoundOutcomeLevelComplete() => 6,
          RoundOutcomeClassicGameOver() || RoundOutcomeLevelFailed() => 4,
          RoundOutcomeOngoing() => null,
        },
      GameEventInvalidMove() ||
      GameEventTrayRefilled() ||
      GameEventTrayRotated() ||
      GameEventTraySwapped() ||
      GameEventCellRemoved() =>
        null,
    };
