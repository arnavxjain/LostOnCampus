import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'shared/widgets/app_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Env.load();
    await AppNavBar.checkGlassSupport();
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);
  } catch (e) {
    runApp(_StartupErrorApp(error: e));
    return;
  }

  // No automatic retries: failures show immediately with a Retry button.
  runApp(ProviderScope(retry: (_, _) => null, child: const LostOnCampusApp()));
}

/// Shown instead of the app when configuration is missing or Supabase fails to start.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('App failed to start:\n\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
