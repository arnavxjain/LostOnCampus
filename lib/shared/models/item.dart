import 'package:flutter/material.dart';

/// Mirrors the `item_category` enum in the database.
enum ItemCategory {
  electronics('Electronics', Icons.devices),
  idCard('ID card', Icons.badge),
  keys('Keys', Icons.key),
  wallet('Wallet', Icons.account_balance_wallet),
  bag('Bag', Icons.backpack),
  clothing('Clothing', Icons.checkroom),
  books('Books', Icons.menu_book),
  bottle('Bottle', Icons.water_drop),
  other('Other', Icons.category);

  const ItemCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// The database value, e.g. `id_card`.
  String get dbValue => this == idCard ? 'id_card' : name;

  static ItemCategory fromDb(String? value) =>
      values.firstWhere((c) => c.dbValue == value, orElse: () => other);
}

/// Mirrors the `item_status` enum in the database.
enum ItemStatus {
  lost('Lost'),
  atSecurity('With security'),
  returned('Returned');

  const ItemStatus(this.label);

  final String label;

  static ItemStatus fromDb(String? value) => switch (value) {
        'at_security' => atSecurity,
        'returned' => returned,
        _ => lost,
      };
}

/// Mirrors the `handover_status` enum in the database.
enum HandoverStatus {
  atSecurity,
  collected;

  static HandoverStatus fromDb(String? value) => value == 'collected' ? collected : atSecurity;
}

/// The latest handover of an item: created when a finder taps "Found".
class ItemHandover {
  const ItemHandover({
    required this.id,
    required this.status,
    required this.note,
    required this.createdAt,
    this.code,
  });

  factory ItemHandover.fromJson(Map<String, dynamic> json) => ItemHandover(
        id: json['id'] as String,
        status: HandoverStatus.fromDb(json['status'] as String?),
        note: json['note'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        code: (json['code'] as Map<String, dynamic>?)?['code'] as String?,
      );

  final String id;
  final HandoverStatus status;

  /// The finder's note saying which security desk has the item.
  final String note;
  final DateTime createdAt;

  /// The 6-digit pickup code. Only readable by the item's owner and admins;
  /// always null for the finder and everyone else.
  final String? code;
}

class Item {
  const Item({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.category,
    required this.status,
    required this.createdAt,
    this.description,
    this.imageUrl,
    this.handover,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final handovers = (json['handovers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return Item(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: ItemCategory.fromDb(json['category'] as String?),
      imageUrl: json['image_url'] as String?,
      status: ItemStatus.fromDb(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      handover: handovers.isEmpty ? null : ItemHandover.fromJson(handovers.first),
    );
  }

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final ItemCategory category;
  final String? imageUrl;
  final ItemStatus status;
  final DateTime createdAt;

  /// Most recent handover, when the viewer is allowed to see it (owner, finder,
  /// admin). The pickup code is only present for the owner and admins.
  final ItemHandover? handover;
}
