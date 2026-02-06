import 'package:cloud_firestore/cloud_firestore.dart';

/// External Bank Account Model
/// Represents a bank account connected via Nordigen/Open Banking
class ExternalAccountModel {
  const ExternalAccountModel({
    required this.id,
    required this.userId,
    required this.nordigenAccountId,
    required this.requisitionId,
    required this.institutionId,
    required this.institutionName,
    this.institutionLogo,
    required this.iban,
    this.ownerName,
    this.currency = 'EUR',
    required this.linkedAt,
    required this.expiresAt,
    this.isActive = true,
    this.lastBalance,
    this.lastBalanceUpdate,
  });

  /// Internal ID (Firestore document ID)
  final String id;

  /// BJBank user ID
  final String userId;

  /// Nordigen account ID
  final String nordigenAccountId;

  /// Nordigen requisition ID
  final String requisitionId;

  /// Bank institution ID (e.g., 'CAIXA_GERAL_DE_DEPOSITOS_CGDIPTPL')
  final String institutionId;

  /// Bank display name (e.g., 'Caixa Geral de Depósitos')
  final String institutionName;

  /// Bank logo URL
  final String? institutionLogo;

  /// Account IBAN
  final String iban;

  /// Account owner name
  final String? ownerName;

  /// Currency code
  final String currency;

  /// When the account was linked
  final DateTime linkedAt;

  /// When the consent expires (90 days per PSD2)
  final DateTime expiresAt;

  /// Whether the account is currently active
  final bool isActive;

  /// Last known balance
  final double? lastBalance;

  /// Last balance update timestamp
  final DateTime? lastBalanceUpdate;

  /// Create from Firestore document
  factory ExternalAccountModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExternalAccountModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      nordigenAccountId: data['nordigenAccountId'] ?? '',
      requisitionId: data['requisitionId'] ?? '',
      institutionId: data['institutionId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      institutionLogo: data['institutionLogo'],
      iban: data['iban'] ?? '',
      ownerName: data['ownerName'],
      currency: data['currency'] ?? 'EUR',
      linkedAt: (data['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 90)),
      isActive: data['isActive'] ?? true,
      lastBalance: (data['lastBalance'] as num?)?.toDouble(),
      lastBalanceUpdate: (data['lastBalanceUpdate'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'nordigenAccountId': nordigenAccountId,
      'requisitionId': requisitionId,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'institutionLogo': institutionLogo,
      'iban': iban,
      'ownerName': ownerName,
      'currency': currency,
      'linkedAt': Timestamp.fromDate(linkedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'lastBalance': lastBalance,
      'lastBalanceUpdate': lastBalanceUpdate != null
          ? Timestamp.fromDate(lastBalanceUpdate!)
          : null,
    };
  }

  /// Copy with updated fields
  ExternalAccountModel copyWith({
    String? id,
    String? userId,
    String? nordigenAccountId,
    String? requisitionId,
    String? institutionId,
    String? institutionName,
    String? institutionLogo,
    String? iban,
    String? ownerName,
    String? currency,
    DateTime? linkedAt,
    DateTime? expiresAt,
    bool? isActive,
    double? lastBalance,
    DateTime? lastBalanceUpdate,
  }) {
    return ExternalAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nordigenAccountId: nordigenAccountId ?? this.nordigenAccountId,
      requisitionId: requisitionId ?? this.requisitionId,
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      institutionLogo: institutionLogo ?? this.institutionLogo,
      iban: iban ?? this.iban,
      ownerName: ownerName ?? this.ownerName,
      currency: currency ?? this.currency,
      linkedAt: linkedAt ?? this.linkedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      lastBalance: lastBalance ?? this.lastBalance,
      lastBalanceUpdate: lastBalanceUpdate ?? this.lastBalanceUpdate,
    );
  }

  /// Check if consent has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if consent is about to expire (within 7 days)
  bool get isExpiringSoon {
    final daysUntilExpiry = expiresAt.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  /// Get days until expiry
  int get daysUntilExpiry {
    final days = expiresAt.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }

  /// Check if account is usable (active and not expired)
  bool get isUsable => isActive && !isExpired;

  /// Masked IBAN for display (PT50 **** **** 1234)
  String get maskedIban {
    final cleaned = iban.replaceAll(' ', '');
    if (cleaned.length < 8) return iban;
    return '${cleaned.substring(0, 4)} **** **** ${cleaned.substring(cleaned.length - 4)}';
  }

  /// Formatted IBAN with spaces
  String get formattedIban {
    final cleaned = iban.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  /// Formatted last balance
  String? get formattedLastBalance {
    if (lastBalance == null) return null;
    final parts = lastBalance!.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '€$intPart,${parts[1]}';
  }

  /// Short institution name for display
  String get shortName {
    // Handle common Portuguese bank names
    if (institutionName.toLowerCase().contains('caixa geral')) {
      return 'CGD';
    } else if (institutionName.toLowerCase().contains('millennium')) {
      return 'BCP';
    } else if (institutionName.toLowerCase().contains('novo banco')) {
      return 'Novo Banco';
    } else if (institutionName.toLowerCase().contains('santander')) {
      return 'Santander';
    } else if (institutionName.toLowerCase().contains('bpi')) {
      return 'BPI';
    } else if (institutionName.toLowerCase().contains('bankinter')) {
      return 'Bankinter';
    } else if (institutionName.toLowerCase().contains('activobank')) {
      return 'ActivoBank';
    } else if (institutionName.toLowerCase().contains('montepio')) {
      return 'Montepio';
    }
    // Return first word if name is too long
    final words = institutionName.split(' ');
    return words.first.length > 15
        ? words.first.substring(0, 12) + '...'
        : words.first;
  }

  @override
  String toString() {
    return 'ExternalAccountModel(id: $id, bank: $institutionName, iban: $maskedIban)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExternalAccountModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
