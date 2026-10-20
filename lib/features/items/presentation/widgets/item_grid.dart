import 'package:flutter/material.dart';

import '../../../../shared/models/item.dart';
import '../../../../shared/utils/time_ago.dart';
import '../../../../shared/widgets/pill.dart';
import 'item_image.dart';
import '../../../../core/theme/shapes.dart';

/// Two-column grid of [ItemGridCard]s. Scrollable even when short so
/// pull-to-refresh always works.
class ItemGrid extends StatelessWidget {
  const ItemGrid({super.key, required this.items, required this.onTap, this.pillsFor, this.header});

  final List<Item> items;
  final ValueChanged<Item> onTap;

  /// Pills under each card; defaults to the posted time.
  final List<Widget> Function(Item item)? pillsFor;

  /// Optional content above the grid that scrolls with it.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    // Leave room for the floating navbar.
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 212,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => ItemGridCard(
              item: items[i],
              onTap: () => onTap(items[i]),
              pills: pillsFor?.call(items[i]) ?? [Pill(timeAgo(items[i].createdAt))],
            ),
          ),
        ),
      ],
    );
  }
}

class ItemGridCard extends StatelessWidget {
  const ItemGridCard({super.key, required this.item, required this.onTap, required this.pills});

  final Item item;
  final VoidCallback onTap;
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = item.description;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Squircle(
                radius: 15,
                child: AspectRatio(aspectRatio: 2, child: ItemImage(item: item, iconSize: 32)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          description == null || description.isEmpty ? item.category.label : description,
                          style: textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                child: Wrap(spacing: 4, runSpacing: 4, children: pills),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
