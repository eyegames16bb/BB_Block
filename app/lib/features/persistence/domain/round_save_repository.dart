import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:bb_block/features/persistence/domain/saved_round.dart';

/// Persists the round currently in progress for each game mode, separately
/// from [PlayerProgress]'s account-level `GameSaveRepository` — this is
/// deliberately synchronous (unlike that one) because `GameController.build`
/// must resume a saved round on the same synchronous pass that constructs
/// the `GameEngine`; there's no `Future` to await inside a Riverpod
/// `@riverpod` class's `build()`. The local implementation can honor this
/// because `SharedPreferences` is already fully loaded into memory by
/// `main()` before the app ever runs (see `sharedPreferencesProvider`) — a
/// future cloud-backed implementation would need a different resume
/// strategy entirely, not just an async version of this same interface.
abstract interface class RoundSaveRepository {
  /// [classicHasFrame] only matters when [mode] is `classic` — user
  /// instruction: the two Classic Mode variants (Çerçeve Var/Yok) keep
  /// fully independent in-progress rounds (as well as their already-
  /// separate `classicHighScoreFramed`/`classicHighScoreFrameless` bests),
  /// so resuming "Çerçeve Var" never touches "Çerçeve Yok"'s round or vice
  /// versa. Ignored for Level Mode, which has only one round slot.
  SavedRound? load(GameModeType mode, {bool classicHasFrame = false});

  /// Derives its own storage key from `round.config` (mode +
  /// `classicHasFrame`) — never needs the caller to pass it separately.
  void save(SavedRound round);

  void clear(GameModeType mode, {bool classicHasFrame = false});
}
