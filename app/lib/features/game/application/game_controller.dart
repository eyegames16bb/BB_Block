import 'dart:async';

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/game_feel_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
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
import 'package:bb_block/features/persistence/domain/saved_round.dart';
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
  // Deliberately `late`, not `late final` — a real bug found while fixing
  // "Tekrar Oyna doesn't work" (user report): `ref.invalidate` on a
  // provider that's still actively watched (as `GameScreen`'s `ref.watch`
  // always is here) makes Riverpod call `build()` again on this *same*
  // Notifier instance rather than constructing a fresh one — it only
  // creates a new instance once every listener has gone away and the
  // provider is torn down. With `late final`, that second `build()` call
  // threw a `LateInitializationError` trying to reassign `_config`/
  // `_engine`, which silently killed the rebuild — the round-over overlay
  // never dismissed and no fresh round ever appeared, exactly matching the
  // "tapping Play Again does nothing" report. Plain `late` allows the
  // second assignment, so a re-`build()` genuinely starts over.
  late GameEngine _engine;
  late GameLaunchConfig _config;

  @override
  GameSession build(GameLaunchConfig config) {
    // A round already saved for this mode+variant (the app was closed
    // mid-game, not just backgrounded — see `RoundSaveRepository`'s doc
    // comment) always wins over a fresh start. `HomeScreen._startLevel`
    // already checks for this before navigating here and skips its choice
    // sheet entirely; `_startClassic` deliberately does NOT skip its own
    // Çerçeve Var/Yok sheet (user instruction — that choice is always
    // asked), but once made it resumes whichever variant's round (if any)
    // was saved for it. Either way the check is repeated here too so this
    // provider is correct even if ever built a different way. The saved
    // round's own `config` — not whatever was passed in — becomes the
    // source of truth for the rest of this round, since it's what the
    // engine actually resumes.
    final saved = ref.read(roundSaveRepositoryProvider).load(
          config.mode,
          classicHasFrame: config.classicHasFrame,
        );
    if (saved != null) {
      _config = saved.config;
      _engine = GameEngine(
        mode: _strategyFor(saved.config),
        generator: WeightedPieceGenerator(),
        initialBoard: saved.toBoard(),
        initialTray: saved.toTrayPieces(),
        initialScore: saved.score,
        initialFrameRemoved: saved.frameRemoved,
        initialRotateCharges: saved.rotateCharges,
        initialSwapCharges: saved.swapCharges,
        initialSingleCellRemoveCharges: saved.singleCellRemoveCharges,
        initialStarTargetRow: saved.starTargetRow,
        initialStarTargetColumn: saved.starTargetColumn,
      );
      return _engine.session;
    }

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
    // Saved the instant the round exists, not just after the first move —
    // an app kill before any placement would otherwise resume into nothing.
    _persistRound();
    return _engine.session;
  }

  void placePiece({required int trayIndex, required GridPosition anchor}) {
    _apply(_engine.placePiece(trayIndex: trayIndex, anchor: anchor));
  }

  void rotateTray() => _apply(_engine.rotateTray());

  void swapTray() => _apply(_engine.swapTray());

  void removeCell(GridPosition position) =>
      _apply(_engine.removeCell(position));

  /// Classic Mode only: spends a Gold Key to revive a round that just ended
  /// in "no valid move" — user instruction, offered alongside the existing
  /// "Play Again"/"Main Menu" options in `GameScreen`'s round-over overlay.
  /// A no-op (and no key spent) if the round isn't actually in that state,
  /// or if the player has no Gold Key to spend.
  Future<void> continueWithGoldKey() async {
    if (_engine.session.outcome is! RoundOutcomeClassicGameOver) return;
    final spent = await ref
        .read(playerProgressControllerProvider.notifier)
        .spendGoldKeyToContinueRound();
    if (!spent) return;
    _apply(_engine.continueRoundWithFreshTray());
  }

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

    // The saved round is the single source of truth for "resume where I
    // left off" — it tracks whatever the engine's actual outcome is right
    // now, not just the events of this one turn, so a revived round (via
    // `continueWithGoldKey`) is saved fresh again instead of staying
    // cleared.
    if (_engine.session.isOver) {
      ref.read(roundSaveRepositoryProvider).clear(
            _config.mode,
            classicHasFrame: _config.classicHasFrame,
          );
    } else {
      _persistRound();
    }

    if (events.any((event) => event is GameEventRoundEnded)) {
      _recordOutcome();
    }
    events.forEach(ref.read(feedbackOrchestratorProvider).play);
  }

  void _persistRound() {
    ref.read(roundSaveRepositoryProvider).save(
          SavedRound.fromSession(config: _config, session: _engine.session),
        );
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
