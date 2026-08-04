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
  }) = _PlayerProgress;

  factory PlayerProgress.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressFromJson(json);
}
