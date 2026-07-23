import 'package:bb_block/core/services/audio/sound_effect.dart';

abstract interface class AudioService {
  Future<void> init();

  Future<void> playEffect(SoundEffect effect);

  Future<void> playAmbient();

  Future<void> stopAmbient();

  void setMuted({required bool muted});

  void setVolume(double volume);
}
