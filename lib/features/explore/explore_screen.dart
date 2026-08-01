import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_guide.dart';
import '../../data/seed/seed_data.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'VISUAL LIBRARY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.rose,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Explore bite guides',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 7),
            const Text(
              'Browse image-led examples by place and preference.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
      TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.muted,
        indicator: BoxDecoration(
          color: AppColors.rose,
          borderRadius: BorderRadius.circular(18),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 15),
        tabs: const <Widget>[
          Tab(text: 'For you'),
          Tab(text: 'Outdoors'),
          Tab(text: 'At home'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: const <Widget>[
            _ExploreCollection(
              title: 'For you',
              subtitle: 'Visual guides picked to get you started.',
              categories: <String>{'Outdoors', 'At home'},
            ),
            _ExploreCollection(
              title: 'Outdoor guides',
              subtitle: 'Gardens, parks, trails, and after-dusk time outside.',
              categories: <String>{'Outdoors'},
            ),
            _ExploreCollection(
              title: 'At-home guides',
              subtitle: 'Bedroom, pet, and indoor concerns.',
              categories: <String>{'At home'},
            ),
          ],
        ),
      ),
    ],
  );
}

class _ExploreCollection extends StatelessWidget {
  const _ExploreCollection({
    required this.title,
    required this.subtitle,
    required this.categories,
  });

  final String title;
  final String subtitle;
  final Set<String> categories;

  @override
  Widget build(BuildContext context) {
    final selection = guides
        .where((guide) => categories.contains(guide.category))
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        _ContextHero(categories: categories),
        SectionHeader(title: title),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...selection.map(
          (guide) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExploreGuideCard(guide: guide),
          ),
        ),
      ],
    );
  }
}

class _ContextHero extends StatelessWidget {
  const _ContextHero({required this.categories});

  final Set<String> categories;

  @override
  Widget build(BuildContext context) {
    final outdoors =
        categories.contains('Outdoors') && !categories.contains('At home');
    final atHome =
        categories.contains('At home') && !categories.contains('Outdoors');
    final alignment = outdoors
        ? Alignment.topLeft
        : atHome
        ? Alignment.bottomLeft
        : Alignment.topRight;
    final headline = outdoors
        ? 'Notice the setting, too.'
        : atHome
        ? 'Start with calm observation.'
        : 'Picture-led guidance, not certainty.';
    return SizedBox(
      height: 200,
      child: AssetCrop(
        asset: AppAssets.careContexts,
        alignment: alignment,
        overlay: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Colors.transparent,
                Colors.black.withValues(alpha: .7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreGuideCard extends StatelessWidget {
  const _ExploreGuideCard({required this.guide});

  final BiteGuide guide;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/guide/${guide.id}'),
    borderRadius: BorderRadius.circular(22),
    child: Ink(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AssetCrop(
            asset: AppAssets.commonBites,
            alignment: visualAlignment(guide.visual),
            overlay: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: .78),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        guide.category.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFFFD6D0),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        guide.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guide.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFEFEB),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
