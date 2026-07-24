import 'dart:math';

import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/features/booster/domain/booster_kind.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_progress_controller.g.dart';

/// Loads the persisted [PlayerProgress] and applies the mutations the game
/// produces (new high scores, level advancement), writing each change back
/// through the [gameSaveRepositoryProvider]. This is the only place that
/// decides *what a new best is*; callers just report raw results.
@riverpod
class PlayerProgressController extends _$PlayerProgressController {
  @override
  Future<PlayerProgress> build() async {
    final progress = await ref.watch(gameSaveRepositoryProvider).load();
    // Apply the persisted sound/haptics preference to the services as soon
    // as progress loads, so a saved "muted" choice actually takes effect on
    // startup rather than only after the next toggle.
    ref.read(audioServiceProvider).setMuted(muted: !progress.soundEnabled);
    ref
        .read(hapticsServiceProvider)
        .setMuted(muted: !progress.hapticsEnabled);
    return progress;
  }

  Future<void> setSoundEnabled({required bool enabled}) async {
    final current = state.value ?? const PlayerProgress();
    ref.read(audioServiceProvider).setMuted(muted: !enabled);
    await _persist(current.copyWith(soundEnabled: enabled));
  }

  Future<void> setHapticsEnabled({required bool enabled}) async {
    final current = state.value ?? const PlayerProgress();
    ref.read(hapticsServiceProvider).setMuted(muted: !enabled);
    await _persist(current.copyWith(hapticsEnabled: enabled));
  }

  Future<void> recordClassicScore({
    required bool hasFrame,
    required int score,
  }) async {
    final current = state.value ?? const PlayerProgress();
    final updated = hasFrame
        ? current.copyWith(
            classicHighScoreFramed:
                max(current.classicHighScoreFramed, score),
          )
        : current.copyWith(
            classicHighScoreFrameless:
                max(current.classicHighScoreFrameless, score),
          );
    await _persist(updated);
  }

  Future<void> advanceLevel() async {
    final current = state.value ?? const PlayerProgress();
    await _persist(current.copyWith(currentLevel: current.currentLevel + 1));
  }

  /// Rewarded-ad payout. The actual ad SDK isn't wired up yet (see
  /// `AdMobAdsService`) — callers currently invoke this the moment a
  /// simulated ad view completes.
  Future<void> grantGoldKey() async {
    final current = state.value ?? const PlayerProgress();
    await _persist(
      current.copyWith(goldKeyCount: current.goldKeyCount + 1),
    );
  }

  /// Writes back the booster charges a `GameEngine` is holding for the
  /// current round, right after a booster is actually used — not just at
  /// round end — so a charge spent mid-round survives the player quitting
  /// before the round naturally finishes.
  Future<void> syncBoosterCharges({
    required int rotate,
    required int swap,
    required int singleCellRemove,
  }) async {
    final current = state.value ?? const PlayerProgress();
    await _persist(
      current.copyWith(
        rotateCharges: rotate,
        swapCharges: swap,
        singleCellRemoveCharges: singleCellRemove,
      ),
    );
  }

  /// Spends one Gold Key to add one charge of the chosen [kind]. Returns
  /// whether it succeeded — the caller must not treat the booster as
  /// refilled on `false`.
  Future<bool> refillBooster(BoosterKind kind) async {
    final current = state.value ?? const PlayerProgress();
    if (current.goldKeyCount <= 0) return false;

    final refilled = switch (kind) {
      BoosterKind.rotate =>
        current.copyWith(rotateCharges: current.rotateCharges + 1),
      BoosterKind.swap =>
        current.copyWith(swapCharges: current.swapCharges + 1),
      BoosterKind.singleCellRemove => current.copyWith(
          singleCellRemoveCharges: current.singleCellRemoveCharges + 1,
        ),
    };
    await _persist(refilled.copyWith(goldKeyCount: current.goldKeyCount - 1));
    return true;
  }

  Future<void> _persist(PlayerProgress progress) async {
    await ref.read(gameSaveRepositoryProvider).save(progress);
    state = AsyncData(progress);
  }
}
