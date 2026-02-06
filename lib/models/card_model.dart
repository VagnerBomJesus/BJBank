import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Card Type Enum
enum CardType {
  debit,      // Cartão de Débito
  credit,     // Cartão de Crédito
  prepaid,    // Cartão Pré-pago
  virtual,    // Cartão Virtual
}

/// Card Brand Enum
enum CardBrand {
  visa,
  mastercard,
  maestro,
}

/// Card Status Enum
enum CardStatus {
  active,
  blocked,
  expired,
  cancelled,
}

/// Card Model for BJBank
class CardModel {
  const CardModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.cardNumber,
    required this.lastFourDigits,
    required this.expiryDate,
    required this.cvv,
    required this.type,
    required this.brand,
    this.status = CardStatus.active,
    this.holderName = '',
    this.dailyLimit = 1000.0,
    this.monthlyLimit = 5000.0,
    this.contactlessEnabled = true,
    this.onlinePaymentsEnabled = true,
    this.internationalEnabled = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String accountId;
  final String cardNumber;       // Full card number (encrypted in production)
  final String lastFourDigits;   // For display
  final String expiryDate;       // MM/YY format
  final String cvv;              // 3 digits (encrypted in production)
  final CardType type;
  final CardBrand brand;
  final CardStatus status;
  final String holderName;
  final double dailyLimit;
  final double monthlyLimit;
  final bool contactlessEnabled;
  final bool onlinePaymentsEnabled;
  final bool internationalEnabled;
  final DateTime? createdAt;

  /// Create CardModel from Firestore document
  factory CardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CardModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      accountId: data['accountId'] ?? '',
      cardNumber: data['cardNumber'] ?? '',
      lastFourDigits: data['lastFourDigits'] ?? '',
      expiryDate: data['expiryDate'] ?? '',
      cvv: data['cvv'] ?? '',
      type: _parseType(data['type']),
      brand: _parseBrand(data['brand']),
      status: _parseStatus(data['status']),
      holderName: data['holderName'] ?? '',
      dailyLimit: (data['dailyLimit'] ?? 1000.0).toDouble(),
      monthlyLimit: (data['monthlyLimit'] ?? 5000.0).toDouble(),
      contactlessEnabled: data['contactlessEnabled'] ?? true,
      onlinePaymentsEnabled: data['onlinePaymentsEnabled'] ?? true,
      internationalEnabled: data['internationalEnabled'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'accountId': accountId,
      'cardNumber': cardNumber,
      'lastFourDigits': lastFourDigits,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'type': type.name,
      'brand': brand.name,
      'status': status.name,
      'holderName': holderName,
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'contactlessEnabled': contactlessEnabled,
      'onlinePaymentsEnabled': onlinePaymentsEnabled,
      'internationalEnabled': internationalEnabled,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  CardModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? cardNumber,
    String? lastFourDigits,
    String? expiryDate,
    String? cvv,
    CardType? type,
    CardBrand? brand,
    CardStatus? status,
    String? holderName,
    double? dailyLimit,
    double? monthlyLimit,
    bool? contactlessEnabled,
    bool? onlinePaymentsEnabled,
    bool? internationalEnabled,
    DateTime? createdAt,
  }) {
    return CardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      cardNumber: cardNumber ?? this.cardNumber,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      status: status ?? this.status,
      holderName: holderName ?? this.holderName,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      contactlessEnabled: contactlessEnabled ?? this.contactlessEnabled,
      onlinePaymentsEnabled: onlinePaymentsEnabled ?? this.onlinePaymentsEnabled,
      internationalEnabled: internationalEnabled ?? this.internationalEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static CardType _parseType(String? type) {
    switch (type) {
      case 'debit':
        return CardType.debit;
      case 'credit':
        return CardType.credit;
      case 'prepaid':
        return CardType.prepaid;
      case 'virtual':
        return CardType.virtual;
      default:
        return CardType.debit;
    }
  }

  static CardBrand _parseBrand(String? brand) {
    switch (brand) {
      case 'visa':
        return CardBrand.visa;
      case 'mastercard':
        return CardBrand.mastercard;
      case 'maestro':
        return CardBrand.maestro;
      default:
        return CardBrand.visa;
    }
  }

  static CardStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return CardStatus.active;
      case 'blocked':
        return CardStatus.blocked;
      case 'expired':
        return CardStatus.expired;
      case 'cancelled':
        return CardStatus.cancelled;
      default:
        return CardStatus.active;
    }
  }

  /// Get card type display name
  String get typeDisplayName {
    switch (type) {
      case CardType.debit:
        return 'Cartão de Débito';
      case CardType.credit:
        return 'Cartão de Crédito';
      case CardType.prepaid:
        return 'Cartão Pré-pago';
      case CardType.virtual:
        return 'Cartão Virtual';
    }
  }

  /// Get card brand display name
  String get brandDisplayName {
    switch (brand) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.maestro:
        return 'Maestro';
    }
  }

  /// Get masked card number for display
  String get maskedNumber {
    return '•••• •••• •••• $lastFourDigits';
  }

  /// Get formatted card number with spaces
  String get formattedNumber {
    final buffer = StringBuffer();
    for (var i = 0; i < cardNumber.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cardNumber[i]);
    }
    return buffer.toString();
  }

  /// Check if card is usable
  bool get isActive => status == CardStatus.active;

  @override
  String toString() {
    return 'CardModel(id: $id, type: $typeDisplayName, number: $maskedNumber)';
  }
}

