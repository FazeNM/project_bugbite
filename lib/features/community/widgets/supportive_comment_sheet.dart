import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_post.dart';
import '../../../state/community_providers.dart';

class SupportiveCommentSheet extends ConsumerStatefulWidget {
  const SupportiveCommentSheet({super.key, required this.postId, this.replyTo});

  final String postId;
  final CommunityComment? replyTo;

  @override
  ConsumerState<SupportiveCommentSheet> createState() =>
      _SupportiveCommentSheetState();
}

class _SupportiveCommentSheetState
    extends ConsumerState<SupportiveCommentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final saved = await ref
        .read(communityActionsProvider.notifier)
        .addComment(
          postId: widget.postId,
          body: _commentController.text,
          replyToCommentId: widget.replyTo?.id,
        );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(communityActionsProvider).errorMessage ??
              'Your comment could not be published. Check your connection and try again. Your reply is still here.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    padding: EdgeInsets.fromLTRB(
      24,
      4,
      24,
      28 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.replyTo == null
                  ? 'Add a supportive comment'
                  : 'Reply to ${widget.replyTo!.author}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Replies are visible to other signed-in members. Avoid diagnosis claims, personal information, and personal medical advice.',
            ),
            if (widget.replyTo case final comment?) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.roseSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                    left: BorderSide(color: AppColors.rose, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${comment.author} wrote',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      comment.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Community experience · not verified medical advice',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _commentController,
              enabled: !_submitting,
              minLines: 2,
              maxLines: 4,
              maxLength: 2000,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Write a kind, useful reply…',
              ),
              validator: (value) {
                final length = (value ?? '').trim().length;
                return length < 2 || length > 2000
                    ? 'Write a reply between 2 and 2,000 characters.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.replyTo == null ? 'Post comment' : 'Post reply',
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
