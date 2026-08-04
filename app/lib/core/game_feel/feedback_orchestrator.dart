import 'dart:async';

import 'package:bb_block/core/game_feel/screen_shake.dart';
import 'package:bb_block/core/services/audio/audio_service.dart';
import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/game/application/game_audio.dart';
import 'package:bb_block/features/game/application/game_feel_mapping.dart';
import 'package:bb_block/features/game/application/game_haptics.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';

/// The Game Feel Engine's single entry point: `GameController` calls
/// [play] once per [GameEvent] instead of separately triggering haptics and
/// audio itself. Audio (primary + any layered secondary sound), haptics,
/// and screen shake all dispatch from here, so a given event's whole
/// feedback sequence lives in one place rather than three ad hoc call
/// sites — the engine layer just says what happened, this decides how it
/// feels.
class FeedbackOrchestrator {
  FeedbackOrchestrator({
    required AudioService audio,
    required HapticsService haptics,
    required ScreenShakeController screenShake,
  })  : _audio = audio,
        _haptics = haptics,
        _screenShake = screenShake;

  final AudioService _audio;
  final HapticsService _haptics;
  final ScreenShakeController _screenShake;

  void play(GameEvent event) {
    final intensity = hapticIntensityFor(event);
    if (intensity != null) unawaited(_haptics.trigger(intensity));

    final effect = soundEffectFor(event);
    if (effect != null) unawaited(_audio.playEffect(effect));
    final layered = secondarySoundEffectFor(event);
    if (layered != null) unawaited(_audio.playEffect(layered));

    final shake = screenShakeMagnitudeFor(event);
    if (shake != null) _screenShake.shake(shake);

    _playExtraPulseFor(event);
  }

  /// A second, delayed haptic pulse for the handful of moments the user's
  /// haptic spec calls out as needing more than a single flat impact:
  ///
  /// - **Combo** (a multi-line clear): "Heavy Impact + kısa Success hissi"
  ///   — the primary heavy pulse already fired above; this adds a light
  ///   follow-up so a combo reads as a distinct two-beat "bigger" moment
  ///   next to an ordinary single-line clear's single heavy pulse.
  /// - **Frame teardown**: "Belirgin Heavy Impact" (a *pronounced* heavy
  ///   impact) — a second heavy pulse shortly after the first makes the
  ///   750-point frame break read as weightier than a plain line clear,
  ///   which only ever gets one.
  /// - **Level complete**: "Success Notification" — Flutter's
  ///   `HapticFeedback` has no dedicated notification-style haptic (that's
  ///   an iOS-only concept, `UINotificationFeedbackGenerator`, not exposed
  ///   through the cross-platform API this app uses); a heavy pulse
  ///   followed by a light one approximates the same "done — and it went
  ///   well" two-beat feel.
  ///
  /// Every case here is *in addition to* the primary pulse [play] already
  /// triggered above, never a replacement for it.
  void _playExtraPulseFor(GameEvent event) {
    switch (event) {
      case GameEventLinesCleared(:final rows, :final columns)
          when (rows.length + columns.length) >= 2:
        _delayedPulse(HapticIntensity.light, const Duration(milliseconds: 90));
      case GameEventFrameDestroyed():
        _delayedPulse(HapticIntensity.heavy, const Duration(milliseconds: 100));
      case GameEventRoundEnded(outcome: RoundOutcomeLevelComplete()):
        _delayedPulse(HapticIntensity.light, const Duration(milliseconds: 150));
      case _:
        break;
    }
  }

  void _delayedPulse(HapticIntensity intensity, Duration delay) {
    unawaited(
      Future<void>.delayed(delay).then((_) => _haptics.trigger(intensity)),
    );
  }
}
