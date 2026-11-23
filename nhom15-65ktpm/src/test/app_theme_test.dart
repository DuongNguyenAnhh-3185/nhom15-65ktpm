import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('brand and text color pairs meet WCAG AA contrast', () {
    final theme = AppTheme.kidTheme;
    final scheme = theme.colorScheme;

    expect(_contrastRatio(scheme.primary, scheme.onPrimary),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(scheme.secondary, scheme.onSecondary),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(scheme.tertiary, scheme.onTertiary),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.background, AppColors.textDark),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.background, AppColors.textLight),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.background, AppColors.primaryText),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.background, AppColors.purpleText),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.success, AppColors.onSuccess),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.warning, AppColors.onWarning),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.error, AppColors.onError),
        greaterThanOrEqualTo(4.5));
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance > secondLuminance ? secondLuminance : firstLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}
