import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/utils/snackbar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../providers/items_providers.dart';

/// Student shell: bottom navigation between the feed, "My posts" and
/// notifications, a shared "Post lost item" button, and a live ping when a new
/// notification arrives.
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      _channel = ref.read(notificationsRepositoryProvider).watchNew(userId: userId, onInsert: _onNotification);
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) ref.read(notificationsRepositoryProvider).stopWatching(channel);
    super.dispose();
  }

  void _onNotification(AppNotification n) {
    if (!mounted) return;
    ref.invalidate(notificationsProvider);
    ref.invalidate(myItemsProvider);
    ref.invalidate(lostItemsProvider);
    final itemId = n.itemId;
    if (itemId != null) ref.invalidate(itemDetailProvider(itemId));

    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('${n.title} ${n.body}'),
        action: itemId == null
            ? null
            : SnackBarAction(label: 'View', onPressed: () => context.push(Routes.itemDetail(itemId))),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: shell,
      floatingActionButton: shell.currentIndex == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(Routes.postItem),
              icon: const Icon(Icons.add),
              label: const Text('Post lost item'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.search), label: 'Lost items'),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'My posts',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
