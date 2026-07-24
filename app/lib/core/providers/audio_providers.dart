import 'dart:async';

import 'package:bb_block/core/services/audio/audio_service.dart';
import 'package:bb_block/core/services/audio/audioplayers_audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioPlayersAudioService();
  unawaited(service.init());
  return service;
});
