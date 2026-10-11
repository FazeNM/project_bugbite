import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_filters.dart';
import '../../../data/models/community_post.dart';
import '../../../state/auth_controller.dart';
import '../../../state/community_providers.dart';
import 'community_moderation.dart';

/// The same published-post presentation is used in the feed and conversation.
class CommunityPostCard extends ConsumerWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    this.isDetail = false,
  });

  final CommunityPost post;
  final bool isDetail;

  void _openPost(BuildContext context) =>
      context.push('/community/post/${Uri.encodeComponent(post.id)}');

  Future<void> _removePost(BuildContext context, WidgetRef ref) async {
    if (!await confirmCommunityRemoval(context, isPost: true) ||
        !context.mounted) {
      return;
    }
    final succeeded = await ref
        .read(communityActionsProvider.notifier)
        .deletePost(postId: post.id);
    if (!context.mounted) return;
    showCommunityActionResult(
      context,
      ref,
      succeeded: succeeded,
      successMessage: 'Post removed from the community.',
    );
    if (succeeded && isDetail) context.go('/community');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedState = ref.watch(communityLikedProvider(post.id));
    final liked = likedState.asData?.value ?? false;
    final action = ref.watch(communityActionsProvider);
    final isOwnPost = ref.watch(currentUserProvider)?.id == post.authorId;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        key: ValueKey('community-post-${post.id}'),
        onTap: isDetail ? null : () => _openPost(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(aspectRatio: 1.9, child: _PostVisual(post: post)),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.roseSoft,
                        child: Text(
                          post.author.trim().isEmpty
                              ? '?'
                              : post.author
                                    .trim()
                                    .characters
                                    .first
                                    .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.rose,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.author,
                          style: Theme.of(context).textTheme.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _relativeDate(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Post options',
                        enabled: !action.isLoading,
                        onSelected: (value) {
                          if (value == 'remove') {
                            _removePost(context, ref);
                          } else {
                            reportCommunityPost(context, ref, post.id);
                          }
                        },
                        itemBuilder: (_) => <PopupMenuEntry<String>>[
                          if (isOwnPost)
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove post'),
                            )
                          else
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Report post'),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    post.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.tags
                        .map(
                          (tag) => GuidePill(label: BiteFilters.labelFor(tag)),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: liked ? 'Remove like' : 'Support this post',
                        onPressed:
                            action.isLoading ||
                                likedState.isLoading ||
                                likedState.hasError
                            ? null
                            : () async {
                                final succeeded = await ref
                                    .read(communityActionsProvider.notifier)
                                    .setLiked(postId: post.id, liked: !liked);
                                if (!succeeded && context.mounted) {
                                  showCommunityActionResult(
                                    context,
                                    ref,
                                    succeeded: false,
                                    successMessage: '',
                                  );
                                }
                              },
                        icon: likedState.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: liked ? AppColors.rose : AppColors.muted,
                              ),
                      ),
                      Text(
                        '${post.likes}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      if (!isDetail) ...<Widget>[
                        const SizedBox(width: 12),
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () => _openPost(context),
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                              post.totalComments == 0
                                  ? 'Comment'
                                  : '${post.totalComments} comment${post.totalComments == 1 ? '' : 's'}',
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.muted,
                        ),
                      ],
                    ],
                  ),
                  if (likedState.hasError)
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(communityLikedProvider(post.id)),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Could not load your like. Retry'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }
}

class _PostVisual extends ConsumerWidget {
  const _PostVisual({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = post.imagePath;
    final Widget visual;
    if (path != null) {
      visual = ref
          .watch(communityPhotoProvider(path))
          .when(
            loading: () => const ColoredBox(
              color: AppColors.apricot,
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading shared photo',
                ),
              ),
            ),
            error: (_, _) => _PhotoRetry(
              onRetry: () => ref.invalidate(communityPhotoProvider(path)),
            ),
            data: (bytes) => bytes == null
                ? _PhotoRetry(
                    onRetry: () => ref.invalidate(communityPhotoProvider(path)),
                  )
                : Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    semanticLabel: 'Photo shared with ${post.possibleMatch}',
                    errorBuilder: (_, _, _) => _PhotoRetry(
                      onRetry: () =>
                          ref.invalidate(communityPhotoProvider(path)),
                    ),
                  ),
          );
    } else {
      visual = const _NoPostPhoto();
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        visual,
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: <Color>[Color(0xA61E1513), Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: GuidePill(label: post.possibleMatch),
          ),
        ),
      ],
    );
  }
}

class _PhotoRetry extends StatelessWidget {
  const _PhotoRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.apricot,
    child: Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Photo unavailable · Retry'),
      ),
    ),
  );
}

class _NoPostPhoto extends StatelessWidget {
  const _NoPostPhoto();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.apricot,
    child: Center(
      child: Icon(
        Icons.photo_outlined,
        size: 44,
        color: AppColors.muted,
        semanticLabel: 'No photo shared',
      ),
    ),
  );
}
