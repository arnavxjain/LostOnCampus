import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';

/// Shown while the signed-in user's role is being resolved.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: role.hasError && !role.isLoading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 16),
                    const Text("Couldn't load your account.", textAlign: TextAlign.center),
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      Text('${role.error}', textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(userRoleProvider),
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () => ref.read(authRepositoryProvider).signOut(),
                      child: const Text('Sign out'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
