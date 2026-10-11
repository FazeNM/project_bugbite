import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_widgets.dart';
import '../../data/seed/seed_data.dart';
import '../../state/app_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/profile_data_controller.dart';
import 'widgets/profile_activity_section.dart';
import 'widgets/profile_notifications_section.dart';
import 'widgets/profile_preferences_section.dart';
import 'widgets/profile_saved_guides_section.dart';
import 'widgets/profile_shared_posts_section.dart';
import 'widgets/profile_sign_out_button.dart';
import 'widgets/profile_summary.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final authAction = ref.watch(authControllerProvider);
    final profileData = ref.watch(profileDataProvider);
    final savedGuides = guides
        .where((guide) => state.savedGuideIds.contains(guide.id))
        .toList(growable: false);
    final privatePosts = state.posts
        .where(
          (post) =>
              post.authorId == state.userId && post.publishedPostId == null,
        )
        .toList(growable: false);

    void openGuide(String guideId) => context.push('/guide/$guideId');
    void openSettings() => context.push('/settings');

    return profileData.when(
      loading: () =>
          const ProfileDataLoadingView(photoAsset: AppAssets.honeyBee),
      error: (_, _) => ProfileDataErrorView(
        onRetry: () => ref.read(profileDataProvider.notifier).reload(),
      ),
      data: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: <Widget>[
            ProfilePageHeader(onOpenSettings: openSettings),
            const SizedBox(height: 16),
            ProfileIdentityCard(displayName: state.displayName),
            const ProfileNotificationsSection(),
            const SizedBox(height: 14),
            Text(
              '${savedGuides.length} saved guides · Private to this account',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (state.persistenceError case final message?)
              PersistenceWarningCard(
                message: message,
                onRetry: () =>
                    ref.read(appControllerProvider.notifier).retryPersistence(),
              ),
            ProfileSavedGuidesSection(
              guides: savedGuides,
              onOpenGuide: openGuide,
            ),
            const ProfileSharedPostsSection(),
            if (privatePosts.isNotEmpty)
              LegacyPrivatePostsSection(posts: privatePosts),
            ProfileActivitySection(
              profileData: profileData,
              onRetry: () => ref.read(profileDataProvider.notifier).reload(),
              onOpenGuide: openGuide,
            ),
            ProfilePreferencesSection(onOpenSettings: openSettings),
            const SizedBox(height: 16),
            ProfileSignOutButton(
              isLoading: authAction.isLoading,
              onPressed: () => _confirmSignOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of BiteWise?'),
        content: const Text(
          'Your saved guides, history, settings, and private notes remain on this device for this account. Published community posts and comments remain online and visible to other signed-in members.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !context.mounted) return;
    final authController = ref.read(authControllerProvider.notifier);
    final appController = ref.read(appControllerProvider.notifier);
    final didSignOut = await authController.signOut();

    if (didSignOut) {
      appController.signOut();
      if (context.mounted) context.go('/sign-in');
      return;
    }

    if (!context.mounted) return;
    final message = ref.read(authControllerProvider).errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
