import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loc/core/router/app_router.dart';
import 'package:loc/shared/models/user_role.dart';

void main() {
  group('UserRole.fromString', () {
    test('parses admin', () => expect(UserRole.fromString('admin'), UserRole.admin));
    test('old guard value is not an admin', () => expect(UserRole.fromString('guard'), UserRole.student));
    test('defaults unknown/null to student', () {
      expect(UserRole.fromString('superuser'), UserRole.student);
      expect(UserRole.fromString(null), UserRole.student);
    });
  });

  group('resolveRedirect', () {
    String? redirect(
      String location, {
      bool signedIn = true,
      AsyncValue<UserRole?>? role,
    }) =>
        resolveRedirect(
          location: location,
          isSignedIn: signedIn,
          role: role ?? const AsyncData(UserRole.student),
        );

    test('signed-out users are sent to login', () {
      expect(redirect(Routes.home, signedIn: false), Routes.login);
      expect(redirect(Routes.admin, signedIn: false), Routes.login);
      expect(redirect(Routes.login, signedIn: false), isNull);
      expect(redirect(Routes.register, signedIn: false), isNull);
      expect(redirect(Routes.verifyEmail, signedIn: false), isNull);
    });

    test('email verification success goes to role home', () {
      expect(redirect(Routes.verifyEmail), Routes.home);
      expect(redirect(Routes.verifyEmail, role: const AsyncData(UserRole.admin)), Routes.admin);
    });

    test('waits on splash while role loads', () {
      expect(redirect(Routes.home, role: const AsyncLoading()), Routes.splash);
      expect(redirect(Routes.splash, role: const AsyncLoading()), isNull);
    });

    test('students land on home and cannot enter admin area', () {
      expect(redirect(Routes.login), Routes.home);
      expect(redirect(Routes.splash), Routes.home);
      expect(redirect(Routes.admin), Routes.home);
      expect(redirect(Routes.home), isNull);
      expect(redirect(Routes.myPosts), isNull);
      expect(redirect(Routes.notifications), isNull);
      expect(redirect(Routes.postItem), isNull);
      expect(redirect(Routes.itemDetail('x')), isNull);
    });

    test('admins land on and stay in admin area, but can open item details', () {
      const admin = AsyncData<UserRole?>(UserRole.admin);
      expect(redirect(Routes.login, role: admin), Routes.admin);
      expect(redirect(Routes.home, role: admin), Routes.admin);
      expect(redirect(Routes.admin, role: admin), isNull);
      expect(redirect(Routes.myPosts, role: admin), Routes.admin);
      expect(redirect(Routes.itemDetail('x'), role: admin), isNull);
      expect(redirect(Routes.postItem, role: admin), Routes.admin);
      expect(redirect(Routes.notifications, role: admin), Routes.admin);
    });
  });
}
