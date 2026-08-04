import 'package:audioplayers/audioplayers.dart';
import 'package:bb_block/core/services/audio/audio_service.dart';
import 'package:bb_block/core/services/audio/procedural_sfx.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:bb_block/core/utils/app_logger.dart';

/// Pools a handful of [AudioPlayer]s round-robin for overlapping one-shot
/// SFX, and keeps a dedicated looping player for the ambient background
/// track. Most gameplay SFX are synthesized by [proceduralSfxPathFor] (no
/// licensed asset needed — see CLAUDE.md's Mixkit/Zapsplat concern),
/// written to a temp file, and played via `DeviceFileSource` — the same
/// well-tested playback path every asset/URL source already uses, rather
/// than `BytesSource` (a narrower, less-exercised code path in
/// `audioplayers`; see `procedural_sfx.dart`). Anything without a
/// procedural recipe falls back to `assets/audio/sfx/<effect>.mp3`, which
/// isn't bundled yet. The ambient loop always uses
/// `assets/audio/ambient/background_loop.mp3`, also not bundled. Every play
/// call is wrapped so a missing asset logs instead of throwing.
final class AudioPlayersAudioService implements AudioService {
  // Bumped from 6 (user instruction: increase the channel count as part of
  // investigating the background-audio-interruption bug) — a busy turn
  // (placement + line-clear + combo/star bonus layered sounds, all fired
  // within the same frame via `FeedbackOrchestrator`) can legitimately want
  // more than a couple of these active at once; a deeper pool means a
  // later effect is less likely to `.stop()` an still-playing earlier one
  // just to reuse its channel.
  AudioPlayersAudioService({int concurrentEffectPlayers = 12})
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
    // Bug fix (user report, marked critical: turning sound on stops/
    // interrupts whatever background audio — music from another app — was
    // already playing). audioplayers' default `AudioContext` requests
    // *exclusive* audio focus on Android (`AndroidAudioFocus.gain`) and a
    // non-mixing session category on iOS, so simply playing our first SFX
    // silences the rest of the device. `AndroidAudioFocus.none` never
    // requests focus at all, and iOS's `ambient` category mixes with other
    // apps' audio by design — both let our short one-shot SFX/ambient loop
    // layer on top of whatever else is already playing instead of
    // stopping it.
    //
    // The *authoritative* copy of this same call now lives in `main()`,
    // deliberately run before `runApp` — this repeat here is a defensive
    // fallback in case `AudioPlayersAudioService` is ever constructed
    // through a path that skipped `main()` (there isn't one today, but the
    // cost of being wrong about that is a silenced background track, so
    // the redundancy — `setAudioContext` is idempotent — is worth it.
    //
    // Wrapped like every other platform call below: in a headless test
    // environment (no real platform channel behind audioplayers) this
    // throws, and since `init()` is fired via `unawaited()` from
    // `audioServiceProvider`, an uncaught throw here surfaced as a stray
    // async error landing in whatever *later* test happened to be running
    // when the Future rejected — not the test that actually triggered it.
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    } on Object catch (error) {
      appLogger.w('Could not configure audio session: $error');
    }
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
      final proceduralPath = await proceduralSfxPathFor(effect);
      if (proceduralPath != null) {
        await player.play(DeviceFileSource(proceduralPath));
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
