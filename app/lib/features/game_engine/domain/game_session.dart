import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_session.freezed.dart';

/// The complete, immutable snapshot of a single game in progress. Everything
/// the UI needs to render a frame lives here; the `GameEngine` replaces it
/// wholesale on every move. Behaviour (scoring, mode rules) is deliberately
/// *not* stored here — it lives in the strategies the engine holds — so the
/// session stays a plain, serializable value object.
@freezed
abstract class GameSession with _$GameSession {
  const factory GameSession({
    required Board board,
    required List<TrayPiece> tray,
    required int score,
    required GameModeType mode,
    required RoundOutcome outcome,
    @Default(false) bool frameRemoved,
    // Booster charges for *this attempt only*. Classic Mode always starts
    // at zero (it has no boosters at all, per the GDD); an unlocked Level
    // Mode attempt starts at `BoosterConstants` defaults and resets to
    // those defaults again on every retry — see `GameEngine.boostersEnabled`.
    @Default(0) int rotateCharges,
    @Default(0) int swapCharges,
    @Default(0) int singleCellRemoveCharges,
  }) = _GameSession;

  const GameSession._();

  bool get isOver => outcome is! RoundOutcomeOngoing;
}
