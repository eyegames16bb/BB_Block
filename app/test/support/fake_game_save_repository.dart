import 'package:bb_block/features/persistence/domain/game_save_repository.dart';
import 'package:bb_block/features/persistence/domain/player_progress.dart';

/// In-memory [GameSaveRepository] for tests — no SharedPreferences needed.
class FakeGameSaveRepository implements GameSaveRepository {
  FakeGameSaveRepository([this._stored = const PlayerProgress()]);

  PlayerProgress _stored;

  @override
  Future<PlayerProgress> load() async => _stored;

  @override
  Future<void> save(PlayerProgress progress) async => _stored = progress;
}
