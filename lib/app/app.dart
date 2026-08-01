import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/auth_screens.dart';
import '../features/community/add_bite_screen.dart';
import '../features/community/community_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/explore/guide_detail_screen.dart';
import '../features/find/find_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import 'app_shell.dart';

GoRouter _createRouter() => GoRouter(
  initialLocation: '/sign-in',
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
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/guide/:guideId',
      builder: (context, state) =>
          GuideDetailScreen(guideId: state.pathParameters['guideId']!),
    ),
    GoRoute(
      path: '/add-bite',
      builder: (context, state) => const AddBiteScreen(),
    ),
  ],
);

class BiteWiseApp extends StatefulWidget {
  const BiteWiseApp({super.key});

  @override
  State<BiteWiseApp> createState() => _BiteWiseAppState();
}

class _BiteWiseAppState extends State<BiteWiseApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'BiteWise',
    debugShowCheckedModeBanner: false,
    theme: BiteWiseTheme.light(),
    routerConfig: _router,
  );
}
