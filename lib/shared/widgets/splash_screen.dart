import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import 'wordmark.dart';

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
                    Icon(CupertinoIcons.wifi_slash, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    const Text("Couldn't load your account.", textAlign: TextAlign.center),
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      Text('${role.error}', textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(userRoleProvider),
                      icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                      label: const Text('Retry'),
                    ),
                    TextButton.icon(
                      onPressed: () => ref.read(authRepositoryProvider).signOut(),
                      icon: const Icon(CupertinoIcons.square_arrow_right, size: 18),
                      label: const Text('Sign out'),
                    ),
                  ],
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Wordmark(), SizedBox(height: 28), CircularProgressIndicator()],
                ),
        ),
      ),
    );
  }
}
