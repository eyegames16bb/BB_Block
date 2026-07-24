import 'dart:async';

import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/game/application/game_audio.dart';
import 'package:bb_block/features/game/application/game_haptics.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_engine/domain/game_engine.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_engine/domain/game_session.dart';
import 'package:bb_block/features/game_mode/domain/classic_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/level_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/piece_generation/domain/weighted_piece_generator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_controller.g.dart';

/// Bridges the pure [GameEngine] into Riverpod: it owns one engine per
/// [GameLaunchConfig], exposes the current [GameSession] as state, and
/// forwards user intents to the engine, republishing the new session after
/// each. Game rules never leak into the widget layer — widgets only read the
/// session and call these methods.
@riverpod
class GameController extends _$GameController {
  late final GameEngine _engine;
  late final GameLaunchConfig _config;

  @override
  GameSession build(GameLaunchConfig config) {
    _config = config;
    // Level Mode boosters are a persistent, account-level resource (see
    // `PlayerProgress`) — every fresh engine (including a retry) starts from
    // whatever the player currently owns, not a fixed per-attempt default.
    // Classic Mode never has boosters, so it never touches this provider —
    // callers (HomeScreen) are responsible for making sure PlayerProgress
    // has actually finished loading before a Level Mode config reaches here.
    final isLevel = config.mode == GameModeType.level;
    final progress = isLevel
        ? (ref.read(playerProgressControllerProvider).value ??
            const PlayerProgress())
        : null;
    _engine = GameEngine(
      mode: _strategyFor(config),
      generator: WeightedPieceGenerator(),
      initialRotateCharges: progress?.rotateCharges ?? 0,
      initialSwapCharges: progress?.swapCharges ?? 0,
      initialSingleCellRemoveCharges: progress?.singleCellRemoveCharges ?? 0,
    );
    return _engine.session;
  }

  void placePiece({required int trayIndex, required GridPosition anchor}) {
    _apply(_engine.placePiece(trayIndex: trayIndex, anchor: anchor));
  }

  void rotatePiece(int trayIndex) => _apply(_engine.rotatePiece(trayIndex));

  void swapTray() => _apply(_engine.swapTray());

  void removeCell(GridPosition position) =>
      _apply(_engine.removeCell(position));

  void _apply(List<GameEvent> events) {
    final previousScore = state.score;
    state = _engine.session;

    // Classic Mode has no natural "end of round" that always fires (the
    // player can quit mid-round), so the high score is persisted the moment
    // it's actually beaten rather than only at game-over — see
    // `_RecordBadge` in game_screen.dart for the matching live display.
    if (_config.mode == GameModeType.classic && state.score > previousScore) {
      unawaited(
        ref.read(playerProgressControllerProvider.notifier).recordClassicScore(
              hasFrame: _config.classicHasFrame,
              score: state.score,
            ),
      );
    }

    if (events.any(_isBoosterUseEvent)) {
      unawaited(
        ref.read(playerProgressControllerProvider.notifier).syncBoosterCharges(
              rotate: state.rotateCharges,
              swap: state.swapCharges,
              singleCellRemove: state.singleCellRemoveCharges,
            ),
      );
    }

    if (events.any((event) => event is GameEventRoundEnded)) {
      _recordOutcome();
    }
    _triggerHaptics(events);
    _triggerAudio(events);
    // Extension point: the animation system will consume `events` here
    // once it lands.
  }

  bool _isBoosterUseEvent(GameEvent event) =>
      event is GameEventPieceRotated ||
      event is GameEventTraySwapped ||
      event is GameEventCellRemoved;

  void _triggerHaptics(List<GameEvent> events) {
    final haptics = ref.read(hapticsServiceProvider);
    for (final event in events) {
      final intensity = hapticIntensityFor(event);
      if (intensity != null) unawaited(haptics.trigger(intensity));
    }
  }

  void _triggerAudio(List<GameEvent> events) {
    final audio = ref.read(audioServiceProvider);
    for (final event in events) {
      final effect = soundEffectFor(event);
      if (effect != null) unawaited(audio.playEffect(effect));
    }
  }

  void _recordOutcome() {
    final progress = ref.read(playerProgressControllerProvider.notifier);
    final session = _engine.session;
    switch (session.outcome) {
      // Classic Mode's score is already persisted continuously in _apply as
      // it's earned, so there's nothing left to do here for it.
      case RoundOutcomeClassicGameOver():
        break;
      case RoundOutcomeLevelComplete():
        unawaited(progress.advanceLevel());
      case RoundOutcomeLevelFailed():
      case RoundOutcomeOngoing():
        break;
    }
  }

  GameModeStrategy _strategyFor(GameLaunchConfig config) =>
      switch (config.mode) {
        GameModeType.classic =>
          ClassicModeStrategy(hasFrame: config.classicHasFrame),
        GameModeType.level => const LevelModeStrategy(),
      };
}
