import 'package:flutter/material.dart';

/// A [FilledButton] with an optional leading icon that shows a spinner and
/// disables itself while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final onPressed = loading ? null : this.onPressed;
    if (loading) {
      return FilledButton(
        onPressed: null,
        child: const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (icon == null) return FilledButton(onPressed: onPressed, child: Text(label));
    return FilledButton.icon(onPressed: onPressed, icon: Icon(icon, size: 20), label: Text(label));
  }
}
