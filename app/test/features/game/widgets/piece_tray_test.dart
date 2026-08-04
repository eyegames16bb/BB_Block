import 'package:bb_block/features/board/domain/entities/board.dart';
import 'package:bb_block/features/board/domain/entities/cell_state.dart';
import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_tray.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:bb_block/features/game_engine/domain/tray_piece.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_fixtures.dart';

void main() {
  Widget wrap(
    Widget child, {
    required double width,
    required double height,
  }) =>
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(width: width, height: height, child: child),
          ),
        ),
      );

  testWidgets(
      'a 5-cell vertical line piece shrinks to fit a tight slot instead of '
      'clipping (user report: 4/5-cell line pieces were cut off)',
      (tester) async {
    final tray = [
      TrayPiece(shape: shapeById(PieceShapeId.pentominoLineVertical)),
    ];

    // A slot far shorter than the piece's natural size at trayMaxCellSize
    // (26 * 5 = 130 tall) — the fix must shrink the piece down to fit
    // rather than overflow/clip.
    await tester.pumpWidget(
      wrap(
        PieceTray(tray: tray, dragCellSize: 35, board: Board.empty()),
        width: 120,
        height: 60,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    final size = tester.getSize(find.byType(WoodTile).first);
    expect(size.height, lessThanOrEqualTo(60 / 5));
  });

  testWidgets(
      'a small piece renders at the full tray cell size when there is '
      'plenty of room', (tester) async {
    final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];

    await tester.pumpWidget(
      wrap(
        PieceTray(tray: tray, dragCellSize: 35, board: Board.empty()),
        width: 200,
        height: 100,
      ),
    );
    await tester.pump();

    final size = tester.getSize(find.byType(WoodTile).first);
    expect(size.width, 26);
    expect(size.height, 26);
  });

  testWidgets(
      'a 5-cell horizontal line piece shrinks to fit a narrow slot',
      (tester) async {
    final tray = [
      TrayPiece(shape: shapeById(PieceShapeId.pentominoLineHorizontal)),
    ];

    await tester.pumpWidget(
      wrap(
        PieceTray(tray: tray, dragCellSize: 35, board: Board.empty()),
        width: 60,
        height: 60,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    final size = tester.getSize(find.byType(WoodTile).first);
    expect(size.width, lessThanOrEqualTo(60 / 5));
  });

  testWidgets(
      'a piece with nowhere to go on the current board renders dimmed '
      '(user instruction), a placeable one renders at full opacity',
      (tester) async {
    // A fully-packed board: nothing can be placed anywhere, regardless of
    // shape.
    final fullBoard = Board(
      size: 10,
      cells: List.filled(100, CellState.filled),
    );
    final tray = [TrayPiece(shape: shapeById(PieceShapeId.single))];

    await tester.pumpWidget(
      wrap(
        PieceTray(tray: tray, dragCellSize: 35, board: fullBoard),
        width: 200,
        height: 100,
      ),
    );
    await tester.pump();

    final dimmedOpacity = tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byType(WoodTile),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    expect(dimmedOpacity, GamePalette.unplaceablePieceOpacity);

    // Same piece, but an empty board where it obviously fits — full
    // opacity, no dimming.
    await tester.pumpWidget(
      wrap(
        PieceTray(tray: tray, dragCellSize: 35, board: Board.empty()),
        width: 200,
        height: 100,
      ),
    );
    await tester.pump();

    final fullOpacity = tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byType(WoodTile),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    expect(fullOpacity, 1);
  });
}
