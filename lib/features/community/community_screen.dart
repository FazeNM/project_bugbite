import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_filters.dart';
import 'widgets/community_post_results.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({
    super.key,
    this.selectedTags = const <String>{},
    this.authorId,
  });

  final Set<String> selectedTags;
  final String? authorId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: <Widget>[
          Text(
            authorId == null
                ? 'Shared experiences'
                : 'Your published experiences',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'A supportive place to compare notes—not a place for medical diagnoses.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (selectedTags.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Your selected filters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  key: const ValueKey('clear-community-filters'),
                  onPressed: () => context.go('/community'),
                  child: const Text('Clear filters'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedTags.map((tag) {
                return InputChip(
                  key: ValueKey('community-filter-$tag'),
                  label: Text(BiteFilters.labelFor(tag)),
                  onDeleted: () => context.go(
                    BiteFilters.communityLocation(
                      selectedTags.where((id) => id != tag),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Showing only posts whose authors selected all these observations.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/add-bite'),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Add your experience'),
          ),
          const SizedBox(height: 14),
          if (authorId != null)
            TextButton.icon(
              onPressed: () => context.go('/community'),
              icon: const Icon(Icons.people_outline_rounded),
              label: const Text('See the whole community'),
            ),
          const SafetyNotice(compact: true),
          SectionHeader(
            title: selectedTags.isEmpty
                ? 'Recent from the community'
                : 'Matching community experiences',
          ),
          CommunityPostResults(selectedTags: selectedTags, authorId: authorId),
        ],
      ),
    );
  }
}
