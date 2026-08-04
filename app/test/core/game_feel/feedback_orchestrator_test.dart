import 'package:bb_block/core/game_feel/feedback_orchestrator.dart';
import 'package:bb_block/core/game_feel/screen_shake.dart';
import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_audio_service.dart';
import '../../support/fake_haptics_service.dart';

void main() {
  FeedbackOrchestrator orchestrator({
    required FakeHapticsService haptics,
  }) {
    return FeedbackOrchestrator(
      audio: FakeAudioService(),
      haptics: haptics,
      screenShake: ScreenShakeController(),
    );
  }

  test('a single-line clear fires only the one heavy pulse — no extra '
      '"combo" follow-up', () async {
    final haptics = FakeHapticsService();
    orchestrator(haptics: haptics).play(
      const GameEvent.linesCleared(rows: [0], columns: [], linePoints: 9),
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(haptics.triggered, [HapticIntensity.heavy]);
  });

  test('a multi-line clear (combo) fires the primary heavy pulse, then a '
      'light follow-up shortly after (user instruction: "Heavy Impact + '
      'kısa Success hissi")', () async {
    final haptics = FakeHapticsService();
    orchestrator(haptics: haptics).play(
      const GameEvent.linesCleared(
        rows: [0, 1],
        columns: [],
        linePoints: 18,
      ),
    );

    // Immediately after: only the primary pulse has fired yet.
    expect(haptics.triggered, [HapticIntensity.heavy]);

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(
      haptics.triggered,
      [HapticIntensity.heavy, HapticIntensity.light],
    );
  });

  test('frame teardown fires two heavy pulses — a "pronounced" heavy '
      'impact (user instruction)', () async {
    final haptics = FakeHapticsService();
    orchestrator(haptics: haptics).play(const GameEvent.frameDestroyed());

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(
      haptics.triggered,
      [HapticIntensity.heavy, HapticIntensity.heavy],
    );
  });

  test('level complete fires a heavy pulse then a light one, approximating '
      'a "Success Notification" (user instruction)', () async {
    final haptics = FakeHapticsService();
    orchestrator(haptics: haptics).play(
      const GameEvent.roundEnded(outcome: RoundOutcome.levelComplete()),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(
      haptics.triggered,
      [HapticIntensity.heavy, HapticIntensity.light],
    );
  });

  test('classic game over (not level complete) gets no extra follow-up '
      'pulse', () async {
    final haptics = FakeHapticsService();
    orchestrator(haptics: haptics).play(
      const GameEvent.roundEnded(outcome: RoundOutcome.classicGameOver()),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(haptics.triggered, [HapticIntensity.heavy]);
  });
}
