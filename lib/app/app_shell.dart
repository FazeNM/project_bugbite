import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_widgets.dart';
import '../state/app_controller.dart';
import '../state/community_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _destinations = <_ShellDestination>[
    _ShellDestination('/home', 'Home', Icons.home_outlined, Icons.home_rounded),
    _ShellDestination(
      '/explore',
      'Explore',
      Icons.explore_outlined,
      Icons.explore_rounded,
    ),
    _ShellDestination('/find', 'Find', Icons.tune_outlined, Icons.tune_rounded),
    _ShellDestination(
      '/community',
      'Community',
      Icons.forum_outlined,
      Icons.forum_rounded,
    ),
    _ShellDestination(
      '/profile',
      'Profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (item) => location.startsWith(item.location),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    if (appState.isHydrating) {
      return const Scaffold(
        body: ProfileDataLoadingView(photoAsset: AppAssets.honeyBee),
      );
    }

    final unread =
        ref.watch(communityUnreadNotificationCountProvider).asData?.value ?? 0;
    Widget destinationIcon(_ShellDestination item, IconData icon) {
      if (item.location != '/profile' || unread == 0) return Icon(icon);
      return Badge(
        key: ValueKey('profile-notification-badge-${icon.codePoint}'),
        label: Text(unread >= 100 ? '99+' : '$unread'),
        child: Icon(icon),
      );
    }

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            context.go(_destinations[index].location),
        destinations: _destinations
            .map(
              (item) => NavigationDestination(
                icon: destinationIcon(item, item.icon),
                selectedIcon: destinationIcon(item, item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(
    this.location,
    this.label,
    this.icon,
    this.selectedIcon,
  );

  final String location;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
