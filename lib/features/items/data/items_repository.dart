import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/item.dart';

class ItemsRepository {
  ItemsRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'item-images';
  static const _feedLimit = 100;
  static const _adminLimit = 500;

  /// Item columns plus its latest handover. The code comes back only for the
  /// owner and admins (RLS); for anyone else it is null.
  static const _withHandover = '*, handovers(id, status, note, created_at, code:handover_codes(code))';

  String get _userId => _client.auth.currentUser!.id;

  /// Lost items, newest first, optionally filtered by text and category.
  Future<List<Item>> fetchLostItems({String query = '', ItemCategory? category}) async {
    var request = _client.from('items').select().eq('status', 'lost');
    if (category != null) request = request.eq('category', category.dbValue);

    final term = sanitizeSearch(query);
    if (term.isNotEmpty) {
      request = request.or('title.ilike.*$term*,description.ilike.*$term*');
    }

    final rows = await request.order('created_at').limit(_feedLimit);
    return rows.map(Item.fromJson).toList();
  }

  Future<List<Item>> fetchMyItems() async {
    final rows = await _client
        .from('items')
        .select(_withHandover)
        .eq('owner_id', _userId)
        .order('created_at')
        .order('created_at', referencedTable: 'handovers')
        .limit(1, referencedTable: 'handovers');
    return rows.map(Item.fromJson).toList();
  }

  /// A single item, or null if it doesn't exist or the user can't see it.
  Future<Item?> fetchItem(String id) async {
    final rows = await _client
        .from('items')
        .select(_withHandover)
        .eq('id', id)
        .order('created_at', referencedTable: 'handovers')
        .limit(1, referencedTable: 'handovers')
        .limit(1);
    return rows.isEmpty ? null : Item.fromJson(rows.first);
  }

  /// Every item with its latest handover and code. Admin only (RLS).
  Future<List<Item>> fetchAllItems() async {
    final rows = await _client
        .from('items')
        .select(_withHandover)
        .order('created_at')
        .order('created_at', referencedTable: 'handovers')
        .limit(1, referencedTable: 'handovers')
        .limit(_adminLimit);
    return rows.map(Item.fromJson).toList();
  }

  /// Finder taps "Found": creates the handover and pickup code, and moves the
  /// item to "with security" in one step on the server.
  Future<void> reportFound({required String itemId, required String note}) =>
      _client.rpc('report_found', params: {'p_item_id': itemId, 'p_note': note});

  /// Admin taps "Trace complete" after the owner gives the matching code.
  Future<void> completeHandover({required String handoverId, required String code}) =>
      _client.rpc('complete_handover', params: {'p_handover_id': handoverId, 'p_code': code});

  /// Live changes to items: the owner's own items, or every item visible to
  /// the caller when [ownerId] is null (admins). Stop with [stopWatching].
  RealtimeChannel watchItems({String? ownerId, required void Function(PostgresChangePayload) onChange}) {
    return _client
        .channel('items:${ownerId ?? 'all'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          filter: ownerId == null
              ? null
              : PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'owner_id', value: ownerId),
          callback: onChange,
        )
        .subscribe();
  }

  Future<void> stopWatching(RealtimeChannel channel) => _client.removeChannel(channel);

  /// Uploads the optional image first, then inserts the item. If the insert
  /// fails, the uploaded image is removed again.
  Future<Item> createItem({
    required String title,
    String? description,
    required ItemCategory category,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    String? imagePath;
    String? imageUrl;
    if (imageBytes != null) {
      final ext = (imageExtension ?? 'jpg').toLowerCase();
      imagePath = '$_userId/${DateTime.now().microsecondsSinceEpoch}.$ext';
      await _client.storage.from(_bucket).uploadBinary(
            imagePath,
            imageBytes,
            fileOptions: FileOptions(contentType: _contentType(ext)),
          );
      imageUrl = _client.storage.from(_bucket).getPublicUrl(imagePath);
    }

    try {
      final row = await _client
          .from('items')
          .insert({
            'title': title,
            'description': description,
            'category': category.dbValue,
            'image_url': imageUrl,
          })
          .select()
          .single();
      return Item.fromJson(row);
    } catch (_) {
      if (imagePath != null) await _client.storage.from(_bucket).remove([imagePath]);
      rethrow;
    }
  }

  /// Deletes an item (only allowed by the database while it's still lost) and its image.
  Future<void> deleteItem(Item item) async {
    final deleted = await _client.from('items').delete().eq('id', item.id).select('id');
    if (deleted.isEmpty) {
      throw StateError('This item can no longer be deleted.');
    }
    final path = _storagePath(item.imageUrl);
    if (path != null) {
      // Best effort: the item is already gone, a leftover image is harmless.
      await _client.storage.from(_bucket).remove([path]).catchError((_) => <FileObject>[]);
    }
  }

  static String? _storagePath(String? publicUrl) {
    if (publicUrl == null) return null;
    final marker = '/$_bucket/';
    final i = publicUrl.indexOf(marker);
    return i < 0 ? null : Uri.decodeComponent(publicUrl.substring(i + marker.length));
  }

  static String _contentType(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' || 'heif' => 'image/heic',
        _ => 'image/jpeg',
      };

  /// Removes characters that have meaning in PostgREST filter syntax.
  static String sanitizeSearch(String query) =>
      query.replaceAll(RegExp(r'[,()*%\\:."]'), ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
}
