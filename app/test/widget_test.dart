import 'package:bb_block/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen shows the game title and both mode buttons',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BbBlockApp()),
    );

    expect(find.text('BB Block'), findsOneWidget);
    expect(find.text('Klasik Mod'), findsOneWidget);
    expect(find.text('Level Mod'), findsOneWidget);
  });
}
