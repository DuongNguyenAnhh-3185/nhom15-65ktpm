import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  static ThemeData get kidTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: const Color(0xFFFFDDD5),
      onPrimaryContainer: const Color(0xFF5C1608),
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: const Color(0xFFFFF3C4),
      onSecondaryContainer: const Color(0xFF352900),
      tertiary: AppColors.accentPurple,
      onTertiary: AppColors.onAccentPurple,
      tertiaryContainer: const Color(0xFFEDE3FF),
      onTertiaryContainer: const Color(0xFF2E1065),
      error: AppColors.error,
      onError: AppColors.onError,
      surface: AppColors.background,
      onSurface: AppColors.textDark,
      onSurfaceVariant: AppColors.textLight,
      outline: AppColors.textLight,
      outlineVariant: AppColors.outline,
    );
    final textTheme = GoogleFonts.quicksandTextTheme().copyWith(
      displayLarge: GoogleFonts.quicksand(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
      displayMedium: GoogleFonts.quicksand(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textLight,
      ),
      bodySmall: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textLight,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.minTouchSize,
          ),
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.minTouchSize,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.minTouchSize,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBg,
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primaryText, width: 2),
        ),
        errorStyle: TextStyle(color: colorScheme.error),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
