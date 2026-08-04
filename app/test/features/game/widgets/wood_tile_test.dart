import 'package:bb_block/features/game/presentation/widgets/game_palette.dart';
import 'package:bb_block/features/game/presentation/widgets/wood_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BoxDecoration decorationOf(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(WoodTile),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  testWidgets(
      'a placed (non-frame) tile is a diagonal amber gradient with a glow — '
      'the new block/board texture (user instruction)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: WoodTile(size: 40)),
      ),
    );

    final decoration = decorationOf(tester);
    expect(
      decoration.gradient,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GamePalette.placedBlockGradientStart,
          GamePalette.placedBlockGradientEnd,
        ],
      ),
    );
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.boxShadow!.first.color, GamePalette.placedBlockGlow);
  });

  testWidgets(
      'a frame tile keeps its flat fill — no gradient or glow, unaffected '
      'by the placed-tile texture change', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: WoodTile(size: 40, isFrame: true)),
      ),
    );

    final decoration = decorationOf(tester);
    expect(decoration.gradient, isNull);
    expect(decoration.color, GamePalette.frameBlock);
    expect(decoration.boxShadow, isNull);
  });
}
