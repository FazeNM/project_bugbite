import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/seed/seed_data.dart';
import '../../state/app_controller.dart';
import '../../state/profile_data_controller.dart';
import 'widgets/home_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profileData = ref.watch(profileDataProvider);
    return profileData.when(
      loading: () =>
          const ProfileDataLoadingView(photoAsset: AppAssets.honeyBee),
      error: (_, _) => ProfileDataErrorView(
        onRetry: () => ref.read(profileDataProvider.notifier).reload(),
      ),
      data: (profile) => ListView(
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
          if (state.persistenceError case final message?)
            PersistenceWarningCard(
              message: message,
              onRetry: () =>
                  ref.read(appControllerProvider.notifier).retryPersistence(),
            ),
          SectionHeader(
            title: 'Common bite guides',
            actionLabel: 'Use filters',
            onAction: () => context.go('/find'),
          ),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: featuredGuides.length,
              separatorBuilder: (_, _) => const SizedBox(width: 11),
              itemBuilder: (context, index) =>
                  CommonGuideCard(guide: featuredGuides[index]),
            ),
          ),
          if (profile.continueBite != null) ...<Widget>[
            const SectionHeader(title: 'Continue looking'),
            ContinueBiteCard(item: profile.continueBite!),
          ],
          SectionHeader(
            title: profile.recentBites.isEmpty
                ? 'Suggestions from your activity'
                : 'Suggested for you',
            actionLabel: 'Explore',
            onAction: () => context.go('/explore'),
          ),
          if (profile.recommendations.isEmpty)
            const EmptyPanel(
              icon: Icons.auto_awesome_outlined,
              title: 'Nothing personalized yet',
              message:
                  'Open a visual guide and suggestions based on what you viewed will appear here.',
            )
          else
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: profile.recommendations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    SuggestionCard(guide: profile.recommendations[index]),
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
      ),
    );
  }
}
