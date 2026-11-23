import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('brand and text color pairs meet WCAG AA contrast', () {
    expect(_contrastRatio(AppColors.primary, AppColors.onPrimary),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.secondary, AppColors.onSecondary),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.accentPurple, AppColors.onAccentPurple),
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

  test('progress and status graphics meet WCAG non-text contrast', () {
    final progressTrack = Color.alphaBlend(
      AppColors.surface.withValues(alpha: 0.9),
      Colors.white,
    );
    expect(_contrastRatio(AppColors.primary, progressTrack),
        greaterThanOrEqualTo(3));

    final statusPairs = [
      (AppColors.success, AppColors.success),
      (AppColors.onWarning, AppColors.warning),
      (AppColors.error, AppColors.error),
      (AppColors.info, AppColors.info),
    ];
    for (final (foreground, background) in statusPairs) {
      final tintedBackground = Color.alphaBlend(
        background.withValues(alpha: 0.16),
        Colors.white,
      );
      expect(
        _contrastRatio(foreground, tintedBackground),
        greaterThanOrEqualTo(3),
      );
    }
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
