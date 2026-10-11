import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_filters.dart';
import '../../../data/services/community_filter_service.dart';
import '../../../data/services/community_repository.dart';
import '../../../state/community_providers.dart';
import 'community_post_card.dart';

/// Shared cloud results keep guide fallbacks and the full feed consistent.
class CommunityPostResults extends ConsumerStatefulWidget {
  const CommunityPostResults({
    super.key,
    this.selectedTags = const <String>{},
    this.previewLimit,
    this.authorId,
  });

  final Set<String> selectedTags;
  final int? previewLimit;
  final String? authorId;

  @override
  ConsumerState<CommunityPostResults> createState() =>
      _CommunityPostResultsState();
}

class _CommunityPostResultsState extends ConsumerState<CommunityPostResults> {
  int _limit = 50;

  @override
  void didUpdateWidget(covariant CommunityPostResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorId != widget.authorId ||
        !setEquals(oldWidget.selectedTags, widget.selectedTags)) {
      _limit = 50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = BiteFilters.normalizeAll(widget.selectedTags).toList()..sort();
    final provider = communityFeedProvider((
      tag: tags.firstOrNull,
      authorId: widget.authorId,
      limit: _limit,
    ));
    return ref
        .watch(provider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: <Widget>[
                CircularProgressIndicator(
                  semanticsLabel: 'Loading community experiences',
                ),
                SizedBox(height: 12),
                Text('Loading community experiences…'),
              ],
            ),
          ),
          error: (error, _) => LoadErrorPanel(
            title: 'Community experiences could not load',
            message: error is CommunityException
                ? error.message
                : 'Check your connection and try again. Your private saved guides are still on this device.',
            onRetry: () => ref.invalidate(provider),
          ),
          data: (loadedPosts) {
            final posts = filterCommunityPosts(loadedPosts, tags.toSet());
            final hasMore = loadedPosts.length >= _limit;
            final visible = widget.previewLimit == null
                ? posts
                : posts.take(widget.previewLimit!);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (posts.isEmpty)
                  EmptyPanel(
                    icon: Icons.forum_outlined,
                    title: hasMore
                        ? 'No matches in loaded posts'
                        : tags.isEmpty
                        ? 'No experiences in loaded results'
                        : 'No loaded posts match all these filters',
                    message: hasMore
                        ? 'Load more experiences to keep looking. No matching post does not mean a reaction is harmless.'
                        : tags.isEmpty
                        ? 'Reconnect and refresh to check for the newest posts, or share your own experience.'
                        : 'Reconnect and refresh, try fewer filters, or share what you noticed. No matching post does not mean a reaction is harmless.',
                  )
                else ...<Widget>[
                  if (tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${posts.length} loaded post${posts.length == 1 ? '' : 's'} with all selected observations · newest first',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ...visible.map(
                    (post) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CommunityPostCard(post: post),
                    ),
                  ),
                  if (widget.previewLimit != null &&
                      posts.length > widget.previewLimit!)
                    Text(
                      'Showing the ${widget.previewLimit} most recent matching experiences from the loaded posts.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
                if (hasMore) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('load-more-community'),
                    onPressed: () => setState(() => _limit += 50),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: const Text('Load more experiences'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => ref.invalidate(provider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh experiences'),
                ),
              ],
            );
          },
        );
  }
}
