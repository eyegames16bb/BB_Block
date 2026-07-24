import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_fixtures.dart';

void main() {
  Widget harness({
    required Widget boardGrid,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Draggable<int>(
                data: 0,
                feedback: SizedBox(width: 4, height: 4),
                child: SizedBox(
                  key: Key('drag-source'),
                  width: 40,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
              Expanded(child: boardGrid),
            ],
          ),
        ),
      );

  Future<void> dragOnto(WidgetTester tester, Offset target) async {
    final source = tester.getCenter(find.byKey(const Key('drag-source')));
    final gesture = await tester.startGesture(source);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
      'a drop that lands on an already-filled cell still reaches onPlace — '
      'the widget must not silently swallow a rejected drop', (tester) async {
    final board = boardFromRows(['X..', '...', '...']);
    final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];
    var placeCalls = 0;

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: board,
          tray: tray,
          onPlace: (trayIndex, anchor) => placeCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardTopLeft = tester.getTopLeft(find.byType(BoardGrid));
    // Comfortably inside the already-filled (0,0) cell.
    await dragOnto(tester, boardTopLeft + const Offset(15, 15));

    expect(placeCalls, 1);
  });

  testWidgets('a drop onto empty space also reaches onPlace', (tester) async {
    final board = boardFromRows(['...', '...', '...']);
    final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];
    var placeCalls = 0;

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: board,
          tray: tray,
          onPlace: (trayIndex, anchor) => placeCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardTopLeft = tester.getTopLeft(find.byType(BoardGrid));
    await dragOnto(tester, boardTopLeft + const Offset(15, 15));

    expect(placeCalls, 1);
  });

  testWidgets('a filled cell renders with a pop-in scale animation',
      (tester) async {
    final board = boardFromRows(['X..', '...', '...']);

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(board: board, tray: const [], onPlace: (_, _) {}),
      ),
    );

    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
  });

  testWidgets(
      'a cleared cell keeps rendering its wood tile briefly, then '
      'disappears once the break animation ends', (tester) async {
    final filledBoard = boardFromRows(['X..', '...', '...']);
    final clearedBoard = boardFromRows(['...', '...', '...']);

    await tester.pumpWidget(
      harness(
        boardGrid:
            BoardGrid(board: filledBoard, tray: const [], onPlace: (_, _) {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      harness(
        boardGrid: BoardGrid(
          board: clearedBoard,
          tray: const [],
          onPlace: (_, _) {},
        ),
      ),
    );

    // Mid-animation: the board already reports the cell empty, but its
    // wood tile is still on screen, fading/bursting out.
    await tester.pump();
    expect(find.byType(WoodTile), findsOneWidget);

    // Once the break animation completes, the overlay removes itself.
    await tester.pumpAndSettle();
    expect(find.byType(WoodTile), findsNothing);
  });
}
