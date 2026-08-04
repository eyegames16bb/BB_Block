import 'package:bb_block/features/game/presentation/widgets/place_sequence.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'the settled tile fills its full cell size — regression test: the '
      "sequence's own inner Stack used to default to StackFit.loose, so the "
      'WoodTile (which has no intrinsic size of its own) collapsed to a '
      'near-zero dot instead of filling the cell, making every freshly '
      'placed block invisible (user report: blocks not appearing on screen '
      'when added)', (tester) async {
    const cellSize = 120.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: cellSize,
              height: cellSize,
              child: PlaceSequence(cellSize: cellSize, onSparkle: () {}),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final tileSize = tester.getSize(find.byType(WoodTile));
    expect(tileSize.width, cellSize);
    expect(tileSize.height, cellSize);
  });
}
