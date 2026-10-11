import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_filters.dart';
import '../../data/seed/seed_data.dart';
import '../community/widgets/community_post_results.dart';
import 'widgets/match_card.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({super.key});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  final Set<String> _selectedTags = <String>{};

  @override
  Widget build(BuildContext context) {
    final matches = guides
        .where((guide) => _selectedTags.every(guide.filterTags.contains))
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: <Widget>[
          Text(
            'Find a possible match',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Pick what you notice. We will narrow visual guides—not make a diagnosis.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'What do you notice?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (_selectedTags.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(_selectedTags.clear),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 9,
                  children: BiteFilters.symptoms.map((filter) {
                    final selected = _selectedTags.contains(filter.id);
                    return FilterChip(
                      key: ValueKey('find-tag-${filter.id}'),
                      avatar: Icon(
                        _filterIcon(filter.id),
                        size: 16,
                        color: selected ? Colors.white : AppColors.rose,
                      ),
                      selected: selected,
                      label: Text(filter.label),
                      onSelected: (active) => setState(() {
                        if (active) {
                          _selectedTags.add(filter.id);
                        } else {
                          _selectedTags.remove(filter.id);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SafetyNotice(compact: true),
          SectionHeader(
            title: _selectedTags.isEmpty
                ? 'Browse visual guides'
                : '${matches.length} possible guide${matches.length == 1 ? '' : 's'}',
          ),
          if (matches.isEmpty) ...<Widget>[
            const EmptyPanel(
              icon: Icons.search_off_rounded,
              title: 'No close visual guide',
              message:
                  'There is no guide with all these observations. You can compare community experiences below, or remove a filter. Ask a clinician if symptoms concern you.',
            ),
            const SectionHeader(title: 'Matching community experiences'),
            Text(
              'Posts must include every filter you selected. These are personal reports, not confirmed identifications.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            CommunityPostResults(selectedTags: _selectedTags, previewLimit: 3),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('view-matching-community'),
              onPressed: () =>
                  context.go(BiteFilters.communityLocation(_selectedTags)),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('View matching community posts'),
            ),
          ] else
            ...matches.map(
              (guide) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchCard(guide: guide),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/add-bite'),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Share your experience instead'),
          ),
        ],
      ),
    );
  }
}

IconData _filterIcon(String id) => switch (id) {
  'red' => Icons.circle_outlined,
  'itchy' => Icons.touch_app_outlined,
  'raised' => Icons.landscape_outlined,
  'cluster' => Icons.hub_outlined,
  'line' => Icons.linear_scale_rounded,
  'painful' => Icons.bolt_outlined,
  'swollen' => Icons.blur_circular_rounded,
  'blister' => Icons.bubble_chart_outlined,
  'scalp' => Icons.face_retouching_natural,
  'lower-leg' => Icons.directions_walk_rounded,
  'tick' => Icons.location_on_outlined,
  'stinger' => Icons.gps_fixed_rounded,
  _ => Icons.check_circle_outline,
};
