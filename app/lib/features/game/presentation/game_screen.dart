import 'dart:math' as math;

import 'package:bb_block/core/constants/app_constants.dart';
import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/features/game/application/game_controller.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/widgets/board_grid.dart';
import 'package:bb_block/features/game/presentation/widgets/piece_tray.dart';
import 'package:bb_block/features/game_engine/domain/game_session.dart';
import 'package:bb_block/features/game_mode/domain/game_mode_strategy.dart';
import 'package:bb_block/features/game_mode/domain/round_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({required this.config, super.key});

  final GameLaunchConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider(config));
    final controller = ref.read(gameControllerProvider(config).notifier);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Header(config: config, session: session),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Cap the board to the smaller of the available width
                        // and ~74% of the height, so the board plus the tray
                        // below always fit without overflow on any screen.
                        final boardSide = math.min(
                          constraints.maxWidth,
                          constraints.maxHeight * 0.74,
                        );
                        final cellSize = boardSide / session.board.size;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: boardSide,
                              height: boardSide,
                              child: BoardGrid(
                                board: session.board,
                                tray: session.tray,
                                onPlace: (trayIndex, anchor) =>
                                    controller.placePiece(
                                  trayIndex: trayIndex,
                                  anchor: anchor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: boardSide,
                              height: cellSize * 2.2,
                              child: PieceTray(
                                tray: session.tray,
                                dragCellSize: cellSize,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (session.isOver)
              _RoundOverlay(config: config, session: session),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.config, required this.session});

  final GameLaunchConfig config;
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final isLevel = config.mode == GameModeType.level;

    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isLevel
              ? _LevelProgress(score: session.score)
              : Text(
                  '${session.score}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
        ),
      ],
    );
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    const target = LevelModeConstants.targetScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$score / $target',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (score / target).clamp(0, 1).toDouble(),
            minHeight: 8,
            backgroundColor: AppColors.navy.withValues(alpha: 0.15),
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

class _RoundOverlay extends ConsumerWidget {
  const _RoundOverlay({required this.config, required this.session});

  final GameLaunchConfig config;
  final GameSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Card(
          color: AppColors.navy,
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title(session.outcome),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppColors.paper),
                ),
                const SizedBox(height: 12),
                Text(
                  'Skor: ${session.score}',
                  style: const TextStyle(color: AppColors.paper, fontSize: 18),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(gameControllerProvider(config)),
                  child: const Text('Tekrar Oyna'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Ana Menü',
                    style: TextStyle(color: AppColors.paper),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(RoundOutcome outcome) => switch (outcome) {
        RoundOutcomeLevelComplete() => 'Bölüm Tamamlandı!',
        RoundOutcomeLevelFailed() => 'Bölüm Başarısız',
        RoundOutcomeClassicGameOver() => 'Oyun Bitti',
        RoundOutcomeOngoing() => '',
      };
}
