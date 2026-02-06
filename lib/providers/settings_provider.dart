import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/secure_storage_service.dart';

/// Settings Provider for BJBank
/// Manages app preferences and settings
class SettingsProvider extends ChangeNotifier {
  bool _isBalanceVisible = true;
  bool _biometricsEnabled = false;
  bool _pinEnabled = false;

  bool get isBalanceVisible => _isBalanceVisible;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get pinEnabled => _pinEnabled;

  /// Initialize settings from storage
  Future<void> initialize() async {
    _isBalanceVisible = await StorageService.isBalanceVisible();
    _biometricsEnabled = await SecureStorageService.isBiometricsEnabled();
    _pinEnabled = await SecureStorageService.isPinEnabled();
    notifyListeners();
  }

  /// Toggle balance visibility
  Future<void> toggleBalanceVisibility() async {
    _isBalanceVisible = !_isBalanceVisible;
    await StorageService.setBalanceVisible(_isBalanceVisible);
    notifyListeners();
  }

  /// Set PIN protection enabled/disabled
  Future<void> setPinEnabled(bool enabled) async {
    await SecureStorageService.setPinEnabled(enabled);
    _pinEnabled = enabled;
    if (!enabled) {
      await SecureStorageService.deletePin();
    }
    notifyListeners();
  }

  /// Set biometrics enabled/disabled
  Future<bool> setBiometricsEnabled(bool enabled) async {
    final result = await SecureStorageService.setBiometricsEnabled(enabled);
    if (result) {
      _biometricsEnabled = enabled;
      notifyListeners();
    }
    return result;
  }
}
