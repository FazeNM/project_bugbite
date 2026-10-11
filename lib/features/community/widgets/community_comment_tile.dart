import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_post.dart';
import '../../../state/auth_controller.dart';
import '../../../state/community_providers.dart';
import 'community_moderation.dart';
import 'supportive_comment_sheet.dart';

class CommunityCommentTile extends ConsumerWidget {
  const CommunityCommentTile({
    super.key,
    required this.comment,
    required this.postId,
  });

  final CommunityComment comment;
  final String postId;

  Future<void> _reply(BuildContext context) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SupportiveCommentSheet(postId: postId, replyTo: comment),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply posted.')));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    if (!await confirmCommunityRemoval(context, isPost: false) ||
        !context.mounted) {
      return;
    }
    final succeeded = await ref
        .read(communityActionsProvider.notifier)
        .deleteComment(postId: postId, commentId: comment.id);
    if (!context.mounted) return;
    showCommunityActionResult(
      context,
      ref,
      succeeded: succeeded,
      successMessage: 'Comment removed.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnComment = ref.watch(currentUserProvider)?.id == comment.authorId;
    final busy = ref.watch(communityActionsProvider).isLoading;
    final date = comment.createdAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final timestamp =
        '${localizations.formatCompactDate(date)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  comment.author,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (isOwnComment)
                IconButton(
                  tooltip: 'Remove your comment',
                  onPressed: busy ? null : () => _remove(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
          if (comment.replyToAuthor case final replyToAuthor?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  backgroundColor: AppColors.roseSoft,
                ),
                onPressed: comment.replyToCommentId == null
                    ? null
                    : () => context.push(
                        Uri(
                          pathSegments: ['', 'community', 'post', postId],
                          queryParameters: {
                            'comment': comment.replyToCommentId!,
                          },
                        ).toString(),
                      ),
                icon: const Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 17,
                ),
                label: Text(
                  'Replying to $replyToAuthor',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(comment.body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          TextButton.icon(
            key: ValueKey('reply-to-${comment.id}'),
            onPressed: busy ? null : () => _reply(context),
            icon: const Icon(Icons.reply_rounded, size: 20),
            label: const Text('Reply'),
          ),
        ],
      ),
    );
  }
}
