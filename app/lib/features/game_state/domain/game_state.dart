import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';

@freezed
sealed class GameState with _$GameState {
  const factory GameState.mainMenu() = GameStateMainMenu;
  const factory GameState.modeSelect() = GameStateModeSelect;
  const factory GameState.playing() = GameStatePlaying;
  const factory GameState.paused() = GameStatePaused;
  const factory GameState.classicGameOver() = GameStateClassicGameOver;
  const factory GameState.levelFailed() = GameStateLevelFailed;
  const factory GameState.levelComplete() = GameStateLevelComplete;
}
