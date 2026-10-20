import 'package:flutter_test/flutter_test.dart';
import 'package:loc/features/guard/presentation/otp_match.dart';
import 'package:loc/shared/models/item.dart';

Item _item(String id, String status, String? code) => Item.fromJson({
      'id': id,
      'owner_id': 'u',
      'title': id,
      'category': 'other',
      'status': status,
      'created_at': '2026-10-20T09:00:00Z',
      'handovers': code == null
          ? []
          : [
              {
                'id': 'h-$id',
                'status': status == 'returned' ? 'collected' : 'at_security',
                'note': 'desk',
                'created_at': '2026-10-20T10:00:00Z',
                'code': {'code': code},
              },
            ],
    });

void main() {
  final atSecurity = [_item('bottle', 'at_security', '123456'), _item('keys', 'at_security', '129999')];
  final returned = [_item('wallet', 'returned', '555555')];

  OtpMatch match(String typed) => matchOtp(typed: typed, atSecurity: atSecurity, returned: returned);

  test('empty input lists everything at security', () {
    expect(match('').matches, hasLength(2));
    expect(match('').noMatch, isFalse);
  });

  test('partial input narrows by prefix', () {
    expect(match('12').matches, hasLength(2));
    expect(match('123').matches.single.title, 'bottle');
  });

  test('exact code matches exactly one item', () {
    final r = match('129999');
    expect(r.matches.single.title, 'keys');
    expect(r.noMatch, isFalse);
  });

  test('a full wrong code matches nothing: hand nothing over', () {
    final r = match('000000');
    expect(r.noMatch, isTrue);
    expect(r.alreadyUsed, isFalse);
  });

  test('a code from an already-collected item is flagged as used', () {
    final r = match('555555');
    expect(r.noMatch, isTrue);
    expect(r.alreadyUsed, isTrue);
  });

  test('partial input never reports "already used"', () {
    expect(match('5555').alreadyUsed, isFalse);
  });
}
