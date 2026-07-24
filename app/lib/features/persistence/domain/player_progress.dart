import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_progress.freezed.dart';
part 'player_progress.g.dart';

/// Account-level progress only. Booster charges are *not* here — they reset
/// every Level Mode attempt and live in `GameSession` instead; see
/// `GameEngine`'s doc comment for why.
@freezed
abstract class PlayerProgress with _$PlayerProgress {
  const factory PlayerProgress({
    @Default(0) int classicHighScoreFramed,
    @Default(0) int classicHighScoreFrameless,
    @Default(1) int currentLevel,
    @Default(0) int goldKeyCount,
    @Default(true) bool soundEnabled,
    @Default(true) bool hapticsEnabled,
  }) = _PlayerProgress;

  factory PlayerProgress.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressFromJson(json);
}
