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
    // The engine's live working copy of the player's booster charges for
    // this round, seeded from `PlayerProgress` by `GameController` and
    // synced back there after every use — see `GameEngine`'s doc comment.
    // Classic Mode always starts at zero (it has no boosters at all).
    @Default(0) int rotateCharges,
    @Default(0) int swapCharges,
    @Default(0) int singleCellRemoveCharges,
    // Level Mode only (user instruction): the row or column — never
    // both — marked by two star icons on opposite frame points this
    // round. Completing it once awards `LevelModeConstants.starLineBonus`
    // on top of the normal clear score — a ONE-TIME bonus (revised user
    // instruction): `GameEngine.placePiece` nulls both fields out the
    // instant it's earned, which is also what tells `BoardGrid` to animate
    // the two star icons away (the frame itself is untouched). Re-rolled
    // fresh only when a new level starts; `null` for Classic Mode, which
    // has no frame-point stars at all.
    int? starTargetRow,
    int? starTargetColumn,
  }) = _GameSession;

  const GameSession._();

  bool get isOver => outcome is! RoundOutcomeOngoing;
}
