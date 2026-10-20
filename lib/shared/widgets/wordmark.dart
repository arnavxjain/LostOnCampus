import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// "LostOnCampus" in the brand style, with an accent dot.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'LostOnCampus',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.teal,
                fontWeight: FontWeight.w800,
                fontSize: size,
                letterSpacing: -0.5,
              ),
        ),
        SizedBox(width: size * 0.18),
        Container(
          width: size * 0.32,
          height: size * 0.32,
          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
        ),
      ],
    );
  }
}
