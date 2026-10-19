import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  static const _limit = 100;

  Future<List<AppNotification>> fetchNotifications() async {
    final rows = await _client.from('notifications').select().order('created_at').limit(_limit);
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<void> markRead(String id) => _client
      .from('notifications')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', id)
      .isFilter('read_at', null);

  Future<void> markAllRead() => _client
      .from('notifications')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .isFilter('read_at', null);

  /// Calls [onInsert] for each new notification addressed to [userId].
  /// Stop with [stopWatching].
  RealtimeChannel watchNew({required String userId, required void Function(AppNotification) onInsert}) {
    return _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (payload) => onInsert(AppNotification.fromJson(payload.newRecord)),
        )
        .subscribe();
  }

  Future<void> stopWatching(RealtimeChannel channel) => _client.removeChannel(channel);
}
