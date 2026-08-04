import 'package:bb_block/core/theme/app_theme.dart';
import 'package:bb_block/core/theme/image_background.dart';
import 'package:bb_block/features/home/presentation/home_screen.dart';
import 'package:bb_block/features/persistence/application/player_progress_controller.dart';
import 'package:bb_block/features/tutorial/presentation/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's real entry point behind the home route — shows the
/// first-launch interactive tutorial instead of the home menu until
/// `PlayerProgress.tutorialCompleted` is true (user instruction: only ever
/// once per install; a fresh install after uninstalling resets it since
/// `PlayerProgress` is the single local save blob everything else here
/// lives in too). Once finished, this same watch-driven rebuild is what
/// swaps straight to [HomeScreen] — no separate navigation needed.
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

    if (!progressAsync.value!.tutorialCompleted) {
      return TutorialScreen(onFinished: () {});
    }
    return const HomeScreen();
  }
}
