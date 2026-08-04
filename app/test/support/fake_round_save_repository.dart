import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/persistence/domain/round_save_repository.dart';
import 'package:bb_block/features/persistence/domain/saved_round.dart';

/// In-memory [RoundSaveRepository] for tests — no SharedPreferences needed.
/// Keyed like the real one: Classic Mode's two frame variants get separate
/// slots, distinct from each other and from Level Mode's single slot.
class FakeRoundSaveRepository implements RoundSaveRepository {
  final Map<String, SavedRound> _stored = {};

  String _keyFor(GameModeType mode, {bool classicHasFrame = false}) =>
      mode == GameModeType.classic
          ? 'classic_${classicHasFrame ? 'framed' : 'frameless'}'
          : mode.name;

  @override
  SavedRound? load(GameModeType mode, {bool classicHasFrame = false}) =>
      _stored[_keyFor(mode, classicHasFrame: classicHasFrame)];

  @override
  void save(SavedRound round) => _stored[_keyFor(
        round.config.mode,
        classicHasFrame: round.config.classicHasFrame,
      )] = round;

  @override
  void clear(GameModeType mode, {bool classicHasFrame = false}) =>
      _stored.remove(_keyFor(mode, classicHasFrame: classicHasFrame));
}
