import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/navigation_helpers.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/services/community_repository.dart';
import '../../state/community_providers.dart';
import 'widgets/community_comment_tile.dart';
import 'widgets/community_post_card.dart';
import 'widgets/supportive_comment_sheet.dart';

class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  const CommunityPostDetailScreen({
    super.key,
    required this.postId,
    this.focusCommentId,
  });

  final String postId;
  final String? focusCommentId;

  @override
  ConsumerState<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends ConsumerState<CommunityPostDetailScreen> {
  int _commentLimit = 50;

  @override
  void didUpdateWidget(covariant CommunityPostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) _commentLimit = 50;
  }

  Future<void> _addComment() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SupportiveCommentSheet(postId: widget.postId),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment added.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = communityPostProvider(widget.postId);
    final postState = ref.watch(provider);
    final post = postState.asData?.value;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => popOrGo(context, '/community'),
        ),
        title: const Text('Shared experience'),
      ),
      body: SafeArea(
        bottom: false,
        child: postState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading post'),
          ),
          error: (error, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: LoadErrorPanel(
              title: 'This conversation could not be loaded',
              message: error is CommunityException
                  ? error.code == 'permission-denied'
                        ? 'This conversation is unavailable. It may have been removed, or your access has changed.'
                        : error.message
                  : 'Check your connection and try again.',
              onRetry: () => ref.invalidate(provider),
            ),
          ),
          data: (post) => post == null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      const EmptyPanel(
                        icon: Icons.forum_outlined,
                        title: 'Post not found',
                        message:
                            'This experience may have been removed or is no longer available.',
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go('/community'),
                        child: const Text('Back to community'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  key: PageStorageKey('conversation-${widget.postId}'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: <Widget>[
                    if (widget.focusCommentId != null) ...<Widget>[
                      _buildFocusedComment(),
                      const SizedBox(height: 18),
                      Semantics(
                        header: true,
                        child: Text(
                          'Original post',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    CommunityPostCard(post: post, isDetail: true),
                    const SizedBox(height: 16),
                    const SafetyNotice(compact: true),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      child: Text(
                        'Comments (${post.totalComments})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Community suggestions are unverified. Newest replies first.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    _buildComments(),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: post == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: FilledButton.icon(
                onPressed: _addComment,
                icon: const Icon(Icons.mode_comment_outlined),
                label: const Text('Add a comment'),
              ),
            ),
    );
  }

  Widget _buildFocusedComment() {
    final provider = communityCommentProvider((
      postId: widget.postId,
      commentId: widget.focusCommentId!,
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Selected comment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The comment you opened, with the original post below.',
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
                    semanticsLabel: 'Loading selected comment',
                  ),
                ),
              ),
              error: (error, _) => LoadErrorPanel(
                title: 'This comment could not be loaded',
                message: error is CommunityException
                    ? error.message
                    : 'Check your connection and try again.',
                onRetry: () => ref.invalidate(provider),
              ),
              data: (comment) => comment == null
                  ? const EmptyPanel(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Comment no longer available',
                      message:
                          'It may have been removed. You can still read the original post and the rest of the conversation below.',
                    )
                  : CommunityCommentTile(
                      key: ValueKey('focused-${comment.id}'),
                      comment: comment,
                      postId: widget.postId,
                    ),
            ),
      ],
    );
  }

  Widget _buildComments() {
    final provider = communityCommentsProvider((
      postId: widget.postId,
      limit: _commentLimit,
    ));
    return ref
        .watch(provider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading comments',
              ),
            ),
          ),
          error: (error, _) => LoadErrorPanel(
            title: 'Comments could not be loaded',
            message: error is CommunityException
                ? error.message
                : 'Check your connection and try again. The conversation has not been deleted.',
            onRetry: () => ref.invalidate(provider),
          ),
          data: (comments) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (comments.isEmpty)
                const EmptyPanel(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No comments yet',
                  message: 'Start the conversation with a kind, useful reply.',
                ),
              for (final comment in comments.where(
                (comment) => comment.id != widget.focusCommentId,
              ))
                CommunityCommentTile(
                  key: ValueKey(comment.id),
                  comment: comment,
                  postId: widget.postId,
                ),
              if (comments.length >= _commentLimit)
                OutlinedButton.icon(
                  key: const ValueKey('load-more-comments'),
                  onPressed: () => setState(() => _commentLimit += 50),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Load older comments'),
                ),
            ],
          ),
        );
  }
}
