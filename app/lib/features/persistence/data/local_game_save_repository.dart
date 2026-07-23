import 'dart:convert';

import 'package:bb_block/features/persistence/domain/game_save_repository.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// v1 storage: a single JSON blob in [SharedPreferences]. This game's saved
/// state is small (a handful of counters), so a full embedded database
/// (Isar/Hive) is unnecessary complexity for now — the [GameSaveRepository]
/// interface makes swapping to one, or to Supabase, a data-layer-only change.
final class LocalGameSaveRepository implements GameSaveRepository {
  const LocalGameSaveRepository(this._preferences);

  final SharedPreferences _preferences;

  static const String _storageKey = 'player_progress';

  @override
  Future<PlayerProgress> load() async {
    final raw = _preferences.getString(_storageKey);
    if (raw == null) return const PlayerProgress();
    return PlayerProgress.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> save(PlayerProgress progress) async {
    await _preferences.setString(_storageKey, jsonEncode(progress.toJson()));
  }
}
