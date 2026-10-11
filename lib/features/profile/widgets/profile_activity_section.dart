import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_guide.dart';
import '../../../data/models/profile_bite_data.dart';

class ProfileActivitySection extends StatelessWidget {
  const ProfileActivitySection({
    required this.profileData,
    required this.onRetry,
    required this.onOpenGuide,
    super.key,
  });

  final AsyncValue<ProfileBiteData> profileData;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenGuide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SectionHeader(title: 'Your bite activity'),
      profileData.when(
        loading: () => const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => LoadErrorPanel(
          title: 'Bite activity is unavailable',
          message: "We couldn't load your recent guides. Please try again.",
          onRetry: onRetry,
        ),
        data: (data) =>
            _ProfileActivityContent(data: data, onOpenGuide: onOpenGuide),
      ),
    ],
  );
}

class _ProfileActivityContent extends StatelessWidget {
  const _ProfileActivityContent({
    required this.data,
    required this.onOpenGuide,
  });

  final ProfileBiteData data;
  final ValueChanged<String> onOpenGuide;

  @override
  Widget build(BuildContext context) {
    if (data.recentBites.isEmpty) {
      return const EmptyPanel(
        icon: Icons.history_rounded,
        title: 'No recent guides',
        message:
            'Open a visual guide and it will appear here for quick access.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (data.continueBite case final continueBite?) ...<Widget>[
          Text(
            'Continue looking',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _ProfileContinueCard(
            item: continueBite,
            onTap: () => onOpenGuide(continueBite.guide.id),
          ),
          const SizedBox(height: 18),
        ],
        Text('Recently viewed', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...data.recentBites.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _RecentBiteCard(
              item: item,
              onTap: () => onOpenGuide(item.guide.id),
            ),
          ),
        ),
        if (data.recommendations.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            'Similar to what you viewed',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final guide = data.recommendations[index];
                return _ProfileRecommendationCard(
                  guide: guide,
                  onTap: () => onOpenGuide(guide.id),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileContinueCard extends StatelessWidget {
  const _ProfileContinueCard({required this.item, required this.onTap});

  final BiteHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.roseSoft,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(19),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 74,
              height: 74,
              child: AssetCrop(
                asset: item.guide.thumbnail.asset,
                borderRadius: BorderRadius.circular(15),
                semanticLabel: item.guide.thumbnail.semanticLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.guide.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Last opened ${_profileRelativeTime(item.lastViewedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(5),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.rose),
          ],
        ),
      ),
    ),
  );
}

class _RecentBiteCard extends StatelessWidget {
  const _RecentBiteCard({required this.item, required this.onTap});

  final BiteHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      leading: SizedBox(
        width: 58,
        height: 58,
        child: AssetCrop(
          asset: item.guide.thumbnail.asset,
          borderRadius: BorderRadius.circular(13),
          semanticLabel: item.guide.thumbnail.semanticLabel,
        ),
      ),
      title: Text(
        item.guide.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('Viewed ${_profileRelativeTime(item.lastViewedAt)}'),
      trailing: item.isComplete
          ? const Icon(Icons.check_circle_rounded, color: AppColors.safe)
          : Text(
              '${(item.progress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.rose,
                fontWeight: FontWeight.w800,
              ),
            ),
    ),
  );
}

class _ProfileRecommendationCard extends StatelessWidget {
  const _ProfileRecommendationCard({required this.guide, required this.onTap});

  final BiteGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 138,
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: AssetCrop(
                  asset: guide.thumbnail.asset,
                  borderRadius: BorderRadius.zero,
                  semanticLabel: guide.thumbnail.semanticLabel,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                guide.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _profileRelativeTime(DateTime viewedAt) {
  final difference = DateTime.now().difference(viewedAt);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'yesterday';
  return '${difference.inDays}d ago';
}
