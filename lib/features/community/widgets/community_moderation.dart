import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/community_providers.dart';

Future<bool> confirmCommunityRemoval(
  BuildContext context, {
  required bool isPost,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isPost ? 'Remove this post?' : 'Remove this comment?'),
        content: Text(
          isPost
              ? 'This post, its photo, and its conversation will no longer appear in the community. This cannot be undone in the app.'
              : 'This comment will no longer appear in the conversation.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ??
    false;

void showCommunityActionResult(
  BuildContext context,
  WidgetRef ref, {
  required bool succeeded,
  required String successMessage,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        succeeded
            ? successMessage
            : ref.read(communityActionsProvider).errorMessage ??
                  'This action could not be completed. Please try again.',
      ),
    ),
  );
}

Future<void> reportCommunityPost(
  BuildContext context,
  WidgetRef ref,
  String postId,
) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Report this post',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your report is private. It does not automatically remove the post or provide medical help.',
            ),
            const SizedBox(height: 12),
            for (final reason in <String>[
              'Unsafe medical advice',
              'Harassment or hateful content',
              'Personal information or photo shared without permission',
              'Spam or unrelated content',
              'Other concern',
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reason),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, reason),
              ),
          ],
        ),
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  final succeeded = await ref
      .read(communityActionsProvider.notifier)
      .reportPost(postId: postId, reason: reason);
  if (!context.mounted) return;
  showCommunityActionResult(
    context,
    ref,
    succeeded: succeeded,
    successMessage:
        'Report submitted. Thank you for helping keep the community safe.',
  );
}
