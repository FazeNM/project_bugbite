import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/seed/seed_data.dart';
import '../../state/app_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final saved = guides
        .where((guide) => state.savedGuideIds.contains(guide.id))
        .toList(growable: false);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Your space',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                onPressed: () => _showSettingsSheet(context),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
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
                    state.displayName.substring(0, 1).toUpperCase(),
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
                      Text(
                        state.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      const Text('Learning carefully, one guide at a time.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _MetricCard(value: '${saved.length}', label: 'Saved guides'),
              const SizedBox(width: 10),
              _MetricCard(
                value:
                    '${state.posts.where((post) => post.author == state.displayName).length}',
                label: 'Shared notes',
              ),
            ],
          ),
          SectionHeader(title: 'Saved visual guides'),
          if (saved.isEmpty)
            const EmptyPanel(
              icon: Icons.bookmark_border_rounded,
              title: 'Nothing saved yet',
              message:
                  'Save a visual guide while browsing and it will stay handy here.',
            )
          else
            SizedBox(
              height: 166,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: saved.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final guide = saved[index];
                  return SizedBox(
                    width: 142,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/guide/${guide.id}'),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: AssetCrop(
                                  asset: AppAssets.commonBites,
                                  alignment: visualAlignment(guide.visual),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(19),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                guide.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          SectionHeader(title: 'Preferences'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
                  title: const Text('Gentle reminders'),
                  subtitle: const Text('Care and safety reminders only'),
                  secondary: const Icon(Icons.notifications_none_rounded),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy and photo controls'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPrivacySheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of BiteWise?'),
        content: const Text(
          'Local saved guides and community drafts are kept only for this session.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(appControllerProvider.notifier).signOut();
              Navigator.pop(dialogContext);
              context.go('/sign-in');
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  static void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.language_rounded),
              title: Text('Language'),
              trailing: Text('English'),
            ),
            ListTile(
              leading: Icon(Icons.accessibility_new_rounded),
              title: Text('Accessibility'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  static void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Privacy first',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            Text(
              'Photos are attached only when you choose to share a post. A production backend should strip metadata and apply moderation before publishing.',
            ),
          ],
        ),
      ),
    );
  }
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
