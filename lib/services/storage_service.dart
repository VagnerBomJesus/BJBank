import 'package:shared_preferences/shared_preferences.dart';

/// Storage Service for local persistence
/// Handles SharedPreferences operations
class StorageService {
  StorageService._();

  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyBalanceVisible = 'balance_visible';

  /// Check if user has seen onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  /// Mark onboarding as complete
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  /// Reset onboarding state (for testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingComplete);
  }

  /// Get balance visibility preference
  static Future<bool> isBalanceVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBalanceVisible) ?? true;
  }

  /// Set balance visibility preference
  static Future<void> setBalanceVisible(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBalanceVisible, visible);
  }
}
