import 'dart:async';
import 'dart:convert';

import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/persistence/domain/round_save_repository.dart';
import 'package:bb_block/features/persistence/domain/saved_round.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One JSON blob per mode — `'saved_round_level'`, and, since Classic
/// Mode's Çerçeve Var/Yok variants keep fully independent rounds (user
/// instruction), `'saved_round_classic_framed'`/
/// `'saved_round_classic_frameless'` — so resuming any one of the three
/// never clobbers the other two.
final class LocalRoundSaveRepository implements RoundSaveRepository {
  const LocalRoundSaveRepository(this._preferences);

  final SharedPreferences _preferences;

  String _keyFor(GameModeType mode, {bool classicHasFrame = false}) {
    if (mode == GameModeType.classic) {
      return 'saved_round_classic_${classicHasFrame ? 'framed' : 'frameless'}';
    }
    return 'saved_round_${mode.name}';
  }

  @override
  SavedRound? load(GameModeType mode, {bool classicHasFrame = false}) {
    final raw = _preferences.getString(
      _keyFor(mode, classicHasFrame: classicHasFrame),
    );
    if (raw == null) return null;
    return SavedRound.tryFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  void save(SavedRound round) {
    unawaited(
      _preferences.setString(
        _keyFor(
          round.config.mode,
          classicHasFrame: round.config.classicHasFrame,
        ),
        jsonEncode(round.toJson()),
      ),
    );
  }

  @override
  void clear(GameModeType mode, {bool classicHasFrame = false}) {
    unawaited(
      _preferences.remove(_keyFor(mode, classicHasFrame: classicHasFrame)),
    );
  }
}
