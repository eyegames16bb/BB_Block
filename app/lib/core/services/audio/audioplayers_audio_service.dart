import 'package:audioplayers/audioplayers.dart';
import 'package:bb_block/core/services/audio/audio_service.dart';
import 'package:bb_block/core/services/audio/procedural_sfx.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/core/utils/app_logger.dart';

/// Pools a handful of [AudioPlayer]s round-robin for overlapping one-shot
/// SFX, and keeps a dedicated looping player for the ambient background
/// track. Most gameplay SFX are synthesized in-memory by [proceduralSfxFor]
/// (no licensed asset needed — see CLAUDE.md's Mixkit/Zapsplat concern) and
/// played via `BytesSource`; anything without a procedural recipe falls
/// back to `assets/audio/sfx/<effect>.mp3`, which isn't bundled yet. The
/// ambient loop always uses `assets/audio/ambient/background_loop.mp3`,
/// also not bundled. Every play call is wrapped so a missing asset logs
/// instead of throwing.
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

    try {
      await player.stop();
      await player.setVolume(_volume);
      final proceduralBytes = proceduralSfxFor(effect);
      if (proceduralBytes != null) {
        await player.play(
          BytesSource(proceduralBytes, mimeType: 'audio/wav'),
        );
      } else {
        await player.play(AssetSource('audio/sfx/${effect.name}.mp3'));
      }
    } on Object catch (error) {
      appLogger.w('Could not play SFX ${effect.name}: $error');
    }
  }

  @override
  Future<void> playAmbient() async {
    if (_muted) return;
    try {
      await _ambientPlayer.setVolume(_volume);
      await _ambientPlayer.play(
        AssetSource('audio/ambient/background_loop.mp3'),
      );
    } on Object catch (error) {
      appLogger.w('Could not play ambient track: $error');
    }
  }

  @override
  Future<void> stopAmbient() => _ambientPlayer.stop();

  @override
  void setMuted({required bool muted}) => _muted = muted;

  @override
  void setVolume(double volume) => _volume = volume.clamp(0, 1);
}
