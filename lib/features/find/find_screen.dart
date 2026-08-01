import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_guide.dart';
import '../../data/seed/seed_data.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({super.key});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  final Set<String> _selectedTags = <String>{};

  static const _filters = <_FilterOption>[
    _FilterOption('Red', 'red', Icons.circle_outlined),
    _FilterOption('Itchy', 'itchy', Icons.touch_app_outlined),
    _FilterOption('Raised', 'raised', Icons.landscape_outlined),
    _FilterOption('Cluster', 'cluster', Icons.hub_outlined),
    _FilterOption('In a line', 'line', Icons.linear_scale_rounded),
    _FilterOption('Painful', 'painful', Icons.bolt_outlined),
    _FilterOption('Attached tick', 'tick', Icons.location_on_outlined),
  ];

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
                  children: _filters.map((filter) {
                    final selected = _selectedTags.contains(filter.value);
                    return FilterChip(
                      avatar: Icon(
                        filter.icon,
                        size: 16,
                        color: selected ? Colors.white : AppColors.rose,
                      ),
                      selected: selected,
                      label: Text(filter.label),
                      onSelected: (active) => setState(() {
                        if (active) {
                          _selectedTags.add(filter.value);
                        } else {
                          _selectedTags.remove(filter.value);
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
          if (matches.isEmpty)
            const EmptyPanel(
              icon: Icons.search_off_rounded,
              title: 'No close visual guide',
              message:
                  'Try removing one filter, or ask a clinician if you are worried about the symptoms.',
            )
          else
            ...matches.map(
              (guide) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MatchCard(guide: guide),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/add-bite'),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Share your experience instead'),
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.guide});

  final BiteGuide guide;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/guide/${guide.id}'),
      child: Ink(
        height: 128,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 118,
              height: double.infinity,
              child: AssetCrop(
                asset: AppAssets.commonBites,
                alignment: visualAlignment(guide.visual),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(21),
                ),
                semanticLabel: 'Visual example for ${guide.title}',
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GuidePill(label: guide.category),
                    const Spacer(),
                    Text(
                      guide.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      guide.pattern,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right_rounded, color: AppColors.rose),
            ),
          ],
        ),
      ),
    ),
  );
}
