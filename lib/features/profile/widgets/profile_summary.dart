import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          'Your space',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      IconButton(
        tooltip: 'Open settings',
        onPressed: onOpenSettings,
        icon: const Icon(Icons.settings_outlined),
      ),
    ],
  );
}

class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({required this.displayName, super.key});

  final String displayName;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFFF4D9D0), Color(0xFFE1AEB0)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: <Widget>[
        CircleAvatar(
          radius: 31,
          backgroundColor: Colors.white.withValues(alpha: .78),
          child: Text(
            displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.rose,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(displayName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              const Text('Learning carefully, one guide at a time.'),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProfileMetricsRow extends StatelessWidget {
  const ProfileMetricsRow({
    required this.savedGuideCount,
    required this.sharedNoteCount,
    super.key,
  });

  final int savedGuideCount;
  final int sharedNoteCount;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _MetricCard(value: '$savedGuideCount', label: 'Saved guides'),
      const SizedBox(width: 10),
      _MetricCard(value: '$sharedNoteCount', label: 'Shared notes'),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.rose),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
