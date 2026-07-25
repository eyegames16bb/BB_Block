import 'dart:math';

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
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
  // Every mutator below does read-`state.value`-then-write, so two calls
  // racing (e.g. a double-tapped refill button) could both read the same
  // stale `goldKeyCount` and both succeed — spending one key for two
  // charges. This queue forces every mutation to wait for the previous
  // one's write to actually land before it reads `state.value`, so each
  // one always builds on the true latest state.
  Future<void> _writeQueue = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() mutate) {
    final result = _writeQueue.then((_) => mutate());
    _writeQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

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

  Future<void> setSoundEnabled({required bool enabled}) => _serialized(
        () async {
          final current = state.value ?? const PlayerProgress();
          ref.read(audioServiceProvider).setMuted(muted: !enabled);
          await _persist(current.copyWith(soundEnabled: enabled));
        },
      );

  Future<void> setHapticsEnabled({required bool enabled}) => _serialized(
        () async {
          final current = state.value ?? const PlayerProgress();
          ref.read(hapticsServiceProvider).setMuted(muted: !enabled);
          await _persist(current.copyWith(hapticsEnabled: enabled));
        },
      );

  Future<void> recordClassicScore({
    required bool hasFrame,
    required int score,
  }) =>
      _serialized(() async {
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
      });

  /// Advances to the next level and, every
  /// [GoldKeyConstants.levelsPerGoldKeyReward] completed levels, grants a
  /// free Gold Key — a milestone bonus on top of the ad-based way to earn
  /// them. `currentLevel` starts at 1, so the number of levels *completed*
  /// so far is `newLevel - 1`.
  Future<void> advanceLevel() => _serialized(() async {
        final current = state.value ?? const PlayerProgress();
        final newLevel = current.currentLevel + 1;
        final completedLevels = newLevel - 1;
        final earnsGoldKey =
            completedLevels % GoldKeyConstants.levelsPerGoldKeyReward == 0;
        await _persist(
          current.copyWith(
            currentLevel: newLevel,
            goldKeyCount: earnsGoldKey
                ? current.goldKeyCount + 1
                : current.goldKeyCount,
          ),
        );
      });

  /// Rewarded-ad payout. The actual ad SDK isn't wired up yet (see
  /// `AdMobAdsService`) — callers currently invoke this the moment a
  /// simulated ad view completes.
  Future<void> grantGoldKey() => _serialized(() async {
        final current = state.value ?? const PlayerProgress();
        await _persist(
          current.copyWith(goldKeyCount: current.goldKeyCount + 1),
        );
      });

  /// Spends one Gold Key to unlock boosters for the Level Mode round about
  /// to start (one charge of each — see `GameLaunchConfig.
  /// levelBoostersUnlocked` and `PlayerProgress`'s doc comment). Returns
  /// whether it succeeded; the caller must not start the round as
  /// "unlocked" on `false`. Serialized like every other mutator here so two
  /// rapid taps can't both read the same pre-spend `goldKeyCount` and both
  /// succeed off a single key.
  Future<bool> spendGoldKeyForBoosters() => _serialized(() async {
        final current = state.value ?? const PlayerProgress();
        if (current.goldKeyCount <= 0) return false;
        await _persist(
          current.copyWith(goldKeyCount: current.goldKeyCount - 1),
        );
        return true;
      });

  Future<void> _persist(PlayerProgress progress) async {
    await ref.read(gameSaveRepositoryProvider).save(progress);
    state = AsyncData(progress);
  }
}
