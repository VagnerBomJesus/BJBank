import 'package:flutter/material.dart';
import 'colors.dart';
import 'border_radius.dart';

/// BJBank Theme Configuration
/// Material Design 3 with blue color scheme
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BJBankColors.primary,
        brightness: Brightness.light,
        primary: BJBankColors.primary,
        onPrimary: BJBankColors.onPrimary,
        primaryContainer: BJBankColors.primaryContainer,
        onPrimaryContainer: BJBankColors.onPrimaryContainer,
        secondary: BJBankColors.secondary,
        onSecondary: BJBankColors.onSecondary,
        secondaryContainer: BJBankColors.secondaryContainer,
        onSecondaryContainer: BJBankColors.onSecondaryContainer,
        tertiary: BJBankColors.tertiary,
        onTertiary: BJBankColors.onTertiary,
        tertiaryContainer: BJBankColors.tertiaryContainer,
        onTertiaryContainer: BJBankColors.onTertiaryContainer,
        error: BJBankColors.error,
        onError: BJBankColors.onError,
        errorContainer: BJBankColors.errorContainer,
        onErrorContainer: BJBankColors.onErrorContainer,
        surface: BJBankColors.surface,
        onSurface: BJBankColors.onSurface,
        surfaceContainerHighest: BJBankColors.surfaceVariant,
        onSurfaceVariant: BJBankColors.onSurfaceVariant,
        outline: BJBankColors.outline,
        outlineVariant: BJBankColors.outlineVariant,
      ),
      scaffoldBackgroundColor: BJBankColors.background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        backgroundColor: BJBankColors.surface,
        foregroundColor: BJBankColors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: BJBankColors.primary,
        unselectedItemColor: BJBankColors.onSurfaceVariant,
        backgroundColor: BJBankColors.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 80,
        backgroundColor: BJBankColors.surface,
        indicatorColor: BJBankColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: BJBankColors.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: BJBankColors.onSurfaceVariant,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BJBankBorderRadius.buttonRadius,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BJBankBorderRadius.buttonRadius,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BJBankBorderRadius.buttonRadius,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BJBankBorderRadius.buttonRadius,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BJBankBorderRadius.cardRadius,
        ),
        color: BJBankColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BJBankBorderRadius.chipRadius,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BJBankBorderRadius.dialogRadius,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BJBankColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BJBankBorderRadius.inputRadius,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerTheme: const DividerThemeData(
        color: BJBankColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BJBankColors.primary,
        brightness: Brightness.dark,
        primary: BJBankColors.primaryLight,
        onPrimary: BJBankColors.primaryDark,
        primaryContainer: BJBankColors.primaryContainerDark,
        onPrimaryContainer: BJBankColors.onPrimaryContainerDark,
        surface: BJBankColors.surfaceDark,
        onSurface: BJBankColors.onSurfaceDark,
        outline: BJBankColors.outlineDark,
        outlineVariant: BJBankColors.outlineVariantDark,
        error: BJBankColors.error,
        onError: BJBankColors.onError,
      ),
      scaffoldBackgroundColor: BJBankColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        backgroundColor: BJBankColors.surfaceDark,
        foregroundColor: BJBankColors.onSurfaceDark,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 80,
        backgroundColor: BJBankColors.surfaceDark,
        indicatorColor: BJBankColors.primaryContainerDark,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: BJBankColors.primaryLight,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: BJBankColors.onSurfaceDark,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BJBankBorderRadius.cardRadius,
        ),
        color: BJBankColors.surfaceVariantDark,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BJBankColors.surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BJBankBorderRadius.inputRadius,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BJBankColors.outlineVariantDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
