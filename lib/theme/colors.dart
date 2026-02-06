import 'package:flutter/material.dart';

/// BJBank Design System Colors
/// Blue-based palette with PQC security theme
/// All colors must be referenced from here - never hardcode colors in screens
class BJBankColors {
  BJBankColors._();

  // ─── Primary Colors (Blue) ───
  static const Color primary = Color(0xFF1A3BF5);
  static const Color primaryLight = Color(0xFFD6DEFF);
  static const Color primaryDark = Color(0xFF0A1FA0);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD6DEFF);
  static const Color onPrimaryContainer = Color(0xFF001062);

  // ─── Secondary Colors ───
  static const Color secondary = Color(0xFF565E71);
  static const Color secondaryLight = Color(0xFFDAE2F9);
  static const Color secondaryDark = Color(0xFF131C2E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDAE2F9);
  static const Color onSecondaryContainer = Color(0xFF131C2E);

  // ─── Tertiary Colors (Blue-Green / Teal) ───
  static const Color tertiary = Color(0xFF006B5F);
  static const Color tertiaryLight = Color(0xFFB2F0E5);
  static const Color tertiaryDark = Color(0xFF00382F);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB2F0E5);
  static const Color onTertiaryContainer = Color(0xFF00201A);

  // ─── Semantic Colors - Success ───
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color successDark = Color(0xFF2E7D32);

  // ─── Semantic Colors - Warning ───
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color warningDark = Color(0xFFEF6C00);

  // ─── Semantic Colors - Error ───
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorLight = Color(0xFFFFDAD6);
  static const Color errorDark = Color(0xFF93000A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // ─── Semantic Colors - Info ───
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFBBDEFB);
  static const Color infoDark = Color(0xFF1565C0);

  // ─── Light Theme Neutrals ───
  static const Color surface = Color(0xFFFAFBFF);
  static const Color surfaceVariant = Color(0xFFE0E3EF);
  static const Color onSurface = Color(0xFF1A1C22);
  static const Color onSurfaceVariant = Color(0xFF44474E);
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6D0);
  static const Color background = Color(0xFFFAFBFF);
  static const Color onBackground = Color(0xFF1A1C22);

  // ─── Dark Theme Neutrals ───
  static const Color surfaceDark = Color(0xFF111318);
  static const Color surfaceVariantDark = Color(0xFF44474E);
  static const Color onSurfaceDark = Color(0xFFE2E2E9);
  static const Color backgroundDark = Color(0xFF111318);
  static const Color onBackgroundDark = Color(0xFFE2E2E9);
  static const Color primaryContainerDark = Color(0xFF002FC9);
  static const Color onPrimaryContainerDark = Color(0xFFD6DEFF);
  static const Color outlineDark = Color(0xFF8E9099);
  static const Color outlineVariantDark = Color(0xFF44474E);

  // ─── PQC Security Colors ───
  static const Color quantum = Color(0xFF00BCD4);
  static const Color quantumLight = Color(0xFFE0F7FA);
  static const Color encrypted = Color(0xFF8BC34A);
  static const Color encryptedLight = Color(0xFFF1F8E9);
  static const Color shield = Color(0xFF3F51B5);
  static const Color shieldLight = Color(0xFFE8EAF6);
  static const Color verified = Color(0xFF009688);
  static const Color verifiedLight = Color(0xFFE0F2F1);

  // ─── Brand Colors ───
  static const Color mbwayRed = Color(0xFFE31837);

  // ─── Card Chip Colors ───
  static const Color chipGold = Color(0xFFD4AF37);
  static const Color chipGoldLight = Color(0xFFF5D060);
  static const Color chipGoldDark = Color(0xFFB8860B);

  // ─── Splash Screen Colors ───
  static const Color splashStart = Color(0xFF2548F5);
  static const Color splashMid = Color(0xFF1A3BF5);
  static const Color splashEnd = Color(0xFF0F2AD4);
  static const Color splashDeep = Color(0xFF0A1FA0);
  static const Color splashOverlay1 = Color(0xFF0E6B8C);  // blue-teal
  static const Color splashOverlay2 = Color(0xFF0A4F6A);  // dark blue-teal
  static const Color splashOverlay3 = Color(0xFF062D4A);  // deep navy-teal

  // ─── Gradients ───

  /// Balance card gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Balance card gradient (3 colors)
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3058FF),
      primary,
      Color(0xFF081880),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Splash screen gradient
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [splashStart, splashMid, splashEnd, splashDeep],
    stops: [0.0, 0.3, 0.7, 1.0],
  );
}
