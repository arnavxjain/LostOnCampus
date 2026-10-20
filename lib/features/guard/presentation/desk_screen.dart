import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/item.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/filter_chips.dart';
import '../../items/presentation/widgets/item_grid.dart';
import '../../items/providers/items_providers.dart';
import 'admin_pills.dart';
import 'trace_complete_sheet.dart';

/// Security desk: every item, filtered by status, each with its pickup code.
class DeskScreen extends ConsumerStatefulWidget {
  const DeskScreen({super.key});

  @override
  ConsumerState<DeskScreen> createState() => _DeskScreenState();
}

class _DeskScreenState extends ConsumerState<DeskScreen> {
  ItemStatus _status = ItemStatus.atSecurity;

  Future<void> _open(Item item) async {
    if (item.status != ItemStatus.atSecurity) {
      await context.push(Routes.itemDetail(item.id));
      return;
    }
    final done = await showTraceCompleteSheet(context, item);
    if (!done || !mounted) return;
    invalidateItemLists(ref);
    showTraceCompleteDone(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(adminItemsProvider);
    final all = items.value ?? const <Item>[];
    int countOf(ItemStatus s) => all.where((i) => i.status == s).length;

    return Scaffold(
      appBar: const AppHeader(showAvatar: false),
      body: Column(
        children: [
          const SizedBox(height: 16),
          FilterChips<ItemStatus>(
            options: [
              FilterOption(
                ItemStatus.atSecurity,
                'With security (${countOf(ItemStatus.atSecurity)})',
                icon: CupertinoIcons.checkmark_shield,
              ),
              FilterOption(ItemStatus.lost, 'Lost (${countOf(ItemStatus.lost)})', icon: CupertinoIcons.search),
              FilterOption(
                ItemStatus.returned,
                'Returned (${countOf(ItemStatus.returned)})',
                icon: CupertinoIcons.checkmark_circle,
              ),
            ],
            selected: _status,
            onSelected: (s) => setState(() => _status = s),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(adminItemsProvider.future),
              child: AsyncView(
                value: items,
                onRetry: () => ref.invalidate(adminItemsProvider),
                data: (_) {
                  final shown = all.where((i) => i.status == _status).toList();
                  if (shown.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 64),
                        MessageView(
                          icon: CupertinoIcons.tray,
                          title: switch (_status) {
                            ItemStatus.atSecurity => 'Nothing at security right now',
                            ItemStatus.lost => 'No items are waiting to be found',
                            ItemStatus.returned => 'No items have been collected yet',
                          },
                        ),
                      ],
                    );
                  }
                  return ItemGrid(items: shown, pillsFor: adminPills, onTap: _open);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
