import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
import 'package:bb_block/features/board/domain/entities/grid_position.dart';
import 'package:bb_block/features/game/application/game_controller.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/game_screen.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/booster_bar.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_tray.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_audio_service.dart';
import '../../support/fake_game_save_repository.dart';
import '../../support/fake_haptics_service.dart';

void main() {
  Widget wrap(GameLaunchConfig config) => ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            FakeGameSaveRepository(),
          ),
          hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
        ],
        child: MaterialApp(home: GameScreen(config: config)),
      );

  testWidgets('classic frameless game renders the board and a full tray',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.classic)),
    );
    await tester.pump();

    expect(find.byType(BoardGrid), findsOneWidget);
    expect(find.byType(PieceTray), findsOneWidget);
    // Three draggable pieces in a fresh tray.
    expect(find.byType(Draggable<int>), findsNWidgets(3));
  });

  testWidgets('level game shows the score-to-target progress header',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.level)),
    );
    await tester.pump();

    expect(find.text('0 / 1000'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('BoosterBar is hidden for Classic Mode', (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.classic)),
    );
    await tester.pump();

    expect(find.byType(BoosterBar), findsNothing);
  });

  testWidgets('BoosterBar is hidden for a locked Level Mode attempt',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.level)),
    );
    await tester.pump();

    expect(find.byType(BoosterBar), findsNothing);
  });

  testWidgets(
      'BoosterBar is shown with default charges for an unlocked Level '
      'Mode attempt', (tester) async {
    await tester.pumpWidget(
      wrap(
        const GameLaunchConfig(
          mode: GameModeType.level,
          levelBoostersUnlocked: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BoosterBar), findsOneWidget);
    // Default charges are 1/1/1.
    expect(find.text('1'), findsNWidgets(3));
  });

  testWidgets('the pause button shows an overlay, and Devam Et dismisses it',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.classic)),
    );
    await tester.pump();

    expect(find.text('Duraklatıldı'), findsNothing);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    expect(find.text('Duraklatıldı'), findsOneWidget);

    await tester.tap(find.text('Devam Et'));
    await tester.pump();

    expect(find.text('Duraklatıldı'), findsNothing);
  });

  testWidgets(
      'backgrounding the app mid-round pauses it, visible again on return',
      (tester) async {
    await tester.pumpWidget(
      wrap(const GameLaunchConfig(mode: GameModeType.classic)),
    );
    await tester.pump();

    // The engine binding deliberately suppresses frames while the
    // simulated app is AppLifecycleState.paused (it mirrors real OS
    // behaviour: a backgrounded app isn't drawing). setState still runs
    // and marks the pause dirty, but nothing paints until state returns to
    // resumed — exactly when the player would actually see the screen
    // again, so this sequence matches what really happens on-device.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Duraklatıldı'), findsOneWidget);
  });

  testWidgets('placing a piece shows a rising +N score popup',
      (tester) async {
    const config = GameLaunchConfig(mode: GameModeType.classic);
    await tester.pumpWidget(wrap(config));
    await tester.pump();

    expect(find.textContaining('+'), findsNothing);

    // Drive the same controller call BoardGrid's onPlace would make on a
    // real drop, rather than simulating the drag gesture itself — that
    // mechanics is already covered end-to-end by board_grid_test.dart.
    // The board starts empty, so any tray piece fits at the origin.
    final context = tester.element(find.byType(GameScreen));
    ProviderScope.containerOf(context)
        .read(gameControllerProvider(config).notifier)
        .placePiece(
          trayIndex: 0,
          anchor: const GridPosition(row: 0, column: 0),
        );
    await tester.pump();

    expect(find.textContaining('+'), findsOneWidget);
  });
}
