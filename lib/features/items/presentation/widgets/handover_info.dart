import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../shared/models/item.dart';
import '../../../../core/theme/shapes.dart';

/// Owner-facing summary of where their item is and the pickup code.
/// Renders nothing while the item is still lost.
class HandoverInfo extends StatelessWidget {
  const HandoverInfo({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handover = item.handover;
    final note = handover?.note ?? '';

    return switch (item.status) {
      ItemStatus.lost => const SizedBox.shrink(),
      ItemStatus.atSecurity => _Banner(
          icon: CupertinoIcons.checkmark_shield_fill,
          text: 'Found! It was handed to security.',
          detail: note.isEmpty ? null : 'Finder\'s note: $note',
          footer: Column(
            children: [
              const SizedBox(height: 8),
              Text('Give the guard this code to collect it:', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              handover?.code == null
                  ? Text('Code not available yet. Pull to refresh.', style: theme.textTheme.bodySmall)
                  : SelectableText(
                      spacedCode(handover!.code!),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ],
          ),
        ),
      ItemStatus.returned => const _Banner(icon: CupertinoIcons.checkmark_circle_fill, text: 'Collected. Glad you got it back!'),
    };
  }
}

/// "123456" -> "123 456" for readability.
String spacedCode(String code) => code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, this.detail, this.footer});

  final IconData icon;
  final String text;
  final String? detail;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppShapes.decoration(color: scheme.secondaryContainer, r: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                    if (detail != null) ...[const SizedBox(height: 4), Text(detail!, style: TextStyle(color: color))],
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) Center(child: footer),
        ],
      ),
    );
  }
}
