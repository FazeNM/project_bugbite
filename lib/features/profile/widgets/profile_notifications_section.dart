import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/community_notification.dart';
import '../../../data/services/community_repository.dart';
import '../../../state/auth_controller.dart';
import '../../../state/community_providers.dart';

class ProfileNotificationsSection extends ConsumerStatefulWidget {
  const ProfileNotificationsSection({super.key});

  @override
  ConsumerState<ProfileNotificationsSection> createState() =>
      _ProfileNotificationsSectionState();
}

class _ProfileNotificationsSectionState
    extends ConsumerState<ProfileNotificationsSection> {
  int _limit = 50;
  String? _openingId;

  Future<void> _open(CommunityNotification notification) async {
    if (_openingId != null) return;
    setState(() => _openingId = notification.id);
    var markedRead = true;
    if (!notification.isRead) {
      markedRead = await ref
          .read(communityActionsProvider.notifier)
          .markNotificationRead(notificationId: notification.id);
    }
    if (!mounted) return;
    setState(() => _openingId = null);
    if (ref.read(currentUserProvider)?.id != notification.recipientId) return;
    if (!markedRead) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(communityActionsProvider).errorMessage ??
                'This notification could not be marked as read. You can still open the conversation.',
          ),
        ),
      );
    }
    await context.push(
      Uri(
        pathSegments: ['', 'community', 'post', notification.postId],
        queryParameters: {'comment': notification.commentId},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = communityNotificationsProvider(_limit);
    final unreadCount =
        ref.watch(communityUnreadNotificationCountProvider).asData?.value ?? 0;
    final busy = ref.watch(communityActionsProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            if (unreadCount > 0)
              Semantics(
                label: unreadCount >= 100
                    ? '99 or more unread notifications'
                    : '$unreadCount unread notifications',
                child: Container(
                  key: const ValueKey('profile-unread-notification-count'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rose,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    unreadCount >= 100 ? '99+' : '$unreadCount new',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Replies appear here when you open the app. Phone notifications are coming soon.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ref
            .watch(provider)
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Loading notifications',
                  ),
                ),
              ),
              error: (error, _) => LoadErrorPanel(
                title: 'Notifications could not load',
                message: error is CommunityException
                    ? error.message
                    : 'Check your connection and try again. Your notifications have not been removed.',
                onRetry: () => ref.invalidate(provider),
              ),
              data: (notifications) => notifications.isEmpty
                  ? const EmptyPanel(
                      icon: Icons.notifications_none_rounded,
                      title: 'You’re all caught up',
                      message:
                          'When someone comments on your post or replies to your comment, you’ll see it here.',
                    )
                  : Column(
                      children: <Widget>[
                        for (final notification in notifications)
                          _NotificationTile(
                            notification: notification,
                            opening: _openingId == notification.id,
                            onTap: _openingId != null || busy
                                ? null
                                : () => _open(notification),
                          ),
                        if (notifications.length >= _limit)
                          OutlinedButton.icon(
                            key: const ValueKey('load-more-notifications'),
                            onPressed: () => setState(() => _limit += 50),
                            icon: const Icon(Icons.expand_more_rounded),
                            label: const Text('Load older notifications'),
                          ),
                      ],
                    ),
            ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.opening,
    required this.onTap,
  });

  final CommunityNotification notification;
  final bool opening;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = notification.createdAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final timestamp =
        '${localizations.formatCompactDate(date)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    final action = notification.isReply
        ? 'replied to your comment'
        : 'commented on your post';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: notification.isRead ? Colors.white : AppColors.roseSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          key: ValueKey('notification-${notification.id}'),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Icon(
            notification.isReply
                ? Icons.reply_rounded
                : Icons.chat_bubble_outline_rounded,
            color: AppColors.rose,
          ),
          title: Text(
            '${notification.actorName} $action',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: notification.isRead
                  ? FontWeight.w500
                  : FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            '${notification.isRead ? '' : 'Unread · '}$timestamp',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: opening
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
