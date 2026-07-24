import 'package:bb_block/core/services/haptics/haptics_service.dart';
import 'package:vibration/vibration.dart';

final class VibrationHapticsService implements HapticsService {
  bool _muted = false;

  @override
  Future<void> trigger(HapticIntensity intensity) async {
    if (_muted) return;

    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

    final duration = switch (intensity) {
      HapticIntensity.selection => 10,
      HapticIntensity.light => 15,
      HapticIntensity.medium => 25,
      HapticIntensity.heavy => 40,
    };

    await Vibration.vibrate(duration: duration);
  }

  @override
  void setMuted({required bool muted}) => _muted = muted;
}
