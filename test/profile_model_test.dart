import 'package:flutter_test/flutter_test.dart';
import 'package:loc/shared/models/profile.dart';
import 'package:loc/shared/models/user_role.dart';

void main() {
  Profile p(String name, {String? email}) => Profile(id: 'u', fullName: name, role: UserRole.student, email: email);

  test('avatar initial comes from the name', () => expect(p('arnav jain').initial, 'A'));
  test('falls back to the email', () => expect(p('  ', email: 'zoe@x.com').initial, 'Z'));
  test('falls back to ? with nothing', () => expect(p('').initial, '?'));
}
