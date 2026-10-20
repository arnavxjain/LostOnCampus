import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/item.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/filter_chips.dart';
import '../../../shared/widgets/search_field.dart';
import '../providers/items_providers.dart';
import 'widgets/item_grid.dart';

/// Student home: search, category chips and a grid of lost items.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final TextEditingController _search;
  Timer? _debounce;

  static final _categoryOptions = [
    const FilterOption<ItemCategory?>(null, 'All', icon: CupertinoIcons.square_grid_2x2),
    for (final c in ItemCategory.values) FilterOption<ItemCategory?>(c, c.label, icon: c.icon),
  ];

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(feedFilterProvider).query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // toggles the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(feedFilterProvider.notifier).setQuery(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() {});
    ref.read(feedFilterProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(feedFilterProvider);
    final items = ref.watch(lostItemsProvider);
    final isFiltered = filter.query.trim().isNotEmpty || filter.category != null;

    return Scaffold(
      appBar: const AppHeader(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SearchField(
              controller: _search,
              hintText: 'Search lost items',
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          FilterChips<ItemCategory?>(
            options: _categoryOptions,
            selected: filter.category,
            onSelected: (c) => ref.read(feedFilterProvider.notifier).setCategory(c),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(lostItemsProvider.future),
              child: AsyncView(
                value: items,
                onRetry: () => ref.invalidate(lostItemsProvider),
                data: (list) => list.isEmpty
                    ? ListView(
                        // Scrollable so pull-to-refresh still works when empty.
                        children: [
                          const SizedBox(height: 64),
                          MessageView(
                            icon: isFiltered ? CupertinoIcons.search : CupertinoIcons.sparkles,
                            title: isFiltered ? 'No matching items' : 'Nothing lost right now',
                            subtitle: isFiltered
                                ? 'Try a different search or category.'
                                : 'Lost something? Tap + to post it.',
                          ),
                        ],
                      )
                    : ItemGrid(items: list, onTap: (item) => context.push(Routes.itemDetail(item.id))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
