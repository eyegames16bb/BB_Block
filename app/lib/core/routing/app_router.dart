import 'package:bb_block/features/game/application/game_launch_config.dart';
import 'package:bb_block/features/game/presentation/game_screen.dart';
import 'package:bb_block/features/home/presentation/home_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String game = '/game';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.game,
      builder: (context, state) =>
          GameScreen(config: state.extra! as GameLaunchConfig),
    ),
  ],
);
