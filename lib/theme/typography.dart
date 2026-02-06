import 'package:flutter/material.dart';

/// BJBank Design System Typography
/// Primary: Roboto, Secondary: Roboto Mono (for values/numbers)
class BJBankTypography {
  BJBankTypography._();

  static const String fontFamilyPrimary = 'Roboto';
  static const String fontFamilyMono = 'Roboto Mono';

  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 57,
    height: 64 / 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 45,
    height: 52 / 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // Headline Styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Monospace Styles (for balance, currency values)
  static const TextStyle balanceLarge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle balanceMedium = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle valueMedium = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle valueSmall = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
}
