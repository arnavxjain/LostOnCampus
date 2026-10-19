import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/item.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/snackbar.dart';
import '../../../shared/utils/time_ago.dart';
import '../../../shared/widgets/async_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/items_providers.dart';
import 'widgets/found_sheet.dart';
import 'widgets/handover_info.dart';
import 'widgets/item_image.dart';
import 'widgets/status_chip.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemDetailProvider(itemId));
    final userId = ref.watch(currentUserIdProvider);
    final role = ref.watch(userRoleProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item'),
        actions: [
          if (item.value case final i? when i.ownerId == userId && i.status == ItemStatus.lost)
            IconButton(
              tooltip: 'Delete post',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, i),
            ),
        ],
      ),
      body: AsyncView(
        value: item,
        onRetry: () => ref.invalidate(itemDetailProvider(itemId)),
        data: (i) => i == null
            ? const MessageView(
                icon: Icons.visibility_off_outlined,
                title: 'This item is no longer available',
                subtitle: 'It may have been found or removed.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(itemDetailProvider(itemId).future),
                child: _ItemDetails(item: i, isOwner: i.ownerId == userId),
              ),
      ),
      bottomNavigationBar: switch (item.value) {
        // Anyone but the owner (and not security staff) can report a lost item found.
        final i? when i.status == ItemStatus.lost && i.ownerId != userId && role == UserRole.student =>
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton.icon(
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('I Found This'),
                onPressed: () => _reportFound(context, ref, i),
              ),
            ),
          ),
        _ => null,
      },
    );
  }

  Future<void> _reportFound(BuildContext context, WidgetRef ref, Item item) async {
    final reported = await showFoundSheet(context, item);
    if (!reported || !context.mounted) return;
    invalidateItemLists(ref);
    showFoundThanks(context);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this post?'),
        content: Text('"${item.title}" will be removed from the lost items list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(itemsRepositoryProvider).deleteItem(item);
      if (!context.mounted) return;
      invalidateItemLists(ref);
      showInfoSnackBar(context, 'Post deleted');
      context.pop();
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, friendlyError(e));
    }
  }
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.item, required this.isOwner});

  final Item item;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = item.description;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        AspectRatio(aspectRatio: 4 / 3, child: ItemImage(item: item, iconSize: 64)),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(status: item.status),
                  Chip(
                    avatar: Icon(item.category.icon, size: 18),
                    label: Text(item.category.label),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${isOwner ? 'You posted this' : 'Posted'} ${timeAgo(item.createdAt)}',
                style: textTheme.bodySmall,
              ),
              if (isOwner && item.status != ItemStatus.lost) ...[
                const SizedBox(height: 16),
                HandoverInfo(item: item),
              ] else if (item.handover case final h?) ...[
                // Finder and admins: where the item was left (never the code for finders).
                const SizedBox(height: 16),
                Text('Finder\'s note', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(h.note, style: textTheme.bodyLarge),
              ],
              const SizedBox(height: 20),
              Text('Description', style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                description == null || description.isEmpty ? 'No description provided.' : description,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
