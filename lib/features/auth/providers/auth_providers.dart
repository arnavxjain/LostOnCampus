import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/models/user_role.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider).auth);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// The signed-in user, refreshed on every auth event.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

/// The signed-in user's id, or null when signed out.
///
/// Only changes on sign-in / sign-out / user switch, not on token refresh,
/// so dependants don't refetch every time the access token rotates.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

/// Role of the signed-in user from `profiles.role`, or null when signed out.
final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  // A list query rather than maybeSingle(): maybeSingle() replaces PostgREST
  // error codes with the HTTP status, which hides the real cause.
  try {
    final rows = await ref
        .watch(supabaseClientProvider)
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .limit(1);
    return UserRole.fromString(rows.isEmpty ? null : rows.first['role'] as String?);
  } catch (e) {
    debugPrint('Failed to load role: $e');
    rethrow;
  }
});
