import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/async_view.dart';
import '../providers/items_providers.dart';
import 'widgets/item_grid.dart';
import 'widgets/owner_pills.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(myItemsProvider);

    return Scaffold(
      appBar: const AppHeader(title: 'My posts'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myItemsProvider.future),
        child: AsyncView(
          value: items,
          onRetry: () => ref.invalidate(myItemsProvider),
          data: (list) => list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    MessageView(
                      icon: CupertinoIcons.tray,
                      title: "You haven't posted anything",
                      subtitle: "Lost something? Tap + and we'll let you know when it's found.",
                    ),
                  ],
                )
              : ItemGrid(
                  items: list,
                  pillsFor: ownerPills,
                  onTap: (item) => context.push(Routes.itemDetail(item.id)),
                ),
        ),
      ),
    );
  }
}
