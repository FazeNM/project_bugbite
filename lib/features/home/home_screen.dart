import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_guide.dart';
import '../../data/seed/seed_data.dart';
import '../../state/app_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: <Widget>[
        Text(
          'YOUR BITE GUIDE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.rose,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Good morning,\n${state.displayName}.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a visual guide, compare what you notice, and use suggestions with care.',
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        SectionHeader(
          title: 'Common bite guides',
          actionLabel: 'Use filters',
          onAction: () => context.go('/find'),
        ),
        _CommonGuideButton(guide: guides[0]),
        const SizedBox(height: 9),
        _CommonGuideButton(guide: guides[1]),
        SectionHeader(
          title: 'Suggested for you',
          actionLabel: 'Explore',
          onAction: () => context.go('/explore'),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _SuggestionCard(guide: guides[index]),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => context.go('/find'),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Find possible matches'),
        ),
        const SizedBox(height: 14),
        const SafetyNotice(compact: true),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.go('/community'),
          child: Ink(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.forum_outlined, color: AppColors.rose),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Want to compare experiences? Visit the community when you’re ready.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommonGuideButton extends StatelessWidget {
  const _CommonGuideButton({required this.guide});

  final BiteGuide guide;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/guide/${guide.id}'),
    borderRadius: BorderRadius.circular(18),
    child: Ink(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 58,
            height: 58,
            child: AssetCrop(
              asset: AppAssets.commonBites,
              alignment: visualAlignment(guide.visual),
              borderRadius: BorderRadius.circular(15),
              semanticLabel: 'Visual example for ${guide.title}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  guide.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  guide.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.guide});

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
              asset: AppAssets.commonBites,
              alignment: visualAlignment(guide.visual),
              borderRadius: BorderRadius.circular(21),
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
