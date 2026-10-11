import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/community_config.dart';
import '../../core/navigation/navigation_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../state/app_controller.dart';
import 'widgets/settings_group.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to profile',
          onPressed: () => popOrGo(context, '/profile'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: <Widget>[
            Text(
              'Make BiteWise comfortable for you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (state.persistenceError case final message?)
              PersistenceWarningCard(
                message: message,
                onRetry: controller.retryPersistence,
              ),
            const SectionHeader(title: 'General'),
            SettingsGroup(
              children: <Widget>[
                SwitchListTile(
                  value: state.gentleReminders,
                  onChanged: (value) async {
                    final saved = await controller.setGentleReminders(value);
                    if (!context.mounted || saved) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'That preference could not be saved. Please try again.',
                        ),
                      ),
                    );
                  },
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Gentle reminders'),
                  subtitle: const Text('Care and safety reminders only'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.language_rounded),
                  title: Text('Language'),
                  trailing: Text('English'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.accessibility_new_rounded),
                  title: Text('Accessibility'),
                  subtitle: Text('Uses your system text and contrast settings'),
                ),
              ],
            ),
            const SectionHeader(title: 'Privacy and photos'),
            SettingsGroup(
              children: <Widget>[
                const ListTile(
                  leading: Icon(Icons.verified_user_outlined),
                  title: Text(
                    communityPhotoUploadsEnabled
                        ? 'Photo metadata protection is on'
                        : 'Photo uploads · Coming soon',
                  ),
                  subtitle: Text(
                    communityPhotoUploadsEnabled
                        ? 'Shared photos are re-encoded as JPEGs with metadata removed before upload.'
                        : 'Reference photos remain available. You can still share text experiences.',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.phonelink_lock_outlined),
                  title: Text('Private notes and shared posts'),
                  subtitle: Text(
                    'Private notes, saves, and history stay on this device for your signed-in account. Published community posts are shared with other signed-in members.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SafetyNotice(),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.info_outline_rounded, color: AppColors.rose),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'BiteWise suggestions and community posts are educational. They are never a confirmed diagnosis.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
