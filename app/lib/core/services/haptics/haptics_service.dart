enum HapticIntensity { light, medium, heavy, selection }

abstract interface class HapticsService {
  Future<void> trigger(HapticIntensity intensity);

  void setMuted({required bool muted});
}
