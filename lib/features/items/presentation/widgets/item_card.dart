import 'package:flutter/material.dart';

import '../../../../shared/models/item.dart';
import '../../../../shared/utils/time_ago.dart';
import 'item_image.dart';
import 'status_chip.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, required this.onTap, this.showStatus = false, this.footer});

  final Item item;
  final VoidCallback onTap;
  final bool showStatus;

  /// Extra content below the main row, e.g. handover info on "My posts".
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.square(dimension: 72, child: ItemImage(item: item, iconSize: 28)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '${item.category.label} · ${timeAgo(item.createdAt)}',
                          style: textTheme.bodySmall,
                        ),
                        if (showStatus) ...[const SizedBox(height: 6), StatusChip(status: item.status)],
                      ],
                    ),
                  ),
                ],
              ),
              if (footer != null) ...[const SizedBox(height: 12), footer!],
            ],
          ),
        ),
      ),
    );
  }
}
