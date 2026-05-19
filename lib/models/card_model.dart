import 'package:bjbank/compat/firestore_compat.dart';

/// Card Type Enum
enum CardType {
  physical,  // Physical card
  virtual,   // Virtual card
  debit,     // Debit card
  credit,    // Credit card
  prepaid,   // Prepaid card
}

/// Card Brand Enum
enum CardBrand {
  visa,           // Visa
  mastercard,     // Mastercard
  maestro,        // Maestro
  amex,           // American Express
  discover,       // Discover
  unionpay,       // UnionPay
  dinersclub,     // Diners Club
  unknown,        // Unknown brand
}

/// Card Status Enum
enum CardStatus {
  active,     // Card is active and usable
  blocked,    // Card is blocked (user action)
  expired,    // Card has expired
  cancelled,  // Card has been cancelled
}

/// Card Model
///
/// Represents a bank card (credit, debit, or virtual).
/// Stores card details and metadata.
///
/// Security:
/// - cardNumber is encrypted in Firestore
/// - cvv is encrypted in Firestore
/// - Never stored in plain text locally
///
/// Example:
/// ```dart
/// final card = CardModel(
///   id: 'card_001',
///   userId: 'user_123',
///   cardNumber: '****5678',
///   cardHolder: 'João Silva',
///   expiryDate: '12/2028',
///   cvv: '***',
///   limit: 5000,
///   spentAmount: 1234,
///   type: CardType.physical,
///   status: CardStatus.active,
/// );
/// ```
class CardModel {
  /// Unique card ID
  final String id;

  /// User ID that owns this card
  final String userId;

  /// Card number (last 4 digits visible)
  /// In Firestore: encrypted
  /// In memory: masked as "****1234"
  final String cardNumber;

  /// Card holder name
  final String cardHolder;

  /// Expiry date (MM/YYYY format)
  final String expiryDate;

  /// CVV/CVC (masked as "***")
  /// In Firestore: encrypted
  final String cvv;

  /// Card limit in currency units
  final double limit;

  /// Amount already spent in current period
  final double spentAmount;

  /// Card type (physical, virtual)
  final CardType type;

  /// Card status (active, blocked, expired, cancelled)
  final CardStatus status;

  /// Card creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Optional card brand (Visa, Mastercard, etc.)
  final String? brand;

  /// Optional card color/theme
  final String? cardColor;

  /// Is card locked for online purchases
  final bool lockedForOnline;

  /// Is card locked for international purchases
  final bool lockedForInternational;

  /// Daily spending limit (optional)
  final double? dailyLimit;

  /// Monthly spending limit (optional)
  final double? monthlyLimit;

  const CardModel({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    required this.limit,
    required this.spentAmount,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.brand,
    this.cardColor,
    this.lockedForOnline = false,
    this.lockedForInternational = false,
    this.dailyLimit,
    this.monthlyLimit,
  });

  /// Get available balance
  double get availableBalance => limit - spentAmount;

  /// Check if card is expired
  bool get isExpired {
    final parts = expiryDate.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;

    final now = DateTime.now();
    final currentYear = now.year % 100; // Last 2 digits
    final currentMonth = now.month;

    if (year < currentYear) return true;
    if (year == currentYear && month < currentMonth) return true;

    return false;
  }

  /// Check if card is valid (not expired, not cancelled)
  bool get isValid => status == CardStatus.active && !isExpired;

  /// Check if card can be used for transactions
  bool get isUsable => isValid && availableBalance > 0;

  /// Format card number for display
  /// Example: "4532 **** **** 1234"
  String formatCardNumber() {
    final visiblePart = cardNumber.replaceAll('*', '');
    if (visiblePart.isEmpty) return '****';

    final lastFour = visiblePart.length >= 4
        ? visiblePart.substring(visiblePart.length - 4)
        : visiblePart;

    return '****$lastFour';
  }

  /// Get masked card number
  /// Example: "****5678"
  String getMaskedCardNumber() => formatCardNumber();

  /// Get percentage of limit spent
  double get spentPercentage => spentAmount / limit;

  /// Get spending percentage as formatted string
  String getSpentPercentageString() => '${(spentPercentage * 100).toStringAsFixed(1)}%';

  /// Get card brand icon name (if available)
  String? getBrandIcon() => brand?.toLowerCase();

