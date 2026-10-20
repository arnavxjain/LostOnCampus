import 'package:flutter/material.dart';

/// The app palette. Opacity variants are part of the design spec, not ad hoc.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF000000);
  static const teal = Color(0xFF007D81);
  static const background = Color(0xFFF6FEFF);
  static const accent = Color(0xFFFF8B8B);

  /// Chip outlines and field borders.
  static const teal36 = Color(0x5C007D81);

  /// Card outlines.
  static const teal32 = Color(0x52007D81);

  /// Pill fills, selected chips, banners.
  static const teal13 = Color(0x21007D81);

  /// Dividers and subtle surfaces.
  static const ink6 = Color(0x0F000000);

  /// Errors aren't in the palette; this red keeps them readable on [background].
  static const error = Color(0xFFB3261E);
}
