import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../shared/models/item.dart';
import '../../../../shared/widgets/pill.dart';
import 'handover_info.dart';
import 'status_chip.dart';

/// Pills for an owner's own item: its status, plus the pickup code while it's
/// with security.
List<Widget> ownerPills(Item item) => [
      StatusChip(status: item.status),
      if (item.status == ItemStatus.atSecurity && item.handover?.code != null)
        Pill(spacedCode(item.handover!.code!), icon: CupertinoIcons.number),
    ];
