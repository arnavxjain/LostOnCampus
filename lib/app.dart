import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/utils/snackbar.dart';

class LostOnCampusApp extends ConsumerWidget {
  const LostOnCampusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lost on Campus',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      // The palette is light-only by design.
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
