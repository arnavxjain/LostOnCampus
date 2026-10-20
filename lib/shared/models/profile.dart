import 'package:flutter/widgets.dart' show StringCharacters;

import 'user_role.dart';

class Profile {
  const Profile({required this.id, required this.fullName, required this.role, this.email, this.phone});

  final String id;
  final String fullName;
  final UserRole role;
  final String? email;
  final String? phone;

  /// First letter of the name (or email) for the avatar.
  String get initial {
    final source = fullName.trim().isNotEmpty ? fullName.trim() : (email ?? '?');
    return source.characters.first.toUpperCase();
  }
}
