import 'package:flutter_test/flutter_test.dart';
import 'package:loc/shared/utils/validators.dart';

void main() {
  test('email', () {
    expect(Validators.email('a@b.co'), isNull);
    expect(Validators.email(' a@b.co '), isNull);
    expect(Validators.email('nope'), isNotNull);
    expect(Validators.email(''), isNotNull);
  });

  test('password length', () {
    expect(Validators.password('12345678'), isNull);
    expect(Validators.password('1234567'), isNotNull);
  });

  test('phone requires E.164 and tolerates formatting', () {
    expect(Validators.phone('+919876543210'), isNull);
    expect(Validators.phone('+91 98765-43210'), isNull);
    expect(Validators.phone('9876543210'), isNotNull);
    expect(Validators.phone('+0123456789'), isNotNull);
    expect(Validators.normalizePhone('+1 (555) 123-4567'), '+15551234567');
  });

  test('otp must be 6 digits', () {
    expect(Validators.otp('123456'), isNull);
    expect(Validators.otp('12345'), isNotNull);
    expect(Validators.otp('12a456'), isNotNull);
  });

  test('full name', () {
    expect(Validators.fullName('Al'), isNull);
    expect(Validators.fullName(' '), isNotNull);
  });
}
