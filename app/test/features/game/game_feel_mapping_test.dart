import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/features/game/application/game_feel_mapping.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('secondarySoundEffectFor', () {
    test('a star-bonus line clear gets its own distinct layer regardless of '
        'line count (user instruction)', () {
      const event = GameEvent.linesCleared(
        rows: [4],
        columns: [],
        linePoints: 258,
        starBonus: true,
      );

      expect(secondarySoundEffectFor(event), SoundEffect.goldenKey);
    });

    test('an ordinary (non-star) single-line clear stays on woodBreak', () {
      const event = GameEvent.linesCleared(
        rows: [4],
        columns: [],
        linePoints: 8,
      );

      expect(secondarySoundEffectFor(event), SoundEffect.woodBreak);
    });

    test('a rejected drop layers a hollow wood-tap under the primary tone '
        '(user instruction: "Invalid Placement")', () {
      expect(
        secondarySoundEffectFor(const GameEvent.invalidMove()),
        SoundEffect.woodHit,
      );
    });
  });

  group('screenShakeMagnitudeFor', () {
    test('a star-bonus clear shakes harder than an ordinary one of the same '
        'line count', () {
      const starEvent = GameEvent.linesCleared(
        rows: [4],
        columns: [],
        linePoints: 258,
        starBonus: true,
      );
      const ordinaryEvent = GameEvent.linesCleared(
        rows: [4],
        columns: [],
        linePoints: 8,
      );

      expect(
        screenShakeMagnitudeFor(starEvent),
        greaterThan(screenShakeMagnitudeFor(ordinaryEvent)!),
      );
    });
  });
}
