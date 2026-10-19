import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/item.dart';
import '../../../shared/utils/time_ago.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/sign_out_button.dart';
import '../../items/presentation/widgets/handover_info.dart';
import '../../items/presentation/widgets/item_image.dart';
import '../../items/providers/items_providers.dart';
import 'trace_complete_sheet.dart';

/// Security staff dashboard: every item with its pickup code. Type the code
/// the owner gives to find the matching item, then complete the trace.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  final _code = TextEditingController();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    // Refresh live when items are found, collected, posted or deleted.
    _channel = ref.read(itemsRepositoryProvider).watchItems(onChange: (_) {
      if (mounted) ref.invalidate(adminItemsProvider);
    });
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) ref.read(itemsRepositoryProvider).stopWatching(channel);
    _code.dispose();
    super.dispose();
  }

  Future<void> _openTrace(Item item) async {
    final done = await showTraceCompleteSheet(context, item, initialCode: _code.text);
    if (!done || !mounted) return;
    _code.clear();
    setState(() {});
    invalidateItemLists(ref);
    showTraceCompleteDone(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(adminItemsProvider);
    final all = items.value ?? const <Item>[];
    final withSecurity = all.where((i) => i.status == ItemStatus.atSecurity).toList();
    final lost = all.where((i) => i.status == ItemStatus.lost).toList();
    final returned = all.where((i) => i.status == ItemStatus.returned).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Security desk'),
          actions: const [SignOutButton()],
          bottom: TabBar(
            tabs: [
              Tab(text: 'With security (${withSecurity.length})'),
              Tab(text: 'Lost (${lost.length})'),
              Tab(text: 'Returned (${returned.length})'),
            ],
          ),
        ),
        body: AsyncView(
          value: items,
          onRetry: () => ref.invalidate(adminItemsProvider),
          data: (_) => TabBarView(
            children: [
              _withSecurityTab(withSecurity, returned),
              _list(lost, empty: 'No items are waiting to be found.'),
              _list(returned, empty: 'No items have been collected yet.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _withSecurityTab(List<Item> withSecurity, List<Item> returned) {
    final typed = _code.text;
    final matches = typed.isEmpty
        ? withSecurity
        : withSecurity.where((i) => i.handover?.code?.startsWith(typed) ?? false).toList();
    final fullCode = typed.length == 6;
    final alreadyUsed = fullCode && matches.isEmpty && returned.any((i) => i.handover?.code == typed);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Enter the owner's 6-digit code",
              prefixIcon: const Icon(Icons.pin),
              suffixIcon: typed.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_code.clear),
                    ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(adminItemsProvider.future),
            child: matches.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 48),
                      if (fullCode)
                        MessageView(
                          icon: Icons.block,
                          title: alreadyUsed ? 'This code was already used' : 'No item matches ${spacedCode(typed)}',
                          subtitle: alreadyUsed
                              ? 'That item has already been collected.'
                              : "Don't hand anything over. Ask the owner to check the code in their app.",
                        )
                      else
                        MessageView(
                          icon: typed.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
                          title: typed.isEmpty ? 'Nothing at security right now' : 'No codes start with $typed',
                        ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: matches.length,
                    itemBuilder: (_, i) => _AdminItemTile(
                      item: matches[i],
                      highlight: fullCode,
                      onTap: () => _openTrace(matches[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _list(List<Item> items, {required String empty}) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminItemsProvider.future),
      child: items.isEmpty
          ? ListView(children: [const SizedBox(height: 48), MessageView(icon: Icons.inbox_outlined, title: empty)])
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (_, i) => _AdminItemTile(
                item: items[i],
                onTap: () => context.push(Routes.itemDetail(items[i].id)),
              ),
            ),
    );
  }
}

class _AdminItemTile extends StatelessWidget {
  const _AdminItemTile({required this.item, required this.onTap, this.highlight = false});

  final Item item;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handover = item.handover;
    final subtitle = switch (item.status) {
      ItemStatus.atSecurity => handover?.note ?? '',
      ItemStatus.lost => 'Posted ${timeAgo(item.createdAt)} · not found yet',
      ItemStatus.returned => 'Collected',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      color: highlight ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(dimension: 64, child: ItemImage(item: item, iconSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item.category.label, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (handover?.code case final code? when item.status != ItemStatus.lost) ...[
                const SizedBox(width: 8),
                Text(
                  spacedCode(code),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    decoration: item.status == ItemStatus.returned ? TextDecoration.lineThrough : null,
                    color: item.status == ItemStatus.returned ? theme.colorScheme.outline : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
