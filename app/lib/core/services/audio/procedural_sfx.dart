import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bb_block/core/services/audio/sound_effect.dart';

/// Procedurally synthesized one-shot SFX, standing in for real recorded
/// audio (none is bundled — see CLAUDE.md, and the Mixkit/Zapsplat
/// licensing concern noted there). Every sound here is pure math — sine/
/// square/noise layers with a percussive envelope, rendered to a 16-bit PCM
/// WAV in memory — the same "procedural instead of a missing asset"
/// approach `WoodBackground` already uses for the table texture.
///
/// Results are cached per [SoundEffect]: synthesis is cheap, but there's no
/// reason to redo it on every play.
final _cache = <SoundEffect, Uint8List>{};

/// Returns the synthesized WAV bytes for [effect], or `null` if this
/// effect has no procedural recipe yet (falls back to the asset path in
/// `AudioPlayersAudioService`).
Uint8List? proceduralSfxFor(SoundEffect effect) {
  final cached = _cache[effect];
  if (cached != null) return cached;

  final recipe = _recipes[effect];
  if (recipe == null) return null;

  final bytes = recipe();
  _cache[effect] = bytes;
  return bytes;
}

final _pathCache = <SoundEffect, String>{};

/// Writes [effect]'s synthesized WAV to a temp file (once, then cached) and
/// returns its path, or `null` if there's no recipe for it.
///
/// `AudioPlayersAudioService` plays this via `DeviceFileSource` rather than
/// handing the raw bytes to `BytesSource` directly: `BytesSource` is a
/// newer, far less exercised code path in `audioplayers` (it's explicitly
/// unsupported in `LOW_LATENCY`/`SoundPool` mode on Android, for instance),
/// whereas file playback is the same well-trodden path every asset/URL
/// source already uses. Since the synthesis is deterministic, writing the
/// same bytes to the same path every launch is harmless — no need to check
/// whether the file already exists.
Future<String?> proceduralSfxPathFor(SoundEffect effect) async {
  final cachedPath = _pathCache[effect];
  if (cachedPath != null) return cachedPath;

  final bytes = proceduralSfxFor(effect);
  if (bytes == null) return null;

  final file = File('${Directory.systemTemp.path}/bb_block_sfx_${effect.name}.wav');
  await file.writeAsBytes(bytes, flush: true);
  _pathCache[effect] = file.path;
  return file.path;
}

const _sampleRate = 22050;

enum _WaveType { sine, square, noise }

class _Layer {
  const _Layer({
    required this.start,
    required this.duration,
    required this.frequency,
    this.frequencyEnd,
    this.type = _WaveType.sine,
    this.amplitude = 0.6,
  });

  final double start;
  final double duration;
  final double frequency;
  final double? frequencyEnd;
  final _WaveType type;
  final double amplitude;
}

final Map<SoundEffect, Uint8List Function()> _recipes = {
  SoundEffect.invalidMove: () => _render(
        totalDuration: 0.22,
        layers: const [
          _Layer(
            start: 0,
            duration: 0.08,
            frequency: 220,
            type: _WaveType.square,
            amplitude: 0.35,
          ),
          _Layer(
            start: 0.11,
            duration: 0.08,
            frequency: 180,
            type: _WaveType.square,
            amplitude: 0.35,
          ),
        ],
      ),
  SoundEffect.pieceSnap: () => _render(
        totalDuration: 0.1,
        layers: const [
          _Layer(start: 0, duration: 0.07, frequency: 150, amplitude: 0.55),
          _Layer(
            start: 0,
            duration: 0.02,
            frequency: 0,
            type: _WaveType.noise,
            amplitude: 0.25,
          ),
        ],
      ),
  SoundEffect.pieceRotate: () => _render(
        totalDuration: 0.05,
        layers: const [
          _Layer(start: 0, duration: 0.04, frequency: 900, amplitude: 0.3),
        ],
      ),
  SoundEffect.lineComplete: () => _render(
        totalDuration: 0.34,
        layers: const [
          _Layer(start: 0, duration: 0.09, frequency: 523, amplitude: 0.5),
          _Layer(
            start: 0.08,
            duration: 0.09,
            frequency: 659,
            amplitude: 0.5,
          ),
          _Layer(
            start: 0.16,
            duration: 0.12,
            frequency: 784,
            amplitude: 0.5,
          ),
        ],
      ),
  SoundEffect.multipleLineComplete: () => _render(
        totalDuration: 0.46,
        layers: const [
          _Layer(start: 0, duration: 0.09, frequency: 523, amplitude: 0.5),
          _Layer(
            start: 0.08,
            duration: 0.09,
            frequency: 659,
            amplitude: 0.5,
          ),
          _Layer(
            start: 0.16,
            duration: 0.09,
            frequency: 784,
            amplitude: 0.5,
          ),
          _Layer(
            start: 0.24,
            duration: 0.16,
            frequency: 1046,
            amplitude: 0.55,
          ),
        ],
      ),
  SoundEffect.frameDestroy: () => _render(
        totalDuration: 0.42,
        layers: const [
          _Layer(
            start: 0,
            duration: 0.3,
            frequency: 0,
            type: _WaveType.noise,
            amplitude: 0.55,
          ),
          _Layer(
            start: 0,
            duration: 0.4,
            frequency: 220,
            frequencyEnd: 55,
            amplitude: 0.5,
          ),
        ],
      ),
  SoundEffect.boosterActivate: () => _render(
        totalDuration: 0.16,
        layers: const [
          _Layer(
            start: 0,
            duration: 0.15,
            frequency: 300,
            frequencyEnd: 900,
            amplitude: 0.4,
          ),
        ],
      ),
  SoundEffect.woodCrack: () => _render(
        totalDuration: 0.09,
        layers: const [
          _Layer(
            start: 0,
            duration: 0.05,
            frequency: 0,
            type: _WaveType.noise,
            amplitude: 0.5,
          ),
          _Layer(start: 0, duration: 0.04, frequency: 200, amplitude: 0.3),
        ],
      ),
  SoundEffect.levelComplete: () => _render(
        totalDuration: 0.56,
        layers: const [
          _Layer(start: 0, duration: 0.1, frequency: 523, amplitude: 0.5),
          _Layer(
            start: 0.09,
            duration: 0.1,
            frequency: 659,
            amplitude: 0.5,
          ),
          _Layer(
            start: 0.18,
            duration: 0.1,
            frequency: 784,
            amplitude: 0.5,
          ),
          _Layer(
            start: 0.27,
            duration: 0.1,
            frequency: 1046,
            amplitude: 0.55,
          ),
          _Layer(start: 0.36, duration: 0.2, frequency: 1318),
        ],
      ),
  SoundEffect.gameOver: () => _render(
        totalDuration: 0.62,
        layers: const [
          _Layer(start: 0, duration: 0.18, frequency: 392, amplitude: 0.5),
          _Layer(
            start: 0.15,
            duration: 0.18,
            frequency: 330,
            amplitude: 0.5,
          ),
          _Layer(
            start: 0.3,
            duration: 0.3,
            frequency: 262,
            amplitude: 0.5,
          ),
        ],
      ),
};

