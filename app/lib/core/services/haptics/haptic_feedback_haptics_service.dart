import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:bb_block/core/utils/app_logger.dart';
import 'package:flutter/services.dart';

/// Uses Flutter's own `HapticFeedback` API (user instruction) — the
/// platform's native haptic engine (Android's haptic-constant vibration
/// effects, iOS's Taptic Engine) rather than a raw duration-based buzz.
/// Replaces the previous `vibration`-package implementation
/// (`VibrationHapticsService`, removed): a fixed-millisecond `Vibration
/// .vibrate(duration: ...)` call feels like one generic motor buzz
/// regardless of intensity, where `HapticFeedback`'s named calls each map
/// to a distinct, OS-tuned physical sensation — closer to what a
/// professional casual game (Block Blast, Royal Match, etc.) actually
/// ships. `HapticIntensity.selection` maps to `selectionClick` (a short,
/// crisp tick used for picking up a piece) rather than any of the impact
/// levels, since it's meant to feel different in kind, not just softer.
final class HapticFeedbackHapticsService implements HapticsService {
  bool _muted = false;

  @override
  Future<void> trigger(HapticIntensity intensity) async {
    if (_muted) return;

    try {
      switch (intensity) {
        case HapticIntensity.selection:
          await HapticFeedback.selectionClick();
        case HapticIntensity.light:
          await HapticFeedback.lightImpact();
        case HapticIntensity.medium:
          await HapticFeedback.mediumImpact();
        case HapticIntensity.heavy:
          await HapticFeedback.heavyImpact();
      }
    } on Object catch (error) {
      // Matches every other platform-channel service in this codebase
      // (audio, ads): a device/platform without haptic support shouldn't
      // crash the interaction that triggered it, just log and move on.
      appLogger.w('Could not trigger haptic feedback: $error');
    }
  }

  @override
  void setMuted({required bool muted}) => _muted = muted;
}
