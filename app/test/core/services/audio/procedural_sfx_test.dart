import 'dart:io';

import 'package:bb_block/core/services/audio/procedural_sfx.dart';
import 'package:bb_block/core/services/audio/sound_effect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every SoundEffect has a procedural recipe', () {
    // The Game Feel Engine (see feedback_orchestrator.dart) can emit any
    // enum value as either a primary or a layered secondary sound — if one
    // of these has no procedural recipe, it silently falls back to a still-
    // missing asset file and plays nothing.
    for (final effect in SoundEffect.values) {
      expect(
        proceduralSfxFor(effect),
        isNotNull,
        reason: '$effect has no procedural SFX recipe',
      );
    }
  });

  test('produces a well-formed mono 16-bit PCM WAV header', () {
    final bytes = proceduralSfxFor(SoundEffect.pieceSnap)!;

    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
    expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');

    // Channels (mono = 1) at byte offset 22, bits per sample (16) at 34.
    final channels = bytes[22] | (bytes[23] << 8);
    final bitsPerSample = bytes[34] | (bytes[35] << 8);
    expect(channels, 1);
    expect(bitsPerSample, 16);

    // More than just a bare header — actual sample data was written.
    expect(bytes.length, greaterThan(44));
  });

  test('repeated calls for the same effect return cached identical bytes',
      () {
    final first = proceduralSfxFor(SoundEffect.lineComplete);
    final second = proceduralSfxFor(SoundEffect.lineComplete);
    expect(identical(first, second), isTrue);
  });

  test('proceduralSfxPathFor writes a real, non-empty WAV file to disk',
      () async {
    final path = await proceduralSfxPathFor(SoundEffect.woodCrack);

    expect(path, isNotNull);
    final file = File(path!);
    expect(file.existsSync(), isTrue);
    final onDiskBytes = await file.readAsBytes();
    expect(onDiskBytes, proceduralSfxFor(SoundEffect.woodCrack));
  });

  test('proceduralSfxPathFor caches the same path across calls', () async {
    final first = await proceduralSfxPathFor(SoundEffect.invalidMove);
    final second = await proceduralSfxPathFor(SoundEffect.invalidMove);
    expect(first, second);
  });
}
