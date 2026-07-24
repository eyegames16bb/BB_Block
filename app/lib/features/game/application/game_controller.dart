import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_engine/domain/game_engine.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_engine/domain/game_session.dart';
import 'package:bb_block/features/game_mode/domain/classic_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/level_mode_strategy.dart';
import 'package:bb_block/features/piece_generation/domain/weighted_piece_generator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_controller.g.dart';

/// Bridges the pure [GameEngine] into Riverpod: it owns one engine per
/// [GameLaunchConfig], exposes the current [GameSession] as state, and
/// forwards user intents to the engine, republishing the new session after
/// each. Game rules never leak into the widget layer — widgets only read the
/// session and call these methods.
@riverpod
class GameController extends _$GameController {
  late final GameEngine _engine;

  @override
  GameSession build(GameLaunchConfig config) {
    _engine = GameEngine(
      mode: _strategyFor(config),
      generator: WeightedPieceGenerator(),
    );
    return _engine.session;
  }

  void placePiece({required int trayIndex, required GridPosition anchor}) {
    _apply(_engine.placePiece(trayIndex: trayIndex, anchor: anchor));
  }

  void rotatePiece(int trayIndex) => _apply(_engine.rotatePiece(trayIndex));

  void swapTray() => _apply(_engine.swapTray());

  void removeCell(GridPosition position) =>
      _apply(_engine.removeCell(position));

  void _apply(List<GameEvent> events) {
    state = _engine.session;
    // Extension point: audio, haptics and animation systems will consume
    // `events` here once those systems land. Today the UI is driven purely
    // by the republished session state.
  }

  GameModeStrategy _strategyFor(GameLaunchConfig config) =>
      switch (config.mode) {
        GameModeType.classic =>
          ClassicModeStrategy(hasFrame: config.classicHasFrame),
        GameModeType.level => const LevelModeStrategy(),
      };
}
