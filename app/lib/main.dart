import 'package:audioplayers/audioplayers.dart';
import 'package:bb_block/app.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  // Bug fix (user report, marked critical: the game's very first sound
  // effect was stopping/pausing whatever background audio — music from
  // another app — was already playing). This MUST run before any
  // `AudioPlayer` is constructed, or it's too late: `audioplayers`
  // resolves each player's audio session/focus configuration from this
  // *global* context at the moment the player is created, not when it
  // first plays — and `AudioPlayersAudioService`'s whole pooled-player
  // set is built in its constructor, which Riverpod can trigger as early
  // as the first frame (via `PlayerProgressController.build()` reading
  // `audioServiceProvider`). Setting it here, before `runApp`, guarantees
  // it's in effect for every player the app ever creates — doing it
  // inside `AudioPlayersAudioService.init()` instead (the first, and
  // insufficient, attempt at this same fix) was too late for the pooled
  // players it had *already* constructed in its own constructor just
  // beforehand.
  try {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    );
  } on Object catch (error) {
    appLogger.w('Could not configure global audio session: $error');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const BbBlockApp(),
    ),
  );
}
