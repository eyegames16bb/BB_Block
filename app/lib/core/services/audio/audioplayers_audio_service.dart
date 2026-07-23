import 'package:audioplayers/audioplayers.dart';
import 'package:bb_block/core/services/audio/audio_service.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';

/// Pools a handful of [AudioPlayer]s round-robin for overlapping one-shot
/// SFX, and keeps a dedicated looping player for the ambient background
/// track. Expects assets at `assets/audio/sfx/<effect>.mp3` and
/// `assets/audio/ambient/background_loop.mp3` — not bundled yet, see
/// CLAUDE.md.
final class AudioPlayersAudioService implements AudioService {
  AudioPlayersAudioService({int concurrentEffectPlayers = 6})
      : _effectPlayers = List.generate(
          concurrentEffectPlayers,
          (_) => AudioPlayer(),
        ),
        _ambientPlayer = AudioPlayer();

  final List<AudioPlayer> _effectPlayers;
  final AudioPlayer _ambientPlayer;

  int _nextEffectPlayerIndex = 0;
  bool _muted = false;
  double _volume = 1;

  @override
  Future<void> init() async {
    await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  Future<void> playEffect(SoundEffect effect) async {
    if (_muted) return;

    final player = _effectPlayers[_nextEffectPlayerIndex];
    _nextEffectPlayerIndex =
        (_nextEffectPlayerIndex + 1) % _effectPlayers.length;

    await player.stop();
    await player.setVolume(_volume);
    await player.play(AssetSource('audio/sfx/${effect.name}.mp3'));
  }

  @override
  Future<void> playAmbient() async {
    if (_muted) return;
    await _ambientPlayer.setVolume(_volume);
    await _ambientPlayer.play(
      AssetSource('audio/ambient/background_loop.mp3'),
    );
  }

  @override
  Future<void> stopAmbient() => _ambientPlayer.stop();

  @override
  void setMuted({required bool muted}) => _muted = muted;

  @override
  void setVolume(double volume) => _volume = volume.clamp(0, 1);
}
