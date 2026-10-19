import 'package:flutter/material.dart';

import '../../../../shared/models/item.dart';

/// The item's photo, or its category icon when there is none or it fails to load.
class ItemImage extends StatelessWidget {
  const ItemImage({super.key, required this.item, this.iconSize = 32});

  final Item item;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(child: Icon(item.category.icon, size: iconSize, color: scheme.outline)),
    );

    final url = item.imageUrl;
    if (url == null) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
