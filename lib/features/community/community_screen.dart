import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/community_post.dart';
import '../../state/app_controller.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(appControllerProvider).posts;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: <Widget>[
          Text(
            'Shared experiences',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'A supportive place to compare notes—not a place for medical diagnoses.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/add-bite'),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add your experience'),
          ),
          const SizedBox(height: 14),
          const SafetyNotice(compact: true),
          SectionHeader(title: 'Recent from the community'),
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CommunityPostCard(post: post),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPostCard extends ConsumerWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
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
                      post.author.substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.rose,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${post.author} · ${post.location}',
                      style: Theme.of(context).textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _relativeDate(post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(post.body, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: post.tags
                    .map((tag) => GuidePill(label: tag))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: post.liked ? 'Remove like' : 'Support this post',
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .togglePostLike(post.id),
                    icon: Icon(
                      post.liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: post.liked ? AppColors.rose : AppColors.muted,
                    ),
                  ),
                  Text(
                    '${post.likes}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => _showCommentSheet(context),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Comment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  static String _relativeDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  static void _showCommentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Add a supportive comment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Avoid diagnosis claims and personal medical advice. Share what helped you safely instead.',
            ),
            const SizedBox(height: 14),
            TextField(
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write a kind, useful reply…',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Post comment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostVisual extends StatelessWidget {
  const _PostVisual({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    const overlay = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: <Color>[Color(0xA61E1513), Colors.transparent],
        ),
      ),
    );
    final label = Padding(
      padding: const EdgeInsets.all(14),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: GuidePill(label: post.possibleMatch),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (post.imageBytes == null)
          AssetCrop(
            asset: AppAssets.bugBitePairs,
            alignment: visualAlignment(post.visual),
            borderRadius: BorderRadius.zero,
            semanticLabel: 'Visual shared with ${post.possibleMatch}',
          )
        else
          Image.memory(
            post.imageBytes!,
            fit: BoxFit.cover,
            semanticLabel: 'Photo shared with ${post.possibleMatch}',
          ),
        overlay,
        label,
      ],
    );
  }
}
