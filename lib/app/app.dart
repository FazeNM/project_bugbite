import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/services/auth_service.dart';
import '../state/app_controller.dart';
import '../state/auth_controller.dart';
import '../state/profile_data_controller.dart';
import 'app_router.dart';

class BiteWiseApp extends ConsumerStatefulWidget {
  const BiteWiseApp({super.key});

  @override
  ConsumerState<BiteWiseApp> createState() => _BiteWiseAppState();
}

class _BiteWiseAppState extends ConsumerState<BiteWiseApp> {
  late final ProviderSubscription<AuthUser?> _authSubscription;
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthUser?>(currentUserProvider, (
      _,
      user,
    ) {
      Future<void>.microtask(() async {
        if (!mounted) return;
        final accountChanged = _activeUserId != user?.id;
        _activeUserId = user?.id;
        if (accountChanged) ref.invalidate(profileDataProvider);

        final appController = ref.read(appControllerProvider.notifier);
        if (user == null) {
          appController.signOut();
        } else {
          await appController.syncAuthenticatedUser(
            userId: user.id,
            displayName: user.displayName,
            email: user.email,
          );
        }
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'BiteWise',
    debugShowCheckedModeBanner: false,
    theme: BiteWiseTheme.light(),
    routerConfig: ref.watch(appRouterProvider),
  );
}
