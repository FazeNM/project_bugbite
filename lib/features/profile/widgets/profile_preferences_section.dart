import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class ProfilePreferencesSection extends StatelessWidget {
  const ProfilePreferencesSection({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SectionHeader(title: 'Preferences'),
      Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('App settings'),
          subtitle: const Text('Reminders, accessibility, privacy, and photos'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onOpenSettings,
        ),
      ),
    ],
  );
}
