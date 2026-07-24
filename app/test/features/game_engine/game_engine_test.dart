import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game_engine/domain/game_engine.dart';
import 'package:bb_block/features/game_engine/domain/game_event.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_fixtures.dart';

void main() {
  final single = shapeById(PieceShapeId.single);
  final horizontalDomino = shapeById(PieceShapeId.dominoHorizontal);
  final verticalDomino = shapeById(PieceShapeId.dominoVertical);

  GameEngine engineOn(
    Board board, {
    List<List<PieceShape>>? script,
    int pointsPerLine = 10,
    int? frameThreshold,
    bool boostersEnabled = true,
  }) {
    return GameEngine(
      mode: FakeModeStrategy(
        initialBoard: board,
        pointsPerLine: pointsPerLine,
        frameThreshold: frameThreshold,
      ),
      generator: ScriptedPieceGenerator(
        script ?? [List.filled(3, single)],
      ),
      boostersEnabled: boostersEnabled,
    );
  }

  group('initial session', () {
    test('starts ongoing with a full tray drawn from the generator', () {
      final engine = engineOn(Board.empty());

      expect(engine.session.outcome, const RoundOutcome.ongoing());
      expect(engine.session.tray.length, 3);
      expect(engine.session.tray.every((piece) => piece.isUsed), isFalse);
      expect(engine.session.score, 0);
    });
  });

  group('placePiece', () {
    test('places a piece and scores one point per cell', () {
      final engine = engineOn(Board.empty());

      final events = engine.placePiece(
        trayIndex: 0,
        anchor: const GridPosition(row: 4, column: 4),
      );

      expect(events, [const GameEvent.piecePlaced(placementPoints: 1)]);
      expect(engine.session.score, 1);
      expect(
        engine.session.board.cellAt(const GridPosition(row: 4, column: 4)),
        CellState.filled,
      );
      expect(engine.session.tray[0].isUsed, isTrue);
    });

    test('rejects an invalid placement without changing state', () {
      final engine = engineOn(
        boardFromRows([
          'X..',
          '...',
          '...',
        ]),
        script: [
          [single, single, single],
        ],
      );

      final events = engine.placePiece(
        trayIndex: 0,
        anchor: const GridPosition(row: 0, column: 0),
      );

      expect(events, [const GameEvent.invalidMove()]);
      expect(engine.session.score, 0);
      expect(engine.session.tray[0].isUsed, isFalse);
    });

    test('completing a line clears it and adds line points', () {
      // Row 8 is one cell short; dropping a single at (8,8) completes it.
      final rows = [
        for (var r = 0; r < 9; r++)
          if (r == 8) 'XXXXXXXX.' else '.........',
      ];
      final engine = engineOn(
        boardFromRows(rows),
        pointsPerLine: 9,
        script: [
          [single, single, single],
        ],
      );

      final events = engine.placePiece(
        trayIndex: 0,
        anchor: const GridPosition(row: 8, column: 8),
      );

      expect(
        events,
        containsAllInOrder(<GameEvent>[
          const GameEvent.piecePlaced(placementPoints: 1),
          const GameEvent.linesCleared(
            rows: [8],
            columns: [],
            linePoints: 9,
          ),
        ]),
      );
      // 1 placement point + 9 line points.
      expect(engine.session.score, 10);
      // The completed row is now empty again.
      expect(
        engine.session.board.cellAt(const GridPosition(row: 8, column: 0)),
        CellState.empty,
      );
    });

    test('refills the tray only once all three pieces are used', () {
      final engine = engineOn(
        Board.empty(),
        script: [
          [single, single, single],
          [single, single, single],
        ],
      );

      engine.placePiece(
        trayIndex: 0,
        anchor: const GridPosition(row: 0, column: 0),
      );
      engine.placePiece(
        trayIndex: 1,
        anchor: const GridPosition(row: 0, column: 2),
      );
      final thirdEvents = engine.placePiece(
        trayIndex: 2,
        anchor: const GridPosition(row: 2, column: 0),
      );

      expect(thirdEvents, contains(const GameEvent.trayRefilled()));
      expect(engine.session.tray.length, 3);
      expect(engine.session.tray.every((piece) => piece.isUsed), isFalse);
    });

    test('ends the round when no remaining piece fits', () {
      // After dropping the single at (0,3) the leftover empties are four
      // isolated cells — neither domino can be placed, so the round ends.
      final engine = engineOn(
        boardFromRows([
          'X.X.',
          'XXX.',
          '.XXX',
          'XX.X',
        ]),
        script: [
          [single, horizontalDomino, verticalDomino],
        ],
      );

      final events = engine.placePiece(
        trayIndex: 0,
        anchor: const GridPosition(row: 0, column: 3),
      );

      expect(
        events,
        contains(
          const GameEvent.roundEnded(outcome: RoundOutcome.classicGameOver()),
        ),
      );
      expect(engine.session.isOver, isTrue);
    });

    test('placing after the round is over is a no-op invalid move', () {
      final engine = engineOn(
        boardFromRows([
          'X.X.',
          'XXX.',
          '.XXX',
          'XX.X',
        ]),
        script: [
          [single, horizontalDomino, verticalDomino],
        ],
      );
      engine.placePiece(
        trayIndex: 0,
        anchor: const GridPosition(row: 0, column: 3),
      );
      final scoreWhenOver = engine.session.score;

      final events = engine.placePiece(
        trayIndex: 1,
        anchor: const GridPosition(row: 1, column: 3),
      );

      expect(events, [const GameEvent.invalidMove()]);
      expect(engine.session.score, scoreWhenOver);
    });
  });

  group('Level Mode frame teardown', () {
    test('removes the frame once, when the score reaches the threshold', () {
      final pentomino = shapeById(PieceShapeId.pentominoLineHorizontal);
      final engine = engineOn(
        Board.framed(),
        frameThreshold: 5,
        script: [
          [pentomino, single, single],
        ],
      );

      // Pentomino = 5 cells -> score hits the threshold of 5 in one move.
      final events = engine.placePiece(
        trayIndex: 0,
        anchor: const GridPosition(row: 1, column: 1),
      );

      expect(events, contains(const GameEvent.frameDestroyed()));
      expect(engine.session.frameRemoved, isTrue);
      expect(engine.session.board.hasFrame, isFalse);

      // A further qualifying move must not tear the frame down again.
      final moreEvents = engine.placePiece(
        trayIndex: 1,
        anchor: const GridPosition(row: 3, column: 1),
      );
      expect(moreEvents, isNot(contains(const GameEvent.frameDestroyed())));
    });
  });

  group('boosters', () {
    test('rotatePiece swaps the tray shape for its rotation', () {
      final lShape = shapeById(PieceShapeId.lTriomino0);
      final engine = engineOn(
        Board.empty(),
        script: [
          [lShape, single, single],
        ],
      );

      final events = engine.rotatePiece(0);

      expect(events.first, const GameEvent.pieceRotated(trayIndex: 0));
      expect(engine.session.tray[0].shape.cells, isNot(lShape.cells));
    });

    test('swapTray replaces every tray piece', () {
      final engine = engineOn(
        Board.empty(),
        script: [
          [
            shapeById(PieceShapeId.pentominoLineHorizontal),
            shapeById(PieceShapeId.pentominoLineVertical),
            shapeById(PieceShapeId.square),
          ],
        ],
      );

      final events = engine.swapTray();

      expect(events.first, const GameEvent.traySwapped());
      expect(engine.session.tray.length, 3);
      expect(engine.session.tray.every((piece) => piece.isUsed), isFalse);
    });

    test('removeCell erases a filled cell and refuses frame cells', () {
      final engine = engineOn(
        boardFromRows([
          '###',
          '#X#',
          '###',
        ]),
        script: [
          [single, single, single],
        ],
      );

      final removed = engine.removeCell(const GridPosition(row: 1, column: 1));
      expect(
        removed.first,
        const GameEvent.cellRemoved(
          position: GridPosition(row: 1, column: 1),
        ),
      );
      expect(
        engine.session.board.cellAt(const GridPosition(row: 1, column: 1)),
        CellState.empty,
      );

      // A frame cell can never be removed.
      final refused = engine.removeCell(const GridPosition(row: 0, column: 0));
      expect(refused, [const GameEvent.invalidMove()]);
    });
  });

  group('booster charges', () {
    test('Classic Mode (boostersEnabled: false) starts with zero charges',
        () {
      final engine = engineOn(Board.empty(), boostersEnabled: false);

      expect(engine.session.rotateCharges, 0);
      expect(engine.session.swapCharges, 0);
      expect(engine.session.singleCellRemoveCharges, 0);
    });

    test('boosters are refused outright when disabled', () {
      final lShape = shapeById(PieceShapeId.lTriomino0);
      final engine = engineOn(
        boardFromRows(['#X#', '#X#', '###']),
        boostersEnabled: false,
        script: [
          [lShape, single, single],
        ],
      );

      expect(engine.rotatePiece(0), [const GameEvent.invalidMove()]);
      expect(engine.swapTray(), [const GameEvent.invalidMove()]);
      expect(
        engine.removeCell(const GridPosition(row: 0, column: 1)),
        [const GameEvent.invalidMove()],
      );
    });

    test('an unlocked Level attempt starts with the default charge counts',
        () {
      final engine = engineOn(Board.framed());

      expect(
        engine.session.rotateCharges,
        BoosterConstants.defaultRotateCharges,
      );
      expect(engine.session.swapCharges, BoosterConstants.defaultSwapCharges);
      expect(
        engine.session.singleCellRemoveCharges,
        BoosterConstants.defaultSingleCellRemoveCharges,
      );
    });

    test('each booster use consumes exactly one charge of its own kind', () {
      final lShape = shapeById(PieceShapeId.lTriomino0);
      final engine = engineOn(
        Board.empty(),
        script: [
          [lShape, single, single],
        ],
      );

      engine.rotatePiece(0);

      expect(
        engine.session.rotateCharges,
        BoosterConstants.defaultRotateCharges - 1,
      );
      expect(engine.session.swapCharges, BoosterConstants.defaultSwapCharges);
    });

    test('a booster with zero charges left refuses further use', () {
      final lShape = shapeById(PieceShapeId.lTriomino0);
      final engine = engineOn(
        Board.empty(),
        script: [
          [lShape, single, single],
        ],
      );

      // Default rotate charge is 1 — the first rotate succeeds...
      final first = engine.rotatePiece(0);
      expect(first.first, isNot(const GameEvent.invalidMove()));

      // ...the second must be refused, and the tray shape stays as it was.
      final shapeAfterFirstRotate = engine.session.tray[0].shape;
      final second = engine.rotatePiece(0);

      expect(second, [const GameEvent.invalidMove()]);
      expect(engine.session.tray[0].shape, shapeAfterFirstRotate);
    });
  });
}
