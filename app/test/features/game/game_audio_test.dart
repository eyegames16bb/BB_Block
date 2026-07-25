import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/game/application/game_audio.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid move plays the invalidMove SFX', () {
    expect(
      soundEffectFor(const GameEvent.invalidMove()),
      SoundEffect.invalidMove,
    );
  });

  test('placing a piece plays the snap SFX', () {
    expect(
      soundEffectFor(const GameEvent.piecePlaced(placementPoints: 1)),
      SoundEffect.pieceSnap,
    );
  });

  test('a single cleared line plays lineComplete, two or more plays '
      'multipleLineComplete', () {
    expect(
      soundEffectFor(
        const GameEvent.linesCleared(rows: [0], columns: [], linePoints: 9),
      ),
      SoundEffect.lineComplete,
    );
    expect(
      soundEffectFor(
        const GameEvent.linesCleared(
          rows: [0, 1],
          columns: [],
          linePoints: 18,
        ),
      ),
      SoundEffect.multipleLineComplete,
    );
  });

  test('a tray refill stays silent', () {
    expect(soundEffectFor(const GameEvent.trayRefilled()), isNull);
  });

  test('frame destruction plays its own distinct SFX', () {
    expect(
      soundEffectFor(const GameEvent.frameDestroyed()),
      SoundEffect.frameDestroy,
    );
  });

  test('boosters: rotate/swap/removeCell each play a distinct SFX', () {
    expect(
      soundEffectFor(const GameEvent.trayRotated()),
      SoundEffect.pieceRotate,
    );
    expect(
      soundEffectFor(const GameEvent.traySwapped()),
      SoundEffect.boosterActivate,
    );
    expect(
      soundEffectFor(
        const GameEvent.cellRemoved(
          position: GridPosition(row: 0, column: 0),
        ),
      ),
      SoundEffect.woodCrack,
    );
  });

  test('round end SFX depends on the outcome', () {
    expect(
      soundEffectFor(
        const GameEvent.roundEnded(outcome: RoundOutcome.levelComplete()),
      ),
      SoundEffect.levelComplete,
    );
    expect(
      soundEffectFor(
        const GameEvent.roundEnded(outcome: RoundOutcome.levelFailed()),
      ),
      SoundEffect.gameOver,
    );
    expect(
      soundEffectFor(
        const GameEvent.roundEnded(
          outcome: RoundOutcome.classicGameOver(),
        ),
      ),
      SoundEffect.gameOver,
    );
  });
}
