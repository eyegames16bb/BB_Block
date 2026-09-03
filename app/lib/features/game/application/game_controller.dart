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
import 'package:bb_block/features/persistence/domain/player_progress.dart';
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
    // Booster charges are a persistent, per-player ledger shared by *both*
    // modes now (user instruction, revised again — previously Level Mode
    // only) — a brand-new install starts at PlayerProgress's own defaults
    // (3/1/1), and every subsequent round, Classic or Level, continues from
    // wherever the last one left off (see
    // `PlayerProgress.levelRotateCharges`'s doc comment and `_apply`, which
    // writes this ledger back after every change in either mode).
    final progress = ref.read(playerProgressControllerProvider).value ??
        const PlayerProgress();
    _engine = GameEngine(
      mode: _strategyFor(config),
      generator: WeightedPieceGenerator(),
      initialRotateCharges: progress.levelRotateCharges,
      initialSwapCharges: progress.levelSwapCharges,
      initialSingleCellRemoveCharges: progress.levelSingleCellRemoveCharges,
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

  /// Level Mode only: spends [GoldKeyConstants.actionCostCoins] to add a
  /// fresh batch of Rotate charges — one of three separate purchase entry
  /// points (user instruction: each booster is bought on its own, not all
  /// three together), offered only once Rotate itself reaches zero. A no-op
  /// (and no coins spent) if the balance is insufficient.
  Future<void> purchaseRotateBoosters() =>
      _purchaseBooster(_engine.refillRotateBoosters);

  /// Same as [purchaseRotateBoosters], for Swap.
  Future<void> purchaseSwapBoosters() =>
      _purchaseBooster(_engine.refillSwapBoosters);

  /// Same as [purchaseRotateBoosters], for Single Cell Remove.
  Future<void> purchaseSingleCellRemoveBoosters() =>
      _purchaseBooster(_engine.refillSingleCellRemoveBoosters);

  Future<void> _purchaseBooster(List<GameEvent> Function() apply) async {
    final spent = await ref
        .read(playerProgressControllerProvider.notifier)
        .spendGoldKeyForBoosters();
    if (!spent) return;
    _apply(apply());
  }

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

    // The booster ledger is persistent and shared by both modes now (see
    // `PlayerProgress`'s doc comment) — every change (a use or a purchase,
    // in either Classic or Level) is written straight back so the next
    // round, whatever mode it's in, resumes from exactly wherever this one
    // left off.
    unawaited(
      ref
          .read(playerProgressControllerProvider.notifier)
          .syncLevelBoosterCharges(
            rotate: state.rotateCharges,
            swap: state.swapCharges,
            singleCellRemove: state.singleCellRemoveCharges,
          ),
    );

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
