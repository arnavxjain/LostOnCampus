import 'package:flutter/material.dart';

/// Lets code without a BuildContext under the app's Scaffold (e.g. realtime
/// callbacks) show snackbars.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showErrorSnackBar(BuildContext context, String message) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: scheme.onError)),
      backgroundColor: scheme.error,
    ));
}

void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
