import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/community_post.dart';
import '../../../data/services/community_repository.dart';
import '../../../state/auth_controller.dart';
import '../../../state/community_providers.dart';

class ProfileSharedPostsSection extends ConsumerWidget {
  const ProfileSharedPostsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorId = ref.watch(currentUserProvider)?.id;
    if (authorId == null) return const SizedBox.shrink();
    final provider = communityFeedProvider((
      tag: null,
      authorId: authorId,
      limit: 50,
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'Your shared experiences',
          actionLabel: 'View all',
          onAction: () => context.go(
            Uri(
              path: '/community',
              queryParameters: {'author': authorId},
            ).toString(),
          ),
        ),
        Text(
          'Published online · visible to other signed-in members',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ref
            .watch(provider)
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Loading your published experiences',
                  ),
                ),
              ),
              error: (error, _) => LoadErrorPanel(
                title: 'Published experiences could not load',
                message: error is CommunityException
                    ? error.message
                    : 'Check your connection and retry. Your private notes are separate.',
                onRetry: () => ref.invalidate(provider),
              ),
              data: (posts) => posts.isEmpty
                  ? const EmptyPanel(
                      icon: Icons.post_add_rounded,
                      title: 'Nothing shared yet',
                      message:
                          'Experiences you publish to the community will appear here.',
                    )
                  : Column(
                      children: <Widget>[
                        for (final post in posts.take(3))
                          _PostSummary(
                            post: post,
                            onTap: () => context.push(
                              '/community/post/${Uri.encodeComponent(post.id)}',
                            ),
                          ),
                        if (posts.length > 3)
                          const Text(
                            'Showing your three newest posts. Choose View all for more.',
                          ),
                      ],
                    ),
            ),
      ],
    );
  }
}

/// Old per-account data stays private until its author explicitly publishes it.
class LegacyPrivatePostsSection extends StatelessWidget {
  const LegacyPrivatePostsSection({super.key, required this.posts});

  final List<CommunityPost> posts;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SectionHeader(title: 'Private notes on this device'),
      Text(
        'These experiences were saved before the shared community was connected. Other members cannot see them. Review each note before choosing to publish it.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      for (final post in posts)
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  post.possibleMatch,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(post.body, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: ValueKey('publish-legacy-${post.id}'),
                  onPressed: () => context.push('/add-bite', extra: post),
                  icon: const Icon(Icons.publish_outlined),
                  label: const Text('Review & publish'),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _PostSummary extends StatelessWidget {
  const _PostSummary({required this.post, required this.onTap});

  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: AppColors.roseSoft,
          child: Icon(Icons.forum_outlined, color: AppColors.rose),
        ),
        title: Text(
          post.possibleMatch,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    ),
  );
}
