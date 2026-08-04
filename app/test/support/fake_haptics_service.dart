import 'package:bb_block/core/services/haptics/haptics_service.dart';

/// Records triggered pulses instead of touching the real `HapticFeedback`
/// platform channel, which isn't available under `flutter test`.
class FakeHapticsService implements HapticsService {
  final List<HapticIntensity> triggered = [];
  bool muted = false;

  @override
  Future<void> trigger(HapticIntensity intensity) async {
    triggered.add(intensity);
  }

  @override
  void setMuted({required bool muted}) => this.muted = muted;
}
