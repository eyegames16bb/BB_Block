import 'package:bb_block/core/constants/app_constants.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_progress.freezed.dart';
part 'player_progress.g.dart';

/// Account-level progress. Booster charges are deliberately *not* stored
/// here — they're an attempt-scoped resource now, not a persistent one: at
/// the start of each Level Mode round the player either spends one Gold Key
/// for one charge of every booster that round only, or plays with none
/// (see `HomeScreen`'s start sheet and `GameLaunchConfig.
/// levelBoostersUnlocked`). Unused charges are lost at round end and
/// nothing mid-round can add more. Classic Mode never has boosters at all.
@freezed
abstract class PlayerProgress with _$PlayerProgress {
  const factory PlayerProgress({
    @Default(0) int classicHighScoreFramed,
    @Default(0) int classicHighScoreFrameless,
    @Default(1) int currentLevel,
    @Default(GoldKeyConstants.startingGoldKeyCount) int goldKeyCount,
    @Default(true) bool soundEnabled,
    @Default(true) bool hapticsEnabled,
    // The already-resolved Gold Key choice for the Level Mode attempt in
    // progress at `currentLevel` — `null` means no choice has been locked
    // in yet for this level (the start sheet must ask). Once set, it stays
    // locked until the level is actually completed (currentLevel advances)
    // — a failed attempt at the same level reuses it without re-asking or
    // re-spending a key. See HomeScreen._startLevel and CLAUDE.md.
    int? pendingLevelChoiceLevel,
    @Default(false) bool pendingLevelBoostersUnlocked,
    // 'tr' or 'en' — the game's UI language (user instruction: full TR/EN
    // support). Defaults to 'tr' since the game's content/GDD is
    // Turkish-first.
    @Default('tr') String languageCode,
    // Gates the first-launch interactive tutorial (user instruction) — the
    // app's startup route shows the tutorial instead of the home menu until
    // this is true. Only ever set once by finishing (or skipping) the
    // tutorial; a fresh install has this false again since it's the same
    // local save blob everything else here lives in.
    @Default(false) bool tutorialCompleted,
    // Classic Mode's board size, now a persistent Settings choice instead of
    // an every-launch sheet (user instruction) — `true` (8x8, framed) is the
    // default for a fresh install. `HomeScreen._startClassic` reads this
    // directly instead of asking.
    @Default(true) bool classicHasFrame,
    // Toggles the mode-specific footer note shown at the bottom-left of the
    // in-game panel (user instruction: "Açıklama Notları") — on by default.
    @Default(true) bool showModeNotesEnabled,
    // Level Mode's booster charges are now a persistent, per-player ledger
    // (user instruction, revised again — previously attempt-scoped) instead
    // of being reseeded every round: only a brand-new install starts here
    // (level 1) at 3/1/1, and from then on whatever's left over (or bought
    // via the empty-booster refill sheet) carries straight into the next
    // level. `GameController` reads these to seed a fresh round and writes
    // them back after every change; Classic Mode never touches these.
    @Default(3) int levelRotateCharges,
    @Default(1) int levelSwapCharges,
    @Default(1) int levelSingleCellRemoveCharges,
  }) = _PlayerProgress;

  factory PlayerProgress.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressFromJson(json);
}
