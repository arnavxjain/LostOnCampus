import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/shapes.dart';

enum PillTone { teal, solid, accent, muted }

/// Small rounded tag: time, status, pickup code.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.icon, this.tone = PillTone.teal, this.large = false});

  final String label;
  final IconData? icon;
  final PillTone tone;

  /// Bigger text, for pickup codes.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.teal => (AppColors.teal13, AppColors.teal),
      PillTone.solid => (AppColors.teal, AppColors.background),
      PillTone.accent => (AppColors.accent, AppColors.ink),
      PillTone.muted => (AppColors.ink6, AppColors.ink),
    };
    final style = (large ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.labelSmall)?.copyWith(
      color: fg,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: large ? 1.5 : null,
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: large ? 5 : 4),
      decoration: ShapeDecoration(color: bg, shape: AppShapes.pill()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: large ? 16 : 13, color: fg), const SizedBox(width: 4)],
          Flexible(child: Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
