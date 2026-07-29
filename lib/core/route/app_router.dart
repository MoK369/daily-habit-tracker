import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'route_paths.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: RoutePaths.addHabit,
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: RoutePaths.editHabitPattern,
        builder: (context, state) => const Placeholder(),
      ),
    ],
  );
}
