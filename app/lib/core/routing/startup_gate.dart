import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/image_background.dart';
import 'package:bb_block/features/home/presentation/home_screen.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's real entry point behind the home route. The first-launch
/// interactive tutorial is temporarily disabled (user instruction) — this
/// always shows [HomeScreen] once the initial `PlayerProgress` load
/// resolves, regardless of `tutorialCompleted`.
class StartupGate extends ConsumerWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(playerProgressControllerProvider);

    if (!progressAsync.hasValue) {
      return const Scaffold(
        body: ImageBackground(
          assetPath: 'assets/images/home_background.png',
          child: Center(
            child: CircularProgressIndicator(color: AppColors.paper),
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}
