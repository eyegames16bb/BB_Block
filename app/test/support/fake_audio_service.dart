import 'package:bb_block/core/services/audio/audio_service.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';

/// Records played effects instead of touching `audioplayers`, which needs
/// real asset files and platform channels not available under
/// `flutter test`.
class FakeAudioService implements AudioService {
  final List<SoundEffect> playedEffects = [];
  bool ambientPlaying = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> playEffect(SoundEffect effect) async {
    playedEffects.add(effect);
  }

  @override
  Future<void> playAmbient() async {
    ambientPlaying = true;
  }

  @override
  Future<void> stopAmbient() async {
    ambientPlaying = false;
  }

  @override
  void setMuted({required bool muted}) {}

  @override
  void setVolume(double volume) {}
}
