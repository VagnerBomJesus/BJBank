import 'dart:math';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

/// OTP Service for BJBank
/// Handles OTP generation and verification for phone verification
class OtpService {
  static const _otpKey = 'pending_otp';
  static const _otpPhoneKey = 'otp_phone';
  static const _otpExpiresKey = 'otp_expires';
  static const _otpAttemptsKey = 'otp_attempts';
  static const int _maxAttempts = 3;
  static const Duration _otpValidity = Duration(minutes: 5);

  /// Generate a 6-digit OTP code
  static String generateOtp() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// Send OTP to phone (simulated - only logs in debug)
  /// Returns true if OTP was "sent" successfully
  static Future<bool> sendOtp(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      // Generate new OTP
      final otp = generateOtp();
      final expires = DateTime.now().add(_otpValidity);

      // Store OTP data
      await SecureStorageService.setSecureValue(_otpKey, otp);
      await SecureStorageService.setSecureValue(_otpPhoneKey, cleanPhone);
      await SecureStorageService.setSecureValue(_otpExpiresKey, expires.toIso8601String());
      await SecureStorageService.setSecureValue(_otpAttemptsKey, '0');

      // In demo mode, print OTP to console
      debugPrint('----------------------------------------');
      debugPrint('OTP para $cleanPhone: $otp');
      debugPrint('Validade: ${_otpValidity.inMinutes} minutos');
      debugPrint('----------------------------------------');

      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify OTP code
  /// Returns VerifyResult with success status and remaining attempts
  static Future<OtpVerifyResult> verifyOtp(String code) async {
    try {
      final storedOtp = await SecureStorageService.getSecureValue(_otpKey);
      final expiresStr = await SecureStorageService.getSecureValue(_otpExpiresKey);
      final attemptsStr = await SecureStorageService.getSecureValue(_otpAttemptsKey);

      if (storedOtp == null || expiresStr == null) {
        return OtpVerifyResult(
          success: false,
          error: OtpError.notFound,
          message: 'Nenhum codigo OTP pendente',
        );
      }

      // Check expiry
      final expires = DateTime.parse(expiresStr);
      if (DateTime.now().isAfter(expires)) {
        await clearOtp();
        return OtpVerifyResult(
          success: false,
          error: OtpError.expired,
          message: 'Codigo OTP expirado. Solicite um novo.',
        );
      }

      // Check attempts
      int attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
      if (attempts >= _maxAttempts) {
        await clearOtp();
        return OtpVerifyResult(
          success: false,
          error: OtpError.maxAttempts,
          message: 'Numero maximo de tentativas excedido',
        );
      }

      // Verify code
      if (code == storedOtp) {
        await clearOtp();
        return OtpVerifyResult(
          success: true,
          message: 'Codigo verificado com sucesso',
        );
      }

      // Wrong code - increment attempts
      attempts++;
      await SecureStorageService.setSecureValue(_otpAttemptsKey, attempts.toString());

      final remaining = _maxAttempts - attempts;
      return OtpVerifyResult(
        success: false,
        error: OtpError.wrongCode,
        message: 'Codigo incorreto. $remaining tentativa${remaining == 1 ? '' : 's'} restante${remaining == 1 ? '' : 's'}.',
        remainingAttempts: remaining,
      );
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return OtpVerifyResult(
        success: false,
        error: OtpError.unknown,
        message: 'Erro ao verificar codigo',
      );
    }
  }

  /// Get the phone number for pending OTP
  static Future<String?> getPendingOtpPhone() async {
    return await SecureStorageService.getSecureValue(_otpPhoneKey);
  }

  /// Check if there's a pending OTP
  static Future<bool> hasPendingOtp() async {
    final otp = await SecureStorageService.getSecureValue(_otpKey);
    final expiresStr = await SecureStorageService.getSecureValue(_otpExpiresKey);

    if (otp == null || expiresStr == null) return false;

    final expires = DateTime.parse(expiresStr);
    return DateTime.now().isBefore(expires);
  }

  /// Get remaining time for OTP validity
  static Future<Duration?> getRemainingTime() async {
    final expiresStr = await SecureStorageService.getSecureValue(_otpExpiresKey);
    if (expiresStr == null) return null;

    final expires = DateTime.parse(expiresStr);
    final remaining = expires.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Clear OTP data after successful verification or expiry
  static Future<void> clearOtp() async {
    await SecureStorageService.deleteSecureValue(_otpKey);
    await SecureStorageService.deleteSecureValue(_otpPhoneKey);
    await SecureStorageService.deleteSecureValue(_otpExpiresKey);
    await SecureStorageService.deleteSecureValue(_otpAttemptsKey);
  }
}

/// OTP Verification Errors
enum OtpError {
  notFound,
  expired,
  wrongCode,
  maxAttempts,
  unknown,
}

/// OTP Verification Result
class OtpVerifyResult {
  const OtpVerifyResult({
    required this.success,
    this.error,
    this.message,
    this.remainingAttempts,
  });

  final bool success;
  final OtpError? error;
  final String? message;
  final int? remainingAttempts;
}
