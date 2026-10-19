import 'package:flutter_test/flutter_test.dart';
import 'package:loc/shared/utils/time_ago.dart';

void main() {
  final now = DateTime(2026, 10, 19, 12);

  test('relative times', () {
    expect(timeAgo(now.subtract(const Duration(seconds: 30)), now: now), 'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
    expect(timeAgo(now.subtract(const Duration(days: 2)), now: now), '2d ago');
  });

  test('older than a week shows the date', () {
    expect(timeAgo(DateTime(2026, 3, 12), now: now), '12 Mar');
  });
}
