import 'package:bb_block/core/providers/audio_providers.dart';
import 'package:bb_block/core/providers/haptics_providers.dart';
import 'package:bb_block/core/providers/persistence_providers.dart';
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
}
