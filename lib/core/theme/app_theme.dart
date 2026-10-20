import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'shapes.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.teal,
      onPrimary: AppColors.background,
      primaryContainer: AppColors.teal13,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.teal,
      onSecondary: AppColors.background,
      secondaryContainer: AppColors.teal13,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.accent,
      onTertiary: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.background,
      surface: AppColors.background,
      onSurface: AppColors.ink,
      onSurfaceVariant: Color(0x99000000),
      surfaceContainerHighest: AppColors.teal13,
      outline: AppColors.teal36,
      outlineVariant: AppColors.teal32,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.background,
    );

    final base = ThemeData(colorScheme: scheme, scaffoldBackgroundColor: AppColors.background);
    final body = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    // Titles and headings are bold throughout.
    TextStyle? bold(TextStyle? s) => s?.copyWith(fontWeight: FontWeight.w700);
    final text = body.copyWith(
      displayLarge: bold(body.displayLarge),
      displayMedium: bold(body.displayMedium),
      displaySmall: bold(body.displaySmall),
      headlineLarge: bold(body.headlineLarge),
      headlineMedium: bold(body.headlineMedium),
      headlineSmall: bold(body.headlineSmall),
      titleLarge: bold(body.titleLarge),
      titleMedium: bold(body.titleMedium),
      titleSmall: bold(body.titleSmall),
    );

    final pill = AppShapes.pill();
    const field = SquircleInputBorder(borderSide: BorderSide(color: AppColors.teal36));

    return base.copyWith(
      textTheme: text,
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(CupertinoIcons.back),
        closeButtonIconBuilder: (_) => const Icon(CupertinoIcons.xmark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        shape: const Border(bottom: BorderSide(color: AppColors.ink6)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
        errorBorder: field.copyWith(borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: field.copyWith(borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColors.teal,
        suffixIconColor: AppColors.teal,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.teal36,
          disabledForegroundColor: AppColors.background,
          minimumSize: const Size.fromHeight(52),
          shape: pill,
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.teal36),
          minimumSize: const Size.fromHeight(52),
          shape: pill,
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.teal, shape: pill),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(shape: AppShapes.border(14))),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.teal13,
        side: const BorderSide(color: AppColors.teal36),
        shape: pill,
        labelStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        iconTheme: const IconThemeData(color: AppColors.teal, size: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppShapes.border(20, side: const BorderSide(color: AppColors.teal32)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.ink6, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 32, cornerSmoothing: AppShapes.smoothing),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.teal36,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: AppShapes.border(28),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.background),
        actionTextColor: AppColors.background,
        shape: AppShapes.border(16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.teal),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(AppColors.background)),
      ),
      popupMenuTheme: PopupMenuThemeData(color: AppColors.background, shape: AppShapes.border(18)),
    );
  }
}
