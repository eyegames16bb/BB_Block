import 'package:bb_block/core/routing/splash_screen.dart';
import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/game_screen.dart';
import 'package:bb_block/features/rewarded_ad/presentation/rewarded_ad_screen.dart';
import 'package:bb_block/features/tutorial/presentation/tutorial_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String game = '/game';
  static const String rewardedAd = '/rewarded-ad';
  static const String tutorial = '/tutorial';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.game,
      builder: (context, state) =>
          GameScreen(config: state.extra! as GameLaunchConfig),
    ),
    GoRoute(
      path: AppRoutes.rewardedAd,
      builder: (context, state) => const RewardedAdScreen(),
    ),
    // Replay entry from Settings (user request, restored after an earlier
    // removal in this same session) — always shows the tutorial regardless
    // of `tutorialCompleted`, and just pops back on finish instead of
    // relying on StartupGate's reactive rebuild.
    GoRoute(
      path: AppRoutes.tutorial,
      builder: (context, state) => TutorialScreen(
        onFinished: () => context.pop(),
      ),
    ),
  ],
);
