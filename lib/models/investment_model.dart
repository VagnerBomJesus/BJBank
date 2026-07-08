import 'package:bjbank/compat/firestore_compat.dart';

/// Investment Type Enum
enum InvestmentType {
  stocks,      // Ações
  bonds,       // Obrigações
  funds,       // Fundos
  crypto,      // Criptomoedas
  precious,    // Metais preciosos
}

/// Investment Status Enum
enum InvestmentStatus {
  active,      // Ativo
  paused,      // Pausado
  closed,      // Fechado
  cancelled,   // Cancelado
}

/// Investment Model
class InvestmentModel {
  const InvestmentModel({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.name,
    required this.type,
    required this.quantity,
    required this.purchasePrice,
    required this.currentPrice,
    required this.investmentDate,
    this.status = InvestmentStatus.active,
    this.description = '',
    this.currency = 'EUR',
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String symbol;           // e.g., AAPL, BTC, VANGUARD
  final String name;
  final InvestmentType type;
  final double quantity;
  final double purchasePrice;    // Preço de compra
  final double currentPrice;     // Preço atual
  final DateTime investmentDate;
  final InvestmentStatus status;
  final String description;
  final String currency;
  final String notes;
  final DateTime? createdAt;

  /// Create from Firestore document
  factory InvestmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvestmentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      symbol: data['symbol'] ?? '',
      name: data['name'] ?? '',
      type: _parseType(data['type']),
      quantity: (data['quantity'] ?? 0).toDouble(),
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      currentPrice: (data['currentPrice'] ?? 0).toDouble(),
      investmentDate: (data['investmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status']),
      description: data['description'] ?? '',
      currency: data['currency'] ?? 'EUR',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'symbol': symbol,
      'name': name,
      'type': type.name,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'currentPrice': currentPrice,
      'investmentDate': Timestamp.fromDate(investmentDate),
      'status': status.name,
      'description': description,
      'currency': currency,
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  InvestmentModel copyWith({
    String? id,
    String? userId,
    String? symbol,
    String? name,
    InvestmentType? type,
    double? quantity,
    double? purchasePrice,
    double? currentPrice,
    DateTime? investmentDate,
    InvestmentStatus? status,
    String? description,
    String? currency,
    String? notes,
    DateTime? createdAt,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      investmentDate: investmentDate ?? this.investmentDate,
      status: status ?? this.status,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static InvestmentType _parseType(String? type) {
    switch (type) {
      case 'stocks':
        return InvestmentType.stocks;
      case 'bonds':
        return InvestmentType.bonds;
      case 'funds':
        return InvestmentType.funds;
      case 'crypto':
        return InvestmentType.crypto;
      case 'precious':
        return InvestmentType.precious;
      default:
        return InvestmentType.stocks;
    }
  }

  static InvestmentStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return InvestmentStatus.active;
      case 'paused':
        return InvestmentStatus.paused;
      case 'closed':
        return InvestmentStatus.closed;
      case 'cancelled':
        return InvestmentStatus.cancelled;
      default:
        return InvestmentStatus.active;
    }
  }

  /// Get type display name
  String get typeDisplayName {
    switch (type) {
      case InvestmentType.stocks:
        return 'Ações';
      case InvestmentType.bonds:
        return 'Obrigações';
      case InvestmentType.funds:
        return 'Fundos';
      case InvestmentType.crypto:
        return 'Criptomoedas';
      case InvestmentType.precious:
        return 'Metais Preciosos';
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case InvestmentStatus.active:
        return 'Ativo';
      case InvestmentStatus.paused:
        return 'Pausado';
      case InvestmentStatus.closed:
        return 'Fechado';
      case InvestmentStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Get total invested (quantity * purchase price)
  double get totalInvested => quantity * purchasePrice;

  /// Get current value (quantity * current price)
  double get currentValue => quantity * currentPrice;

  /// Get gain/loss amount
  double get gainLoss => currentValue - totalInvested;

  /// Get gain/loss percentage
  double get gainLossPercentage {
    if (totalInvested == 0) return 0;
    return (gainLoss / totalInvested) * 100;
  }

  /// Get formatted amount
  String formatAmount(double amount) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Check if investment is profitable
  bool get isProfit => gainLoss >= 0;

  @override
  String toString() {
    return 'InvestmentModel(symbol: $symbol, quantity: $quantity, gain: $gainLoss)';
  }
}