/// Card Number Generator
/// Generates valid card numbers using Luhn algorithm
class CardNumberGenerator {
  static final Random _random = Random.secure();

  /// Generate a valid Visa card number (starts with 4)
  static String generateVisaNumber() {
    return _generateCardNumber('4');
  }

  /// Generate a valid Mastercard number (starts with 51-55 or 2221-2720)
  static String generateMastercardNumber() {
    final prefix = _random.nextBool()
        ? '5${_random.nextInt(5) + 1}' // 51-55
        : '222${_random.nextInt(6) + 1}'; // 2221-2226
    return _generateCardNumber(prefix);
  }

  /// Generate a valid Maestro number (starts with 5018, 5020, 5038, 6304)
  static String generateMaestroNumber() {
    final prefixes = ['5018', '5020', '5038', '6304'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    return _generateCardNumber(prefix, length: 16);
  }

  /// Generate card number with Luhn-valid check digit
  static String _generateCardNumber(String prefix, {int length = 16}) {
    // Generate random digits (except last one which is check digit)
    final digitsNeeded = length - prefix.length - 1;
    final buffer = StringBuffer(prefix);

    for (var i = 0; i < digitsNeeded; i++) {
      buffer.write(_random.nextInt(10));
    }

    // Calculate and append Luhn check digit
    final checkDigit = _calculateLuhnCheckDigit(buffer.toString());
    buffer.write(checkDigit);

    return buffer.toString();
  }

  /// Calculate Luhn check digit
  static int _calculateLuhnCheckDigit(String number) {
    int sum = 0;
    bool alternate = true;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return (10 - (sum % 10)) % 10;
  }

  /// Validate card number using Luhn algorithm
  static bool isValidLuhn(String number) {
    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Generate CVV (3 digits)
  static String generateCVV() {
    return '${_random.nextInt(900) + 100}';
  }

  /// Generate expiry date (3-5 years from now)
  static String generateExpiryDate() {
    final now = DateTime.now();
    final yearsToAdd = _random.nextInt(3) + 3; // 3-5 years
    final expiryYear = (now.year + yearsToAdd) % 100;
    final expiryMonth = _random.nextInt(12) + 1;
    return '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().padLeft(2, '0')}';
  }

  /// Generate card number based on brand
  static String generateByBrand(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return generateVisaNumber();
      case CardBrand.mastercard:
        return generateMastercardNumber();
      case CardBrand.maestro:
        return generateMaestroNumber();
    }
  }
}
