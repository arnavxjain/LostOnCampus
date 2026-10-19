import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/item.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/sign_out_button.dart';
import '../providers/items_providers.dart';
import 'widgets/item_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final TextEditingController _search;
  Timer? _debounce;

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
      appBar: AppBar(title: const Text('Lost items'), actions: const [SignOutButton()]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search lost items',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(tooltip: 'Clear', icon: const Icon(Icons.close), onPressed: _clearSearch),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: filter.category == null,
                  onSelected: () => ref.read(feedFilterProvider.notifier).setCategory(null),
                ),
                for (final c in ItemCategory.values)
                  _CategoryChip(
                    label: c.label,
                    icon: c.icon,
                    selected: filter.category == c,
                    onSelected: () => ref.read(feedFilterProvider.notifier).setCategory(c),
                  ),
              ],
            ),
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
                          const SizedBox(height: 80),
                          MessageView(
                            icon: isFiltered ? Icons.search_off : Icons.celebration_outlined,
                            title: isFiltered ? 'No matching items' : 'Nothing lost right now',
                            subtitle: isFiltered ? 'Try a different search or category.' : 'Lost something? Post it below.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: list.length,
                        itemBuilder: (context, i) => ItemCard(
                          item: list[i],
                          onTap: () => context.push(Routes.itemDetail(list[i].id)),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onSelected, this.icon});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon == null || selected ? null : Icon(icon, size: 18),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
