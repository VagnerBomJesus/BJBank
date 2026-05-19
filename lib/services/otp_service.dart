import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage_service.dart';
import 'supabase_config.dart';

/// OTP Service for BJBank
/// Handles OTP generation and verification for phone verification
/// Supports email delivery via Firebase Cloud Functions
class OtpService {
  static const _otpKey = 'pending_otp';
  static const _otpPhoneKey = 'otp_phone';
  static const _otpEmailKey = 'otp_email';
  static const _otpExpiresKey = 'otp_expires';
  static const _otpAttemptsKey = 'otp_attempts';
  static const int _maxAttempts = 3;
  static const Duration _otpValidity = Duration(minutes: 5);

  /// Generate a 6-digit OTP code
  static String generateOtp() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// Send OTP to phone via email
  /// Returns true if OTP was sent successfully via email
  /// Falls back to console logging in development/demo mode
  static Future<bool> sendOtp(String phone, {String? email}) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      // Generate new OTP
      final otp = generateOtp();
      final expires = DateTime.now().add(_otpValidity);

      // Store OTP data locally
      await SecureStorageService.setSecureValue(_otpKey, otp);
      await SecureStorageService.setSecureValue(_otpPhoneKey, cleanPhone);
      if (email != null) {
        await SecureStorageService.setSecureValue(_otpEmailKey, email);
      }
      await SecureStorageService.setSecureValue(_otpExpiresKey, expires.toIso8601String());
      await SecureStorageService.setSecureValue(_otpAttemptsKey, '0');

      // Try to send via email
      final emailSent = email != null ? await _sendOtpViaEmail(otp, cleanPhone, email) : false;

      // If email not sent, log to console (demo/development mode)
      if (!emailSent) {
        debugPrint('----------------------------------------');
        debugPrint('⚠️ Modo Demo - Email nao configurado');
        debugPrint('OTP para $cleanPhone: $otp');
        debugPrint('Email: $email');
        debugPrint('Validade: ${_otpValidity.inMinutes} minutos');
        debugPrint('----------------------------------------');
      }

      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  /// Envia OTP por email via Edge Function `send_otp_email`.
  /// Devolve true se a Edge Function aceitou o pedido (email enviado ou
  /// modo dev). Devolve false em caso de falha real.
  static Future<bool> _sendOtpViaEmail(String otp, String phone, String email) async {
    try {
      if (!_isValidEmail(email)) {
        debugPrint('Invalid email format: $email');
        return false;
      }

      final sb = SupabaseConfig.client;
      if (sb.auth.currentUser == null) {
        debugPrint('User not authenticated - cannot send OTP email');
        return false;
      }

      final response = await sb.functions.invoke(
        'send_otp_email',
        body: {
          'email': email,
          'otp': otp,
          if (phone.isNotEmpty) 'phone': phone,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['ok'] == true) {
          if (data['devMode'] == true) {
            debugPrint('[send_otp_email] DEV MODE - codigo OTP no log do '
                'servidor (Supabase Functions). RESEND_API_KEY nao configurada.');
          } else {
            debugPrint('[send_otp_email] email enviado para $email');
          }
          return true;
        }
        debugPrint('[send_otp_email] erro: ${data['error']}');
        return false;
      }
      return false;
    } on FunctionException catch (e) {
      debugPrint('send_otp_email FunctionException: ${e.details}');
      return false;
    } catch (e) {
      debugPrint('Error sending OTP via email: $e');
      return false;
    }
  }

  /// Validate email format
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
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

  /// Get the email for pending OTP
  static Future<String?> getPendingOtpEmail() async {
    return await SecureStorageService.getSecureValue(_otpEmailKey);
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
    await SecureStorageService.deleteSecureValue(_otpEmailKey);
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
