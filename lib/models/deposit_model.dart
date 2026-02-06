import 'package:cloud_firestore/cloud_firestore.dart';

/// Deposit Status
enum DepositStatus {
  pending,     // Waiting to be processed
  processing,  // Being processed
  completed,   // Successfully completed
  failed,      // Failed
  cancelled,   // Cancelled by user
}

/// Deposit Model for BJBank
/// Represents a deposit transaction from external bank to BJBank
class DepositModel {
  const DepositModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.externalAccountId,
    required this.amount,
    this.currency = 'EUR',
    this.status = DepositStatus.pending,
    this.nordigenPaymentId,
    this.pqcSignature,
    this.createdAt,
    this.completedAt,
    this.failureReason,
    this.externalAccountIban,
    this.externalBankName,
  });

  /// Unique deposit ID
  final String id;

  /// BJBank user ID
  final String userId;

  /// BJBank account ID (destination)
  final String accountId;

  /// External account ID (source)
  final String externalAccountId;

  /// Deposit amount
  final double amount;

  /// Currency (EUR)
  final String currency;

  /// Current status
  final DepositStatus status;

  /// Nordigen payment ID (if applicable)
  final String? nordigenPaymentId;

  /// PQC signature for security
  final String? pqcSignature;

  /// Creation timestamp
  final DateTime? createdAt;

  /// Completion timestamp
  final DateTime? completedAt;

  /// Failure reason (if status is failed)
  final String? failureReason;

  /// External account IBAN (for display)
  final String? externalAccountIban;

  /// External bank name (for display)
  final String? externalBankName;

  /// Create from Firestore document
  factory DepositModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepositModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      accountId: data['accountId'] ?? '',
      externalAccountId: data['externalAccountId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      status: _parseStatus(data['status']),
      nordigenPaymentId: data['nordigenPaymentId'],
      pqcSignature: data['pqcSignature'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      failureReason: data['failureReason'],
      externalAccountIban: data['externalAccountIban'],
      externalBankName: data['externalBankName'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'accountId': accountId,
      'externalAccountId': externalAccountId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'nordigenPaymentId': nordigenPaymentId,
      'pqcSignature': pqcSignature,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'failureReason': failureReason,
      'externalAccountIban': externalAccountIban,
      'externalBankName': externalBankName,
    };
  }

  /// Copy with updated fields
  DepositModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? externalAccountId,
    double? amount,
    String? currency,
    DepositStatus? status,
    String? nordigenPaymentId,
    String? pqcSignature,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
    String? externalAccountIban,
    String? externalBankName,
  }) {
    return DepositModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      externalAccountId: externalAccountId ?? this.externalAccountId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      nordigenPaymentId: nordigenPaymentId ?? this.nordigenPaymentId,
      pqcSignature: pqcSignature ?? this.pqcSignature,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      externalAccountIban: externalAccountIban ?? this.externalAccountIban,
      externalBankName: externalBankName ?? this.externalBankName,
    );
  }

  /// Parse status string to enum
  static DepositStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return DepositStatus.pending;
      case 'processing':
        return DepositStatus.processing;
      case 'completed':
        return DepositStatus.completed;
      case 'failed':
        return DepositStatus.failed;
      case 'cancelled':
        return DepositStatus.cancelled;
      default:
        return DepositStatus.pending;
    }
  }

  /// Formatted amount for display
  String get formattedAmount {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '€$intPart,${parts[1]}';
  }

  /// Status display name in Portuguese
  String get statusDisplayName {
    switch (status) {
      case DepositStatus.pending:
        return 'Pendente';
      case DepositStatus.processing:
        return 'A processar';
      case DepositStatus.completed:
        return 'Concluído';
      case DepositStatus.failed:
        return 'Falhou';
      case DepositStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Check if deposit is pending
  bool get isPending =>
      status == DepositStatus.pending || status == DepositStatus.processing;

  /// Check if deposit is completed
  bool get isCompleted => status == DepositStatus.completed;

  /// Check if deposit failed
  bool get isFailed =>
      status == DepositStatus.failed || status == DepositStatus.cancelled;

  @override
  String toString() {
    return 'DepositModel(id: $id, amount: $formattedAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DepositModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
