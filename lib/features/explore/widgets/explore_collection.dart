import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_guide.dart';
import '../../../data/seed/seed_data.dart';
import 'bite_photo_card.dart';

class ExploreCollection extends StatelessWidget {
  const ExploreCollection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.categories,
    this.guideIds = const <String>{},
  });

  final String title;
  final String subtitle;
  final Set<String> categories;
  final Set<String> guideIds;

  @override
  Widget build(BuildContext context) {
    final selection = guides
        .where((guide) {
          if (guideIds.isNotEmpty) return guideIds.contains(guide.id);
          return categories.contains(guide.category);
        })
        .toList(growable: false);
    final photos = <({BiteGuide guide, GuideMedia media})>[];
    // Interleave types so a larger mosquito collection cannot hide the others.
    var photoIndex = 0;
    while (selection.any((guide) => guide.bitePhotos.length > photoIndex)) {
      for (final guide in selection) {
        if (guide.bitePhotos.length > photoIndex) {
          photos.add((guide: guide, media: guide.bitePhotos[photoIndex]));
        }
      }
      photoIndex++;
    }
    final withoutPhotos = selection.where((guide) => guide.bitePhotos.isEmpty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        return CustomScrollView(
          key: PageStorageKey('explore-$title'),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    GuidePill(label: '${photos.length} real photo examples'),
                    const SizedBox(height: 12),
                    const Text(
                      'Photos show individual experiences. Similar-looking marks can have different causes.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    if (photos.isEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      const EmptyPanel(
                        icon: Icons.photo_library_outlined,
                        title: 'No skin photo available yet',
                        message:
                            'You can still read the guides below. We never substitute unrelated skin pictures.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: (photos.length / columns).ceil(),
                itemBuilder: (context, row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (
                        var column = 0;
                        column < columns;
                        column++
                      ) ...<Widget>[
                        if (column > 0) const SizedBox(width: 12),
                        Expanded(
                          child: row * columns + column < photos.length
                              ? BitePhotoCard(
                                  guide: photos[row * columns + column].guide,
                                  media: photos[row * columns + column].media,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (withoutPhotos.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'More guides · skin photo not yet available',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList.list(
                children: withoutPhotos
                    .map(
                      (guide) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(guide.title),
                        subtitle: const Text('Read the guide'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/guide/${guide.id}'),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        );
      },
    );
  }
}
