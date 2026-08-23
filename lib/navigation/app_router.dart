import 'package:go_router/go_router.dart';

import '../features/cinema/your_cinema_screen.dart';
import '../features/diary/diary_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/movie_detail/add_movie_screen.dart';
import '../features/movie_detail/movie_detail_screen.dart';
import 'app_shell.dart';
import 'more_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/diary',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/diary',
            builder: (context, state) => const DiaryScreen(),
            routes: [
              GoRoute(
                path: 'movie/:id',
                builder: (context, state) => MovieDetailScreen(
                  entryId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/your-cinema',
            builder: (context, state) => const YourCinemaScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/add-movie',
      builder: (context, state) => const AddMovieScreen(),
    ),
  ],
);