  /// Get status color (for UI)
  String getStatusColor() {
    switch (status) {
      case CardStatus.active:
        return '#4CAF50'; // Green
      case CardStatus.blocked:
        return '#F44336'; // Red
      case CardStatus.expired:
        return '#FFC107'; // Amber
      case CardStatus.cancelled:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get status label in Portuguese
  String getStatusLabel() {
    switch (status) {
      case CardStatus.active:
        return 'Ativa';
      case CardStatus.blocked:
        return 'Bloqueada';
      case CardStatus.expired:
        return 'Expirada';
      case CardStatus.cancelled:
        return 'Cancelada';
    }
  }

  /// Get card type label in Portuguese
  String getTypeLabel() {
    switch (type) {
      case CardType.physical:
        return 'Física';
      case CardType.virtual:
        return 'Virtual';
      case CardType.debit:
        return 'Débito';
      case CardType.credit:
        return 'Crédito';
      case CardType.prepaid:
        return 'Pré-pago';
    }
  }

  /// Get type display name
  String get typeDisplayName => getTypeLabel();

  /// Get brand display name
  String get brandDisplayName => brand ?? 'Desconhecido';

  /// Get masked account number (****1234)
  String get maskedNumber => formatCardNumber();

  /// Get formatted card number
  String get formattedNumber => formatCardNumber();

  /// Get cardholder name
  String get holderName => cardHolder;

  /// Get last four digits of card
  String get lastFourDigits {
    final visiblePart = cardNumber.replaceAll('*', '');
    return visiblePart.length >= 4
        ? visiblePart.substring(visiblePart.length - 4)
        : visiblePart;
  }

  /// Check if contactless is enabled (opposite of locked)
  bool get contactlessEnabled => !lockedForOnline;

  /// Check if online payments are enabled (opposite of locked)
  bool get onlinePaymentsEnabled => !lockedForOnline;

  /// Check if international purchases are enabled (opposite of locked)
  bool get internationalEnabled => !lockedForInternational;

  /// Create a copy with updated fields
  CardModel copyWith({
    String? id,
    String? userId,
    String? cardNumber,
    String? cardHolder,
    String? expiryDate,
    String? cvv,
    double? limit,
    double? spentAmount,
    CardType? type,
    CardStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brand,
    String? cardColor,
    bool? lockedForOnline,
    bool? lockedForInternational,
    double? dailyLimit,
    double? monthlyLimit,
  }) {
    return CardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      limit: limit ?? this.limit,
      spentAmount: spentAmount ?? this.spentAmount,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      brand: brand ?? this.brand,
      cardColor: cardColor ?? this.cardColor,
      lockedForOnline: lockedForOnline ?? this.lockedForOnline,
      lockedForInternational: lockedForInternational ?? this.lockedForInternational,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'cardNumber': cardNumber, // Encrypted in Firestore
        'cardHolder': cardHolder,
        'expiryDate': expiryDate,
        'cvv': cvv, // Encrypted in Firestore
        'limit': limit,
        'spentAmount': spentAmount,
        'type': type.name,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'brand': brand,
        'cardColor': cardColor,
        'lockedForOnline': lockedForOnline,
        'lockedForInternational': lockedForInternational,
        'dailyLimit': dailyLimit,
        'monthlyLimit': monthlyLimit,
      };

  /// Convert to Firestore format (alias for toJson)
  Map<String, dynamic> toFirestore() => toJson();

  /// Create from Firestore JSON
  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      cardNumber: json['cardNumber'] ?? '****',
      cardHolder: json['cardHolder'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      cvv: json['cvv'] ?? '***',
      limit: (json['limit'] as num?)?.toDouble() ?? 0,
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0,
      type: CardType.values.byName(json['type'] ?? 'physical'),
      status: CardStatus.values.byName(json['status'] ?? 'active'),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      brand: json['brand'],
      cardColor: json['cardColor'],
      lockedForOnline: json['lockedForOnline'] ?? false,
      lockedForInternational: json['lockedForInternational'] ?? false,
      dailyLimit: (json['dailyLimit'] as num?)?.toDouble(),
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble(),
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory CardModel.fromFirestore(DocumentSnapshot doc) {
    return CardModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  String toString() => 'CardModel(id: $id, type: $type, status: $status, balance: ${availableBalance.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CardModel && other.id == id && other.userId == userId;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode;
}

/// Card Statistics
class CardStatistics {
  /// Total cards count
  final int totalCards;

  /// Active cards count
  final int activeCards;

  /// Blocked cards count
  final int blockedCards;

  /// Total spending across all cards
  final double totalSpent;

  /// Total available balance across all cards
  final double totalAvailable;

  /// Most used card (highest spending)
  final CardModel? mostUsedCard;

  /// Least used card (lowest spending)
  final CardModel? leastUsedCard;

  const CardStatistics({
    required this.totalCards,
    required this.activeCards,
    required this.blockedCards,
    required this.totalSpent,
    required this.totalAvailable,
    this.mostUsedCard,
    this.leastUsedCard,
  });

  /// Get spending percentage
  double get spendingPercentage {
    final total = totalSpent + totalAvailable;
    if (total == 0) return 0;
    return (totalSpent / total) * 100;
  }

  Map<String, dynamic> toJson() => {
        'totalCards': totalCards,
        'activeCards': activeCards,
        'blockedCards': blockedCards,
        'totalSpent': totalSpent,
        'totalAvailable': totalAvailable,
        'mostUsedCard': mostUsedCard?.toJson(),
        'leastUsedCard': leastUsedCard?.toJson(),
      };
}
