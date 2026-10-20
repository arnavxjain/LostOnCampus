import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/utils/snackbar.dart';
import '../../../shared/widgets/app_nav_bar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../providers/items_providers.dart';

/// Student shell: glass navbar with Home, My posts and Alerts, a "+" button
/// to post, and a live ping when a new notification arrives.
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
      extendBody: true,
      body: shell,
      bottomNavigationBar: AppNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        onAction: () => context.push(Routes.postItem),
        actionLabel: 'Post lost item',
        items: [
          const AppNavItem(
            label: 'Home',
            symbol: 'house',
            selectedSymbol: 'house.fill',
            icon: CupertinoIcons.house,
            selectedIcon: CupertinoIcons.house_fill,
          ),
          const AppNavItem(
            label: 'My posts',
            symbol: 'square.grid.2x2',
            selectedSymbol: 'square.grid.2x2.fill',
            icon: CupertinoIcons.square_grid_2x2,
            selectedIcon: CupertinoIcons.square_grid_2x2_fill,
          ),
          AppNavItem(
            label: 'Alerts',
            symbol: 'bell',
            selectedSymbol: 'bell.fill',
            icon: CupertinoIcons.bell,
            selectedIcon: CupertinoIcons.bell_fill,
            badge: unread,
          ),
        ],
      ),
    );
  }
}
