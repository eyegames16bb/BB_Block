import 'package:bb_block/core/game_feel/feedback_orchestrator.dart';
import 'package:bb_block/core/game_feel/screen_shake.dart';
import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One [ScreenShakeController] per app — `GameScreen` wraps the board in a
/// `ScreenShake` widget listening to this same instance the orchestrator
/// dispatches to, so a shake request from anywhere in the game logic
/// reaches whatever's currently on screen.
final screenShakeControllerProvider = Provider<ScreenShakeController>((ref) {
  final controller = ScreenShakeController();
  ref.onDispose(controller.dispose);
  return controller;
});

final feedbackOrchestratorProvider = Provider<FeedbackOrchestrator>((ref) {
  return FeedbackOrchestrator(
    audio: ref.watch(audioServiceProvider),
    haptics: ref.watch(hapticsServiceProvider),
    screenShake: ref.watch(screenShakeControllerProvider),
  );
});
