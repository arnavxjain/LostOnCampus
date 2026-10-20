import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../shared/models/item.dart';
import '../../../shared/utils/time_ago.dart';
import '../../../shared/widgets/pill.dart';
import '../../items/presentation/widgets/handover_info.dart';

/// Pills on admin cards: the pickup code while with security, otherwise when
/// the item was posted or that it was collected.
List<Widget> adminPills(Item item) => switch (item.status) {
      ItemStatus.atSecurity => [
          if (item.handover?.code case final code?) Pill(spacedCode(code), icon: CupertinoIcons.number, tone: PillTone.solid),
          if (item.handover case final h?) Pill(timeAgo(h.createdAt)),
        ],
      ItemStatus.lost => [Pill(timeAgo(item.createdAt))],
      ItemStatus.returned => [const Pill('Collected', icon: CupertinoIcons.checkmark, tone: PillTone.muted)],
    };
