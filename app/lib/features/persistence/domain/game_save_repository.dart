import 'package:bb_block/features/persistence/domain/player_progress.dart';

/// Abstracts persistence away from the domain layer entirely — nothing above
/// this interface knows whether progress lives in local storage or a cloud
/// backend (Supabase, later). Swapping the implementation never touches
/// callers.
abstract interface class GameSaveRepository {
  Future<PlayerProgress> load();

  Future<void> save(PlayerProgress progress);
}
