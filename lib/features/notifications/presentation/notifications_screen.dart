import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/snackbar.dart';
import '../../../shared/utils/time_ago.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/sign_out_button.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(onPressed: () => _markAllRead(context, ref), child: const Text('Mark all read')),
          const SignOutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: AsyncView(
          value: notifications,
          onRetry: () => ref.invalidate(notificationsProvider),
          data: (list) => list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    MessageView(
                      icon: Icons.notifications_none,
                      title: 'No notifications yet',
                      subtitle: "We'll let you know here when one of your items is found or collected.",
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _NotificationTile(
                    notification: list[i],
                    onTap: () => _open(context, ref, list[i]),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    if (n.isUnread) {
      // Fire and forget: opening the item shouldn't wait on this.
      ref
          .read(notificationsRepositoryProvider)
          .markRead(n.id)
          .then((_) => ref.invalidate(notificationsProvider), onError: (_) {});
    }
    final itemId = n.itemId;
    if (itemId != null) context.push(Routes.itemDetail(itemId));
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, friendlyError(e));
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = notification.isUnread;

    return ListTile(
      onTap: onTap,
      tileColor: unread ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(notification.type.icon, color: theme.colorScheme.onSecondaryContainer),
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(timeAgo(notification.createdAt), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      trailing: unread
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
            )
          : null,
    );
  }
}
