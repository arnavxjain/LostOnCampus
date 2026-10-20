import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/snackbar.dart';
import '../../../shared/utils/time_ago.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/pill.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      appBar: AppHeader(
        title: 'Alerts',
        actions: [
          if (unread > 0) TextButton.icon(
              onPressed: () => _markAllRead(context, ref),
              icon: const Icon(CupertinoIcons.checkmark_alt, size: 18),
              label: const Text('Mark all read'),
            ),
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
                      icon: CupertinoIcons.bell,
                      title: 'No alerts yet',
                      subtitle: "We'll let you know here when one of your items is found or collected.",
                    ),
                  ],
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _NotificationCard(
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unread = notification.isUnread;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: unread ? AppColors.teal13 : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.teal13, shape: BoxShape.circle),
                child: Icon(notification.type.icon, color: AppColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: textTheme.titleSmall?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(notification.body, style: textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Pill(timeAgo(notification.createdAt)),
                  ],
                ),
              ),
              if (unread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
