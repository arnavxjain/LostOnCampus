import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/app_nav_bar.dart';
import '../../items/providers/items_providers.dart';

/// Security staff shell: glass navbar with Desk, Verify and Profile. Keeps the
/// item list live while any tab is open.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    // Refresh when items are found, collected, posted or deleted.
    _channel = ref.read(itemsRepositoryProvider).watchItems(onChange: (_) {
      if (mounted) ref.invalidate(adminItemsProvider);
    });
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) ref.read(itemsRepositoryProvider).stopWatching(channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: AppNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: const [
          AppNavItem(
            label: 'Desk',
            symbol: 'tray.full',
            selectedSymbol: 'tray.full.fill',
            icon: CupertinoIcons.tray,
            selectedIcon: CupertinoIcons.tray_fill,
          ),
          AppNavItem(
            label: 'Verify',
            symbol: 'checkmark.shield',
            selectedSymbol: 'checkmark.shield.fill',
            icon: CupertinoIcons.checkmark_shield,
            selectedIcon: CupertinoIcons.checkmark_shield_fill,
          ),
          AppNavItem(
            label: 'Profile',
            symbol: 'person',
            selectedSymbol: 'person.fill',
            icon: CupertinoIcons.person,
            selectedIcon: CupertinoIcons.person_fill,
          ),
        ],
      ),
    );
  }
}
