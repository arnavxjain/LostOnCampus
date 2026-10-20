import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

/// Mirrors the `notification_type` enum in the database.
enum NotificationType {
  itemFound(CupertinoIcons.checkmark_shield_fill),
  itemCollected(CupertinoIcons.checkmark_circle_fill);

  const NotificationType(this.icon);

  final IconData icon;

  static NotificationType fromDb(String? value) => value == 'item_collected' ? itemCollected : itemFound;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.itemId,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: NotificationType.fromDb(json['type'] as String?),
        title: json['title'] as String,
        body: json['body'] as String,
        itemId: json['item_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String),
      );

  final String id;
  final NotificationType type;
  final String title;
  final String body;

  /// Null if the item was deleted.
  final String? itemId;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}
