import 'package:flutter_test/flutter_test.dart';
import 'package:loc/features/items/data/items_repository.dart';
import 'package:loc/features/items/presentation/widgets/handover_info.dart';
import 'package:loc/shared/models/item.dart';

void main() {
  group('ItemCategory', () {
    test('round-trips database values', () {
      for (final c in ItemCategory.values) {
        expect(ItemCategory.fromDb(c.dbValue), c);
      }
      expect(ItemCategory.idCard.dbValue, 'id_card');
    });
    test('unknown falls back to other', () => expect(ItemCategory.fromDb('spaceship'), ItemCategory.other));
  });

  test('ItemStatus parses database values', () {
    expect(ItemStatus.fromDb('lost'), ItemStatus.lost);
    expect(ItemStatus.fromDb('at_security'), ItemStatus.atSecurity);
    expect(ItemStatus.fromDb('returned'), ItemStatus.returned);
  });

  group('Item.fromJson', () {
    final base = {
      'id': 'i1',
      'owner_id': 'u1',
      'title': 'Keys',
      'description': null,
      'category': 'keys',
      'image_url': null,
      'status': 'lost',
      'created_at': '2026-10-19T10:00:00Z',
    };

    test('feed row without handovers', () {
      final item = Item.fromJson(base);
      expect(item.title, 'Keys');
      expect(item.category, ItemCategory.keys);
      expect(item.handover, isNull);
    });

    test('owner/admin row with handover note and code', () {
      final item = Item.fromJson({
        ...base,
        'status': 'at_security',
        'handovers': [
          {
            'id': 'h1',
            'status': 'at_security',
            'note': 'Floor 2 security desk',
            'created_at': '2026-10-19T11:00:00Z',
            'code': {'code': '123456'},
          },
        ],
      });
      expect(item.status, ItemStatus.atSecurity);
      expect(item.handover!.note, 'Floor 2 security desk');
      expect(item.handover!.code, '123456');
      expect(item.handover!.status, HandoverStatus.atSecurity);
    });

    test('finder sees the note but never a code', () {
      final item = Item.fromJson({
        ...base,
        'status': 'at_security',
        'handovers': [
          {'id': 'h1', 'status': 'at_security', 'note': 'Ground floor', 'created_at': '2026-10-19T11:00:00Z', 'code': null},
        ],
      });
      expect(item.handover!.code, isNull);
      expect(item.handover!.note, 'Ground floor');
    });

    test('collected handover', () {
      final item = Item.fromJson({
        ...base,
        'status': 'returned',
        'handovers': [
          {'id': 'h1', 'status': 'collected', 'note': 'x desk', 'created_at': '2026-10-19T11:00:00Z', 'code': {'code': '000123'}},
        ],
      });
      expect(item.status, ItemStatus.returned);
      expect(item.handover!.status, HandoverStatus.collected);
    });
  });

  test('search terms are stripped of PostgREST filter syntax', () {
    expect(ItemsRepository.sanitizeSearch('  blue,  bottle (steel) '), 'blue bottle steel');
    expect(ItemsRepository.sanitizeSearch('100%*'), '100');
    expect(ItemsRepository.sanitizeSearch('a.b:c"d\\e'), 'a b c d e');
  });

  test('codes are shown in two groups of three', () {
    expect(spacedCode('012345'), '012 345');
    expect(spacedCode('12'), '12');
  });
}
