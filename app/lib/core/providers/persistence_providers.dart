import 'package:bb_block/features/persistence/data/local_game_save_repository.dart';
import 'package:bb_block/features/persistence/domain/game_save_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resolved once in `main()` and injected via an override, so the rest of the
/// graph can depend on [SharedPreferences] synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

/// The persistence seam. Everything above depends on the [GameSaveRepository]
/// interface; swapping the local implementation for a cloud-backed one
/// (Supabase, later) is a single change here.
final gameSaveRepositoryProvider = Provider<GameSaveRepository>(
  (ref) => LocalGameSaveRepository(ref.watch(sharedPreferencesProvider)),
);
