import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/bite_filters.dart';
import '../data/models/community_post.dart';
import '../data/services/auth_service.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/community/add_bite_screen.dart';
import '../features/community/community_screen.dart';
import '../features/community/community_post_detail_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/explore/guide_detail_screen.dart';
import '../features/find/find_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../state/auth_controller.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final router = createAppRouter(authService);

  ref.listen(authStateChangesProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createAppRouter(AuthService authService) => GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final isAuthenticated = authService.currentUser?.isEmailVerified ?? false;
    final isAuthRoute =
        state.matchedLocation == '/sign-in' ||
        state.matchedLocation == '/sign-up';

    if (!isAuthenticated && !isAuthRoute) return '/sign-in';
    if (isAuthenticated && isAuthRoute) return '/home';
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(path: '/find', builder: (context, state) => const FindScreen()),
        GoRoute(
          path: '/community',
          builder: (context, state) => CommunityScreen(
            selectedTags: BiteFilters.fromUri(state.uri),
            authorId: state.uri.queryParameters['author'],
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/guide/:guideId',
      builder: (context, state) => GuideDetailScreen(
        guideId: state.pathParameters['guideId']!,
        initialPhoto:
            int.tryParse(state.uri.queryParameters['photo'] ?? '') ?? 0,
      ),
    ),
    GoRoute(
      path: '/community/post/:postId',
      builder: (context, state) => CommunityPostDetailScreen(
        postId: state.pathParameters['postId']!,
        focusCommentId: state.uri.queryParameters['comment'],
      ),
    ),
    GoRoute(
      path: '/add-bite',
      builder: (context, state) => AddBiteScreen(
        initialPost: state.extra is CommunityPost
            ? state.extra! as CommunityPost
            : null,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