Uint8List _render({
  required double totalDuration,
  required List<_Layer> layers,
}) {
  final totalSamples = (totalDuration * _sampleRate).round();
  final mix = Float64List(totalSamples);

  for (final layer in layers) {
    final startSample = (layer.start * _sampleRate).round();
    final durationSamples = (layer.duration * _sampleRate).round();
    final random =
        layer.type == _WaveType.noise ? Random(durationSamples) : null;

    for (var i = 0; i < durationSamples; i++) {
      final index = startSample + i;
      if (index < 0 || index >= totalSamples) continue;

      final localTime = i / _sampleRate;
      final progress = i / durationSamples;
      final attack = (localTime / 0.005).clamp(0.0, 1.0);
      final decay = pow(1 - progress, 1.6).toDouble();
      final envelope = attack * decay;

      final frequencyEnd = layer.frequencyEnd;
      final frequency = frequencyEnd == null
          ? layer.frequency
          : layer.frequency + (frequencyEnd - layer.frequency) * progress;

      final raw = switch (layer.type) {
        _WaveType.sine => sin(2 * pi * frequency * localTime),
        _WaveType.square =>
          sin(2 * pi * frequency * localTime) >= 0 ? 1.0 : -1.0,
        _WaveType.noise => random!.nextDouble() * 2 - 1,
      };

      mix[index] += raw * layer.amplitude * envelope;
    }
  }

  var peak = 0.0;
  for (final v in mix) {
    final a = v.abs();
    if (a > peak) peak = a;
  }
  // Normalize *up* to a consistent target peak, not just down when
  // clipping — a recipe with a single quiet layer (e.g. pieceRotate's lone
  // sine at amplitude 0.3) would otherwise end up far quieter than one
  // with several stacked layers, even though both should read as
  // comparably "present" one-shot SFX.
  final scale = peak > 0 ? 0.92 / peak : 1.0;

  final samples16 = Int16List(totalSamples);
  for (var i = 0; i < totalSamples; i++) {
    samples16[i] = (mix[i] * scale * 32767).round().clamp(-32768, 32767);
  }

  return _wavBytes(samples16);
}

Uint8List _wavBytes(Int16List samples) {
  final dataLength = samples.length * 2;
  final buffer = BytesBuilder();

  void writeString(String value) => buffer.add(value.codeUnits);
  void writeUint32(int value) => buffer.add([
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ]);
  void writeUint16(int value) =>
      buffer.add([value & 0xFF, (value >> 8) & 0xFF]);

  writeString('RIFF');
  writeUint32(36 + dataLength);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(1); // mono
  writeUint32(_sampleRate);
  writeUint32(_sampleRate * 2); // byte rate: sampleRate * blockAlign
  writeUint16(2); // block align: channels * bitsPerSample/8
  writeUint16(16); // bits per sample
  writeString('data');
  writeUint32(dataLength);
  for (final sample in samples) {
    writeUint16(sample & 0xFFFF);
  }

  return buffer.toBytes();
}
