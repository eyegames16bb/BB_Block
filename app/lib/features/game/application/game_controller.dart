import 'dart:async';

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/game_feel_providers.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_engine/domain/game_engine.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_engine/domain/game_session.dart';
import 'package:bb_block/features/game_mode/domain/classic_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/level_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
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
    // Booster charges are attempt-scoped now, not a persistent resource
    // (see `PlayerProgress`'s doc comment): unlocked means one charge of
    // every booster for this round only, seeded straight from the choice
    // made at `HomeScreen`'s start sheet — never read back from
    // `PlayerProgress`, and never written back to it either.
    final unlocked =
        config.mode == GameModeType.level && config.levelBoostersUnlocked;
    final charges = unlocked ? BoosterConstants.unlockedChargesPerRound : 0;
    _engine = GameEngine(
      mode: _strategyFor(config),
      generator: WeightedPieceGenerator(),
      initialRotateCharges: charges,
      initialSwapCharges: charges,
      initialSingleCellRemoveCharges: charges,
    );
    return _engine.session;
  }

  void placePiece({required int trayIndex, required GridPosition anchor}) {
    _apply(_engine.placePiece(trayIndex: trayIndex, anchor: anchor));
  }

  void rotateTray() => _apply(_engine.rotateTray());

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

    if (events.any((event) => event is GameEventRoundEnded)) {
      _recordOutcome();
    }
    events.forEach(ref.read(feedbackOrchestratorProvider).play);
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
