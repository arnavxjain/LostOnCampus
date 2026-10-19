import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/item.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/sign_out_button.dart';
import '../providers/items_providers.dart';
import 'widgets/handover_info.dart';
import 'widgets/item_card.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(myItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My posts'), actions: const [SignOutButton()]),
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
                      icon: Icons.inventory_2_outlined,
                      title: "You haven't posted anything",
                      subtitle: "Lost something? Post it and we'll let you know when it's found.",
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => ItemCard(
                    item: list[i],
                    showStatus: true,
                    footer: list[i].status == ItemStatus.lost ? null : HandoverInfo(item: list[i]),
                    onTap: () => context.push(Routes.itemDetail(list[i].id)),
                  ),
                ),
        ),
      ),
    );
  }
}
