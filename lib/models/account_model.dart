import 'package:cloud_firestore/cloud_firestore.dart';

/// Account Type Enum
enum AccountType {
  checking,   // Conta à ordem
  savings,    // Conta poupança
  business,   // Conta empresarial
}

/// Account Status Enum
enum AccountStatus {
  active,
  blocked,
  closed,
}

/// Account Model for BJBank
/// Represents a bank account in Portuguese banking system (EUR)
class AccountModel {
  const AccountModel({
    required this.id,
    required this.userId,
    required this.iban,
    required this.accountNumber,
    this.type = AccountType.checking,
    this.status = AccountStatus.active,
    this.balance = 0.0,
    this.availableBalance = 0.0,
    this.currency = 'EUR',
    this.bankCode = '0002',  // BIC/SWIFT code prefix
    this.mbWayLinked = false,
    this.mbWayPhone,
    this.mbWayDailyLimit = 1000.0,
    this.mbWayPerTransactionLimit = 500.0,
    this.mbWayDailyUsed = 0.0,
    this.mbWayLastResetDate,
    this.mbWayLinkedAt,
    this.mbWayLookupCount = 0,
    this.mbWayLastLookup,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String iban;              // PT50 0002 0123 1234 5678 9015 4
  final String accountNumber;     // 12345678901
  final AccountType type;
  final AccountStatus status;
  final double balance;
  final double availableBalance;
  final String currency;
  final String bankCode;
  final bool mbWayLinked;
  final String? mbWayPhone;       // Phone linked to MB WAY
  final double mbWayDailyLimit;   // Default: €1.000
  final double mbWayPerTransactionLimit; // Default: €500
  final double mbWayDailyUsed;    // Amount used today
  final DateTime? mbWayLastResetDate; // Last daily reset
  final DateTime? mbWayLinkedAt;  // When MB WAY was linked
  final int mbWayLookupCount;     // Lookups in last hour
  final DateTime? mbWayLastLookup; // Last phone lookup
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Create AccountModel from Firestore document
  factory AccountModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccountModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      iban: data['iban'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      balance: (data['balance'] ?? 0.0).toDouble(),
      availableBalance: (data['availableBalance'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      bankCode: data['bankCode'] ?? '0002',
      mbWayLinked: data['mbWayLinked'] ?? false,
      mbWayPhone: data['mbWayPhone'],
      mbWayDailyLimit: (data['mbWayDailyLimit'] ?? 1000.0).toDouble(),
      mbWayPerTransactionLimit: (data['mbWayPerTransactionLimit'] ?? 500.0).toDouble(),
      mbWayDailyUsed: (data['mbWayDailyUsed'] ?? 0.0).toDouble(),
      mbWayLastResetDate: (data['mbWayLastResetDate'] as Timestamp?)?.toDate(),
      mbWayLinkedAt: (data['mbWayLinkedAt'] as Timestamp?)?.toDate(),
      mbWayLookupCount: (data['mbWayLookupCount'] ?? 0).toInt(),
      mbWayLastLookup: (data['mbWayLastLookup'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'iban': iban,
      'accountNumber': accountNumber,
      'type': type.name,
      'status': status.name,
      'balance': balance,
      'availableBalance': availableBalance,
      'currency': currency,
      'bankCode': bankCode,
      'mbWayLinked': mbWayLinked,
      'mbWayPhone': mbWayPhone,
      'mbWayDailyLimit': mbWayDailyLimit,
      'mbWayPerTransactionLimit': mbWayPerTransactionLimit,
      'mbWayDailyUsed': mbWayDailyUsed,
      'mbWayLastResetDate': mbWayLastResetDate != null ? Timestamp.fromDate(mbWayLastResetDate!) : null,
      'mbWayLinkedAt': mbWayLinkedAt != null ? Timestamp.fromDate(mbWayLinkedAt!) : null,
      'mbWayLookupCount': mbWayLookupCount,
      'mbWayLastLookup': mbWayLastLookup != null ? Timestamp.fromDate(mbWayLastLookup!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  AccountModel copyWith({
    String? id,
    String? userId,
    String? iban,
    String? accountNumber,
    AccountType? type,
    AccountStatus? status,
    double? balance,
    double? availableBalance,
    String? currency,
    String? bankCode,
    bool? mbWayLinked,
    String? mbWayPhone,
    double? mbWayDailyLimit,
    double? mbWayPerTransactionLimit,
    double? mbWayDailyUsed,
    DateTime? mbWayLastResetDate,
    DateTime? mbWayLinkedAt,
    int? mbWayLookupCount,
    DateTime? mbWayLastLookup,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      iban: iban ?? this.iban,
      accountNumber: accountNumber ?? this.accountNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      balance: balance ?? this.balance,
      availableBalance: availableBalance ?? this.availableBalance,
      currency: currency ?? this.currency,
      bankCode: bankCode ?? this.bankCode,
      mbWayLinked: mbWayLinked ?? this.mbWayLinked,
      mbWayPhone: mbWayPhone ?? this.mbWayPhone,
      mbWayDailyLimit: mbWayDailyLimit ?? this.mbWayDailyLimit,
      mbWayPerTransactionLimit: mbWayPerTransactionLimit ?? this.mbWayPerTransactionLimit,
      mbWayDailyUsed: mbWayDailyUsed ?? this.mbWayDailyUsed,
      mbWayLastResetDate: mbWayLastResetDate ?? this.mbWayLastResetDate,
      mbWayLinkedAt: mbWayLinkedAt ?? this.mbWayLinkedAt,
      mbWayLookupCount: mbWayLookupCount ?? this.mbWayLookupCount,
      mbWayLastLookup: mbWayLastLookup ?? this.mbWayLastLookup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parse type string to enum
  static AccountType _parseType(String? type) {
    switch (type) {
      case 'checking':
        return AccountType.checking;
      case 'savings':
        return AccountType.savings;
      case 'business':
        return AccountType.business;
      default:
        return AccountType.checking;
    }
  }

  /// Parse status string to enum
  static AccountStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return AccountStatus.active;
      case 'blocked':
        return AccountStatus.blocked;
      case 'closed':
        return AccountStatus.closed;
      default:
        return AccountStatus.active;
    }
  }

  /// Get formatted balance in EUR
  String get formattedBalance {
    return '€ ${_formatEuro(balance)}';
  }

  /// Get formatted available balance in EUR
  String get formattedAvailableBalance {
    return '€ ${_formatEuro(availableBalance)}';
  }

  /// Format number as Euro (Portuguese format)
  static String _formatEuro(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$intPart,${parts[1]}';
  }

  /// Get formatted IBAN with spaces (PT50 0002 0123 1234 5678 9015 4)
  String get formattedIban {
    final cleaned = iban.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  /// Get masked IBAN for privacy
  String get maskedIban {
    final cleaned = iban.replaceAll(' ', '');
    if (cleaned.length > 8) {
      return '${cleaned.substring(0, 4)} •••• •••• ${cleaned.substring(cleaned.length - 4)}';
    }
    return iban;
  }

  /// Get account type display name
  String get typeDisplayName {
    switch (type) {
      case AccountType.checking:
        return 'Conta à Ordem';
      case AccountType.savings:
        return 'Conta Poupança';
      case AccountType.business:
        return 'Conta Empresarial';
    }
  }

  /// Check if account can make transfers
  bool get canTransfer => status == AccountStatus.active && availableBalance > 0;

  /// Check if MB WAY is available
  bool get canUseMbWay => mbWayLinked && mbWayPhone != null && status == AccountStatus.active;

  /// Get remaining daily MB WAY limit
  double get mbWayRemainingDaily {
    // Check if daily reset is needed
    final now = DateTime.now();
    if (mbWayLastResetDate != null && _isSameDay(mbWayLastResetDate!, now)) {
      return (mbWayDailyLimit - mbWayDailyUsed).clamp(0.0, mbWayDailyLimit);
    }
    return mbWayDailyLimit; // New day, full limit available
  }

  /// Check if user can make MB WAY transfer for given amount
  bool canMakeMbWayTransfer(double amount) {
    if (!canUseMbWay) return false;
    if (amount > mbWayPerTransactionLimit) return false;
    if (amount > mbWayRemainingDaily) return false;
    if (amount > availableBalance) return false;
    return true;
  }

  /// Get formatted MB WAY phone number
  String? get formattedMbWayPhone {
    if (mbWayPhone == null || mbWayPhone!.length < 12) return mbWayPhone;
    // Format: +351 912 345 678
    final cleaned = mbWayPhone!.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length == 13 && cleaned.startsWith('+351')) {
      return '+351 ${cleaned.substring(4, 7)} ${cleaned.substring(7, 10)} ${cleaned.substring(10)}';
    }
    return mbWayPhone;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  String toString() {
    return 'AccountModel(id: $id, iban: $maskedIban, balance: $formattedBalance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// IBAN Generator for Portuguese Bank Accounts
/// Format: PTkk bbbb ssss cccc cccc cccc c
/// PT = Country code (Portugal)
/// kk = Check digits (2 digits, ISO 7064 Mod 97-10)
/// bbbb = Bank code (4 digits) - BJBank uses 0036
/// ssss = Branch code (4 digits)
/// ccccccccccc = Account number (11 digits)
class IbanGenerator {
  static const String countryCode = 'PT';
  static const String bjBankCode = '0036'; // BJBank identifier
  static const String defaultBranchCode = '0001'; // Main branch

  /// Generate a unique Portuguese IBAN with valid check digits
  static String generate({
    String? accountNumber,
    String branchCode = '0001',
  }) {
    // Generate account number if not provided (11 digits)
    final accNum = accountNumber ?? _generateAccountNumber();

    // Build BBAN (Basic Bank Account Number)
    // Format: bank code (4) + branch (4) + account (11) = 19 digits
    final bban = '$bjBankCode$branchCode$accNum';

    // Calculate check digits using ISO 7064 Mod 97-10
    final checkDigits = _calculateCheckDigits(bban);

    // Final IBAN: PT + check digits + BBAN
    return '$countryCode$checkDigits$bban';
  }

  /// Generate a unique 11-digit account number
  static String _generateAccountNumber() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch % 100000;

    // Format: YYMM + 7 random digits
    final year = (now.year % 100).toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final sequence = random.toString().padLeft(7, '0');

    return '$year$month$sequence';
  }

  /// Calculate IBAN check digits using ISO 7064 Mod 97-10
  /// 1. Move country code and check digits to end (use 00 as placeholder)
  /// 2. Replace letters with numbers (A=10, B=11, ..., Z=35)
  /// 3. Calculate: 98 - (number mod 97)
  static String _calculateCheckDigits(String bban) {
    // PT00 + BBAN -> BBAN + PT00
    // P=25, T=29, so PT = 2529
    final rearranged = '${bban}252900';

    // Calculate mod 97
    final remainder = _mod97(rearranged);
    final checkDigits = 98 - remainder;

    return checkDigits.toString().padLeft(2, '0');
  }

  /// Calculate number mod 97 for large numbers (string-based)
  static int _mod97(String number) {
    int remainder = 0;
    for (int i = 0; i < number.length; i++) {
      final digit = int.parse(number[i]);
      remainder = (remainder * 10 + digit) % 97;
    }
    return remainder;
  }

  /// Validate IBAN check digits
  static bool validateIban(String iban) {
    final cleaned = iban.replaceAll(' ', '').toUpperCase();
    if (cleaned.length != 25 || !cleaned.startsWith('PT')) {
      return false;
    }

    // Move first 4 chars to end
    final rearranged = cleaned.substring(4) + cleaned.substring(0, 4);

    // Replace letters with numbers
    final buffer = StringBuffer();
    for (var char in rearranged.runes) {
      if (char >= 65 && char <= 90) {
        // A-Z -> 10-35
        buffer.write(char - 55);
      } else {
        buffer.writeCharCode(char);
      }
    }

    return _mod97(buffer.toString()) == 1;
  }

  /// Format IBAN with spaces (PT50 0036 0001 1234 5678 901)
  static String format(String iban) {
    final cleaned = iban.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }
}

/// Account Number Generator
class AccountNumberGenerator {
  static int _sequenceCounter = 0;

  /// Generate a unique 11-digit account number
  /// Format: YYDDD + 6 digits (year + day of year + sequence)
  static String generate() {
    final now = DateTime.now();

    // Year (2 digits)
    final year = (now.year % 100).toString().padLeft(2, '0');

    // Day of year (3 digits, 001-366)
    final dayOfYear = _getDayOfYear(now).toString().padLeft(3, '0');

    // Sequence/random (6 digits)
    _sequenceCounter++;
    final timestamp = now.millisecondsSinceEpoch % 10000;
    final sequence = ((_sequenceCounter * 17 + timestamp) % 1000000)
        .toString()
        .padLeft(6, '0');

    return '$year$dayOfYear$sequence';
  }

  /// Get day of year (1-366)
  static int _getDayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  /// Generate unique account number with collision check callback
  static Future<String> generateUnique(
    Future<bool> Function(String) isUnique,
  ) async {
    String accountNumber;
    int attempts = 0;
    const maxAttempts = 100;

    do {
      accountNumber = generate();
      attempts++;
      if (attempts >= maxAttempts) {
        // Fallback to timestamp-based generation
        final now = DateTime.now();
        accountNumber = now.microsecondsSinceEpoch.toString().substring(0, 11);
      }
    } while (!await isUnique(accountNumber) && attempts < maxAttempts);

    return accountNumber;
  }
}

/// Legacy function for backwards compatibility
String generatePortugueseIban({
  String bankCode = '0036',
  String branchCode = '0001',
  String accountNumber = '12345678901',
}) {
  return IbanGenerator.generate(
    accountNumber: accountNumber,
    branchCode: branchCode,
  );
}
