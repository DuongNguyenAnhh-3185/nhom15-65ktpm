import 'package:flutter/material.dart';

class AppColors {
  // Brand colors are used for large surfaces, illustrations, and accents.
  static const Color primary = Color(0xFFE05638);
  static const Color secondary = Color(0xFFFACC15);
  static const Color accentYellow = secondary;
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = primary;

  // Accessible foregrounds for text placed on brand-colored surfaces.
  static const Color onPrimary = Color(0xFF111111);
  static const Color onSecondary = Color(0xFF2D3748);
  static const Color onAccentPurple = Color(0xFF000000);
  static const Color primaryText = Color(0xFFB43822);
  static const Color purpleText = Color(0xFF6D28D9);

  // Surfaces
  static const Color background = Color(0xFFF7F9FC);
  static const Color cardBg = Colors.white;
  static const Color surface = Color(0xFFEDF2F7);
  static const Color outline = Color(0xFFCBD5E1);

  // Soroban board
  static const Color abacusFrame = Color(0xFF4A3728);
  static const Color abacusBeam = Color(0xFFD4A373);
  static const Color abacusRod = Color(0xFFC0C0C0);
  static const Color beadUpper = Color(0xFFFF6B6B);
  static const Color beadLower = Color(0xFF4ECDC4);
  static const Color beadActive = Color(0xFFFFD166);
  static const Color unitDot = Color(0xFF2B2D42);

  // Text and status colors
  static const Color textDark = Color(0xFF2D3748);
  static const Color textLight = Color(0xFF536170);
  static const Color success = Color(0xFF176B4D);
  static const Color onSuccess = Colors.white;
  static const Color warning = Color(0xFFFFBF69);
  static const Color onWarning = Color(0xFF2D3748);
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Colors.white;
  static const Color info = Color(0xFF176B87);
}
