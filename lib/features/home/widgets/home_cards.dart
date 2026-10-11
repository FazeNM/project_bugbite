import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_guide.dart';
import '../../../data/models/profile_bite_data.dart';

class ContinueBiteCard extends StatelessWidget {
  const ContinueBiteCard({super.key, required this.item});

  final BiteHistoryItem item;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: () => context.push('/guide/${item.guide.id}'),
      child: SizedBox(
        height: 126,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 116,
              height: double.infinity,
              child: AssetCrop(
                asset: item.guide.thumbnail.asset,
                borderRadius: BorderRadius.zero,
                semanticLabel: item.guide.thumbnail.semanticLabel,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GuidePill(
                      label: 'Viewed ${_relativeTime(item.lastViewedAt)}',
                    ),
                    const Spacer(),
                    Text(
                      item.guide.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(5),
                      backgroundColor: AppColors.roseSoft,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${(item.progress * 100).round()}% reviewed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.arrow_forward_rounded, color: AppColors.rose),
            ),
          ],
        ),
      ),
    ),
  );
}

class CommonGuideCard extends StatelessWidget {
  const CommonGuideCard({super.key, required this.guide});

  final BiteGuide guide;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 156,
    child: InkWell(
      onTap: () => context.push('/guide/${guide.id}'),
      borderRadius: BorderRadius.circular(19),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: AssetCrop(
                  asset: guide.thumbnail.asset,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  semanticLabel: guide.thumbnail.semanticLabel,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 8, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          guide.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          guide.kind.label,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: AppColors.rose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({super.key, required this.guide});

  final BiteGuide guide;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/guide/${guide.id}'),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AssetCrop(
              asset: guide.thumbnail.asset,
              borderRadius: BorderRadius.circular(21),
              semanticLabel: guide.thumbnail.semanticLabel,
              overlay: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: .74),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    guide.category.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFFFD6D0),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    guide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guide.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFEFEB),
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _relativeTime(DateTime viewedAt) {
  final difference = DateTime.now().difference(viewedAt);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'yesterday';
  return '${difference.inDays}d ago';
}
