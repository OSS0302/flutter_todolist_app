import 'package:go_router/go_router.dart';
import 'package:todolist/presentation/add_screen.dart';
import 'package:todolist/presentation/list_screen.dart';

import '../presentation/stats_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ListScreen(),
    ),
    GoRoute(
      path: '/addScreen',
      builder: (context, state) => const AddScreen(),
    ),
    GoRoute(
      path: '/statsScreen',
      builder: (context, state) => const StatsScreen(),
    ),
  ],
);
