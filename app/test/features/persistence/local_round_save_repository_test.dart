import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/persistence/data/local_round_save_repository.dart';
import 'package:bb_block/features/persistence/domain/saved_round.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_fixtures.dart';

void main() {
  test('save then load round-trips through real SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalRoundSaveRepository(prefs);

    final board = Board.empty();
    final piece = shapeById(PieceShapeId.lTriomino90);
    final round = SavedRound(
      config: const GameLaunchConfig(
        mode: GameModeType.classic,
        classicHasFrame: true,
      ),
      boardSize: board.size,
      cells: board.cells,
      tray: [SavedRoundTrayPiece.from(TrayPiece(shape: piece, isUsed: true))],
      score: 123,
      frameRemoved: false,
      rotateCharges: 2,
      swapCharges: 1,
      singleCellRemoveCharges: 0,
      starTargetRow: 4,
    );

    repo.save(round);
    final loaded = repo.load(GameModeType.classic, classicHasFrame: true);

    expect(loaded, isNotNull);
    expect(loaded!.config, round.config);
    expect(loaded.boardSize, round.boardSize);
    expect(loaded.cells, round.cells);
    expect(loaded.score, 123);
    expect(loaded.rotateCharges, 2);
    expect(loaded.tray.single.shapeId, PieceShapeId.lTriomino90);
    expect(loaded.tray.single.isUsed, isTrue);
    expect(loaded.starTargetRow, 4);
    expect(loaded.starTargetColumn, isNull);
  });

  test(
      "Classic Mode's framed and frameless variants use separate storage "
      'keys, so one never clobbers the other', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalRoundSaveRepository(prefs);
    final board = Board.empty();

    repo.save(
      SavedRound(
        config: const GameLaunchConfig(
          mode: GameModeType.classic,
          classicHasFrame: true,
        ),
        boardSize: board.size,
        cells: board.cells,
        tray: const [],
        score: 10,
        frameRemoved: false,
        rotateCharges: 0,
        swapCharges: 0,
        singleCellRemoveCharges: 0,
      ),
    );
    repo.save(
      SavedRound(
        config: const GameLaunchConfig(mode: GameModeType.classic),
        boardSize: board.size,
        cells: board.cells,
        tray: const [],
        score: 20,
        frameRemoved: false,
        rotateCharges: 0,
        swapCharges: 0,
        singleCellRemoveCharges: 0,
      ),
    );

    expect(
      repo.load(GameModeType.classic, classicHasFrame: true)!.score,
      10,
    );
    expect(repo.load(GameModeType.classic)!.score, 20);
  });

  test('a mode with nothing saved returns null', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalRoundSaveRepository(prefs);

    expect(repo.load(GameModeType.level), isNull);
  });

  test("clearing removes only that mode's saved round", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalRoundSaveRepository(prefs);
    final board = Board.empty();

    repo.save(
      SavedRound(
        config: const GameLaunchConfig(mode: GameModeType.classic),
        boardSize: board.size,
        cells: board.cells,
        tray: const [],
        score: 5,
        frameRemoved: false,
        rotateCharges: 0,
        swapCharges: 0,
        singleCellRemoveCharges: 0,
      ),
    );
    repo.save(
      SavedRound(
        config: const GameLaunchConfig(mode: GameModeType.level),
        boardSize: board.size,
        cells: board.cells,
        tray: const [],
        score: 7,
        frameRemoved: false,
        rotateCharges: 0,
        swapCharges: 0,
        singleCellRemoveCharges: 0,
      ),
    );

    repo.clear(GameModeType.classic);

    expect(repo.load(GameModeType.classic), isNull);
    expect(repo.load(GameModeType.level), isNotNull);
  });
}
