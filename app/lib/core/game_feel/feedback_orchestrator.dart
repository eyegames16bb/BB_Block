import 'dart:async';

import 'package:bb_block/core/game_feel/screen_shake.dart';
import 'package:bb_block/core/services/audio/audio_service.dart';
import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/features/game/application/game_audio.dart';
import 'package:bb_block/features/game/application/game_feel_mapping.dart';
import 'package:bb_block/features/game/application/game_haptics.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';

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
  }
}
