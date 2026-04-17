import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// QR Code Transfer Data Model
class QrTransferData {
  /// Recipient IBAN
  final String recipientIban;

  /// Recipient name
  final String recipientName;

  /// Payment amount (optional)
  final double? amount;

  /// Payment reference (optional)
  final String? reference;

  /// Payment description (optional)
  final String? description;

  /// QR code version
  final String version;

  /// Created timestamp
  final DateTime createdAt;

  const QrTransferData({
    required this.recipientIban,
    required this.recipientName,
    this.amount,
    this.reference,
    this.description,
    this.version = '1.0',
    required this.createdAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'version': version,
        'recipientIban': recipientIban,
        'recipientName': recipientName,
        'amount': amount,
        'reference': reference,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create from JSON
  factory QrTransferData.fromJson(Map<String, dynamic> json) {
    return QrTransferData(
      recipientIban: json['recipientIban'] ?? '',
      recipientName: json['recipientName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      reference: json['reference'],
      description: json['description'],
      version: json['version'] ?? '1.0',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Convert to QR code string
  String toQrString() {
    final json = jsonEncode(toJson());
    return base64Url.encode(utf8.encode(json)).replaceAll('=', '');
  }

  /// Create from QR code string
  static QrTransferData? fromQrString(String qrString) {
    try {
      // Add padding if needed
      var padded = qrString;
      final mod = qrString.length % 4;
      if (mod != 0) {
        padded += '=' * (4 - mod);
      }

      final decoded = utf8.decode(base64Url.decode(padded));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return QrTransferData.fromJson(json);
    } catch (e) {
      debugPrint('Error parsing QR string: $e');
      return null;
    }
  }

  @override
  String toString() =>
      'QrTransferData(iban: $recipientIban, name: $recipientName, amount: €${amount ?? 0})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QrTransferData &&
        other.recipientIban == recipientIban &&
        other.recipientName == recipientName &&
        other.amount == amount;
  }

  @override
  int get hashCode =>
      recipientIban.hashCode ^ recipientName.hashCode ^ amount.hashCode;
}

/// QR Code Service
///
/// Handles QR code generation, parsing, and validation for payments
class QrCodeService {
  // Singleton
  static final QrCodeService _instance = QrCodeService._internal();
  factory QrCodeService() => _instance;
  QrCodeService._internal();

  /// Maximum QR code data size (bytes)
  static const int maxDataSize = 2953; // QR Code Version 40

  /// Generate QR code string from transfer data
  String generateQrCode(QrTransferData transferData) {
    try {
      final qrString = transferData.toQrString();

      if (qrString.length > maxDataSize) {
        throw Exception('QR data exceeds maximum size: ${qrString.length} bytes');
      }

      debugPrint('✅ QR code generated: ${qrString.length} bytes');
      return qrString;
    } catch (e) {
      debugPrint('❌ Error generating QR code: $e');
      rethrow;
    }
  }

  /// Parse QR code string to transfer data
  QrTransferData? parseQrCode(String qrString) {
    try {
      final transferData = QrTransferData.fromQrString(qrString);

      if (transferData == null) {
        debugPrint('❌ Failed to parse QR code');
        return null;
      }

      // Validate
      if (!validateQrCode(transferData)) {
        debugPrint('❌ QR code validation failed');
        return null;
      }

      debugPrint('✅ QR code parsed successfully');
      return transferData;
    } catch (e) {
      debugPrint('❌ Error parsing QR code: $e');
      return null;
    }
  }

  /// Validate QR code data
  bool validateQrCode(QrTransferData transferData) {
    try {
      // Check IBAN format (basic validation)
      if (transferData.recipientIban.isEmpty ||
          transferData.recipientIban.length < 15) {
        debugPrint('❌ Invalid IBAN format');
        return false;
      }

      // Check IBAN starts with country code
      final countryCode = transferData.recipientIban.substring(0, 2);
      if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
        debugPrint('❌ Invalid country code in IBAN');
        return false;
      }

      // Check recipient name
      if (transferData.recipientName.isEmpty) {
        debugPrint('❌ Recipient name cannot be empty');
        return false;
      }

      // Check amount if provided
      if (transferData.amount != null && transferData.amount! < 0) {
        debugPrint('❌ Amount cannot be negative');
        return false;
      }

      debugPrint('✅ QR code validation passed');
      return true;
    } catch (e) {
      debugPrint('❌ Error validating QR code: $e');
      return false;
    }
  }

  /// Check QR code format validity
  bool isValidQrFormat(String qrString) {
    try {
      return QrTransferData.fromQrString(qrString) != null;
    } catch (e) {
      return false;
    }
  }

  /// Encrypt QR data with IBAN
  String encryptQrData(String qrString, String encryptionKey) {
    try {
      // Simple encryption using SHA256 HMAC
      final bytes = utf8.encode(qrString);
      final key = utf8.encode(encryptionKey);

      final hmac = Hmac(sha256, key);
      final encrypted = hmac.convert(bytes);

      return base64Encode(encrypted.bytes + bytes);
    } catch (e) {
      debugPrint('❌ Error encrypting QR data: $e');
      rethrow;
    }
  }

  /// Decrypt QR data
  String? decryptQrData(String encryptedData, String encryptionKey) {
    try {
      final bytes = base64Decode(encryptedData);

      // Extract signature (first 32 bytes) and data
      if (bytes.length <= 32) return null;

      final signature = bytes.sublist(0, 32);
      final data = bytes.sublist(32);
      final qrString = utf8.decode(data);

      // Verify signature
      final key = utf8.encode(encryptionKey);
      final hmac = Hmac(sha256, key);
      final expectedSignature = hmac.convert(data);

      if (!_bytesEqual(signature, expectedSignature.bytes)) {
        debugPrint('❌ QR data signature verification failed');
        return null;
      }

      return qrString;
    } catch (e) {
      debugPrint('❌ Error decrypting QR data: $e');
      return null;
    }
  }

  /// Compare byte arrays securely
  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Get QR code metadata
  Map<String, dynamic> getQrMetadata(String qrString) {
    return {
      'dataSize': qrString.length,
      'maxSize': maxDataSize,
      'utilizationPercent': ((qrString.length / maxDataSize) * 100).toStringAsFixed(1),
      'isValid': isValidQrFormat(qrString),
    };
  }
}
