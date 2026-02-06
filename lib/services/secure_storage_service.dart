import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

/// Secure Storage Service for BJBank
/// Handles PIN, biometrics, and secure data storage
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Storage keys
  static const _pinHashKey = 'bjbank_pin_hash';
  static const _pinSaltKey = 'bjbank_pin_salt';
  static const _biometricsEnabledKey = 'bjbank_biometrics_enabled';
  static const _pinEnabledKey = 'bjbank_pin_enabled';
  static const _userIdKey = 'bjbank_user_id';
  static const _sessionTokenKey = 'bjbank_session_token';

  // ============== PIN MANAGEMENT ==============

  /// Set user PIN
  static Future<bool> setPin(String pin) async {
    try {
      // Generate random salt
      final salt = _generateSalt();

      // Hash PIN with salt
      final hash = _hashPin(pin, salt);

      // Store both
      await _storage.write(key: _pinSaltKey, value: salt);
      await _storage.write(key: _pinHashKey, value: hash);

      debugPrint('PIN stored securely');
      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    }
  }

  /// Verify PIN
  static Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinHashKey);
      final storedSalt = await _storage.read(key: _pinSaltKey);

      if (storedHash == null || storedSalt == null) {
        return false;
      }

      final inputHash = _hashPin(pin, storedSalt);
      return inputHash == storedHash;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Check if PIN is set
  static Future<bool> isPinSet() async {
    try {
      final hash = await _storage.read(key: _pinHashKey);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Change PIN
  static Future<bool> changePin(String oldPin, String newPin) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;
    return await setPin(newPin);
  }

  /// Delete PIN
  static Future<void> deletePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  /// Check if PIN protection is enabled
  static Future<bool> isPinEnabled() async {
    try {
      final value = await _storage.read(key: _pinEnabledKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable/disable PIN protection
  static Future<void> setPinEnabled(bool enabled) async {
    await _storage.write(key: _pinEnabledKey, value: enabled.toString());
  }

  // ============== BIOMETRICS ==============

  /// Check if device supports biometrics
  static Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Autentique-se para aceder ao BJBank',
  }) async {
    try {
      final isEnabled = await isBiometricsEnabled();
      if (!isEnabled) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Enable/disable biometrics
  static Future<bool> setBiometricsEnabled(bool enabled) async {
    try {
      if (enabled) {
        // Verify biometrics are available
        final available = await isBiometricsAvailable();
        if (!available) return false;

        // Test authentication
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Confirme a ativação da biometria',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!authenticated) return false;
      }

      await _storage.write(
        key: _biometricsEnabledKey,
        value: enabled.toString(),
      );
      return true;
    } catch (e) {
      debugPrint('Error setting biometrics: $e');
      return false;
    }
  }

  /// Check if biometrics are enabled
  static Future<bool> isBiometricsEnabled() async {
    try {
      final value = await _storage.read(key: _biometricsEnabledKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  // ============== SESSION MANAGEMENT ==============

  /// Store user ID for session
  static Future<void> setUserId(String? userId) async {
    if (userId == null) {
      await _storage.delete(key: _userIdKey);
    } else {
      await _storage.write(key: _userIdKey, value: userId);
    }
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Store session token
  static Future<void> setSessionToken(String? token) async {
    if (token == null) {
      await _storage.delete(key: _sessionTokenKey);
    } else {
      await _storage.write(key: _sessionTokenKey, value: token);
    }
  }

  /// Get session token
  static Future<String?> getSessionToken() async {
    return await _storage.read(key: _sessionTokenKey);
  }

  // ============== GENERIC SECURE STORAGE ==============

  /// Store secure value
  static Future<void> setSecureValue(String key, String value) async {
    await _storage.write(key: 'bjbank_$key', value: value);
  }

  /// Get secure value
  static Future<String?> getSecureValue(String key) async {
    return await _storage.read(key: 'bjbank_$key');
  }

  /// Delete secure value
  static Future<void> deleteSecureValue(String key) async {
    await _storage.delete(key: 'bjbank_$key');
  }

  /// Clear all secure storage
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    debugPrint('All secure storage cleared');
  }

  // ============== HELPER METHODS ==============

  /// Generate random salt
  static String _generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  /// Hash PIN with salt using SHA-256
  static String _hashPin(String pin, String salt) {
    final data = utf8.encode('$salt$pin$salt');
    // Multiple rounds for added security
    var hash = sha256.convert(data);
    for (var i = 0; i < 10000; i++) {
      hash = sha256.convert(hash.bytes);
    }
    return hash.toString();
  }
}

/// Extension to get biometric type name in Portuguese
extension BiometricTypeExtension on BiometricType {
  String get displayName {
    switch (this) {
      case BiometricType.face:
        return 'Reconhecimento Facial';
      case BiometricType.fingerprint:
        return 'Impressão Digital';
      case BiometricType.iris:
        return 'Scanner de Íris';
      case BiometricType.strong:
        return 'Biometria Forte';
      case BiometricType.weak:
        return 'Biometria';
    }
  }

  String get iconName {
    switch (this) {
      case BiometricType.face:
        return 'face';
      case BiometricType.fingerprint:
        return 'fingerprint';
      case BiometricType.iris:
        return 'visibility';
      default:
        return 'security';
    }
  }
}
