import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/models/item.dart';
import '../data/items_repository.dart';

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepository(ref.watch(supabaseClientProvider));
});

class FeedFilter {
  const FeedFilter({this.query = '', this.category});

  final String query;
  final ItemCategory? category;
}

class FeedFilterNotifier extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => const FeedFilter();

  void setQuery(String query) => state = FeedFilter(query: query, category: state.category);

  void setCategory(ItemCategory? category) => state = FeedFilter(query: state.query, category: category);
}

final feedFilterProvider = NotifierProvider<FeedFilterNotifier, FeedFilter>(FeedFilterNotifier.new);

final lostItemsProvider = FutureProvider.autoDispose<List<Item>>((ref) {
  final filter = ref.watch(feedFilterProvider);
  return ref
      .watch(itemsRepositoryProvider)
      .fetchLostItems(query: filter.query, category: filter.category);
});

final myItemsProvider = FutureProvider.autoDispose<List<Item>>((ref) {
  return ref.watch(itemsRepositoryProvider).fetchMyItems();
});

final adminItemsProvider = FutureProvider.autoDispose<List<Item>>((ref) {
  return ref.watch(itemsRepositoryProvider).fetchAllItems();
});

final itemDetailProvider = FutureProvider.autoDispose.family<Item?, String>((ref, id) {
  return ref.watch(itemsRepositoryProvider).fetchItem(id);
});

/// Call after creating or deleting an item so every list reloads.
void invalidateItemLists(WidgetRef ref) {
  ref.invalidate(lostItemsProvider);
  ref.invalidate(myItemsProvider);
  ref.invalidate(adminItemsProvider);
  ref.invalidate(itemDetailProvider);
}
