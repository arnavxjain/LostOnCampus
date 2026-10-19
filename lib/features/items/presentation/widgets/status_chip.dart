import 'package:flutter/material.dart';

import '../../../../shared/models/item.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      ItemStatus.lost => (scheme.errorContainer, scheme.onErrorContainer),
      ItemStatus.atSecurity => (scheme.primaryContainer, scheme.onPrimaryContainer),
      ItemStatus.returned => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
    );
  }
}
