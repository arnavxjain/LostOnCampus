import 'package:flutter_test/flutter_test.dart';
import 'package:loc/shared/models/app_notification.dart';

void main() {
  final base = {
    'id': 'n1',
    'user_id': 'u1',
    'item_id': 'i1',
    'type': 'item_found',
    'title': 'Your item was found!',
    'body': '"Keys" was handed to security.',
    'read_at': null,
    'created_at': '2026-10-20T09:00:00Z',
  };

  test('parses an unread item_found notification', () {
    final n = AppNotification.fromJson(base);
    expect(n.type, NotificationType.itemFound);
    expect(n.itemId, 'i1');
    expect(n.isUnread, isTrue);
  });

  test('parses a read item_collected notification', () {
    final n = AppNotification.fromJson({...base, 'type': 'item_collected', 'read_at': '2026-10-20T10:00:00Z'});
    expect(n.type, NotificationType.itemCollected);
    expect(n.isUnread, isFalse);
  });

  test('item may be gone', () {
    expect(AppNotification.fromJson({...base, 'item_id': null}).itemId, isNull);
  });
}
