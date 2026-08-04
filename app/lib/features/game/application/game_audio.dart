import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';

/// Maps an engine event to the one-shot SFX it should play, or `null` for a
/// silent event. Mirrors `game_haptics.dart`'s shape and reasoning — pure,
/// Riverpod-free, and independently unit-testable.
SoundEffect? soundEffectFor(GameEvent event) => switch (event) {
      GameEventInvalidMove() => SoundEffect.invalidMove,
      // A single new placement sound (user instruction) replaces the old
      // pieceSnap primary + pieceDrop secondary layering — see
      // procedural_sfx.dart's blockPlace recipe.
      GameEventPiecePlaced() => SoundEffect.blockPlace,
      GameEventLinesCleared(:final rows, :final columns) =>
        (rows.length + columns.length) >= 2
            ? SoundEffect.multipleLineComplete
            : SoundEffect.lineComplete,
      // Same reasoning as haptics: a piecePlaced or linesCleared event
      // already sounded this turn, so a refill stays silent.
      GameEventTrayRefilled() => null,
      GameEventFrameDestroyed() => SoundEffect.frameDestroy,
      GameEventTrayRotated() => SoundEffect.pieceRotate,
      GameEventTraySwapped() => SoundEffect.boosterActivate,
      GameEventCellRemoved() => SoundEffect.woodCrack,
      GameEventRoundEnded(:final outcome) => switch (outcome) {
          RoundOutcomeLevelComplete() => SoundEffect.levelComplete,
          RoundOutcomeLevelFailed() => SoundEffect.gameOver,
          RoundOutcomeClassicGameOver() => SoundEffect.gameOver,
          RoundOutcomeOngoing() => null,
        },
    };
