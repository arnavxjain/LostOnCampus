import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../shared/models/item.dart';
import '../../../../shared/widgets/pill.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ItemStatus.lost => Pill(status.label, tone: PillTone.accent),
      ItemStatus.atSecurity => Pill(status.label, icon: CupertinoIcons.checkmark_shield_fill, tone: PillTone.solid),
      ItemStatus.returned => Pill(status.label, icon: CupertinoIcons.checkmark, tone: PillTone.muted),
    };
  }
}
