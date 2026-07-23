import 'package:freezed_annotation/freezed_annotation.dart';

part 'round_outcome.freezed.dart';

@freezed
sealed class RoundOutcome with _$RoundOutcome {
  const factory RoundOutcome.ongoing() = RoundOutcomeOngoing;
  const factory RoundOutcome.classicGameOver() = RoundOutcomeClassicGameOver;
  const factory RoundOutcome.levelFailed() = RoundOutcomeLevelFailed;
  const factory RoundOutcome.levelComplete() = RoundOutcomeLevelComplete;
}
