import 'dart:math';

import 'package:bb_block/core/providers/persistence_providers.dart';
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
  Future<PlayerProgress> build() =>
      ref.watch(gameSaveRepositoryProvider).load();

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

  /// Spends one Gold Key if available, for unlocking boosters on a Level
  /// Mode attempt. Returns whether it succeeded — the caller must not
  /// proceed to start a boosted attempt on `false`.
  Future<bool> spendGoldKey() async {
    final current = state.value ?? const PlayerProgress();
    if (current.goldKeyCount <= 0) return false;
    await _persist(current.copyWith(goldKeyCount: current.goldKeyCount - 1));
    return true;
  }

  Future<void> _persist(PlayerProgress progress) async {
    await ref.read(gameSaveRepositoryProvider).save(progress);
    state = AsyncData(progress);
  }
}
