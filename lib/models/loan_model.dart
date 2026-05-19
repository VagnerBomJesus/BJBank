import 'package:bjbank/compat/firestore_compat.dart';

/// Loan Status Enum
enum LoanStatus {
  pending,     // Pendente
  approved,    // Aprovado
  active,      // Ativo
  completed,   // Completado
  defaulted,   // Em incumprimento
  cancelled,   // Cancelado
}

/// Loan Type Enum
enum LoanType {
  personal,    // Pessoal
  mortgage,    // Hipotecário
  auto,        // Automóvel
  student,     // Educação
  business,    // Negócio
  other,       // Outro
}

/// Loan Model
class LoanModel {
  const LoanModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.interestRate,
    required this.term,           // in months
    required this.startDate,
    required this.endDate,
    this.status = LoanStatus.pending,
    this.description = '',
    this.monthlyPayment = 0.0,
    this.amountPaid = 0.0,
    this.nextPaymentDate,
    this.collateral = '',
    this.notes = '',
    this.currency = 'EUR',
    this.createdAt,
  });

  final String id;
  final String userId;
  final LoanType type;
  final double amount;
  final double interestRate;     // Annual percentage
  final int term;                // In months
  final DateTime startDate;
  final DateTime endDate;
  final LoanStatus status;
  final String description;
  final double monthlyPayment;
  final double amountPaid;
  final DateTime? nextPaymentDate;
  final String collateral;       // For mortgage, auto loans
  final String notes;
  final String currency;
  final DateTime? createdAt;

  /// Create from Firestore document
  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoanModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseType(data['type']),
      amount: (data['amount'] ?? 0).toDouble(),
      interestRate: (data['interestRate'] ?? 0).toDouble(),
      term: data['term'] ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status']),
      description: data['description'] ?? '',
      monthlyPayment: (data['monthlyPayment'] ?? 0).toDouble(),
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp?)?.toDate(),
      collateral: data['collateral'] ?? '',
      notes: data['notes'] ?? '',
      currency: data['currency'] ?? 'EUR',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'interestRate': interestRate,
      'term': term,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
      'description': description,
      'monthlyPayment': monthlyPayment,
      'amountPaid': amountPaid,
      'nextPaymentDate':
          nextPaymentDate != null ? Timestamp.fromDate(nextPaymentDate!) : null,
      'collateral': collateral,
      'notes': notes,
      'currency': currency,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  LoanModel copyWith({
    String? id,
    String? userId,
    LoanType? type,
    double? amount,
    double? interestRate,
    int? term,
    DateTime? startDate,
    DateTime? endDate,
    LoanStatus? status,
    String? description,
    double? monthlyPayment,
    double? amountPaid,
    DateTime? nextPaymentDate,
    String? collateral,
    String? notes,
    String? currency,
    DateTime? createdAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      term: term ?? this.term,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      description: description ?? this.description,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      amountPaid: amountPaid ?? this.amountPaid,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      collateral: collateral ?? this.collateral,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static LoanType _parseType(String? type) {
    switch (type) {
      case 'personal':
        return LoanType.personal;
      case 'mortgage':
        return LoanType.mortgage;
      case 'auto':
        return LoanType.auto;
      case 'student':
        return LoanType.student;
      case 'business':
        return LoanType.business;
      default:
        return LoanType.other;
    }
  }

  static LoanStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return LoanStatus.pending;
      case 'approved':
        return LoanStatus.approved;
      case 'active':
        return LoanStatus.active;
      case 'completed':
        return LoanStatus.completed;
      case 'defaulted':
        return LoanStatus.defaulted;
      case 'cancelled':
        return LoanStatus.cancelled;
      default:
        return LoanStatus.pending;
    }
  }

  /// Get type display name
  String get typeDisplayName {
    switch (type) {
      case LoanType.personal:
        return 'Pessoal';
      case LoanType.mortgage:
        return 'Hipotecário';
      case LoanType.auto:
        return 'Automóvel';
      case LoanType.student:
        return 'Educação';
      case LoanType.business:
        return 'Negócio';
      case LoanType.other:
        return 'Outro';
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case LoanStatus.pending:
        return 'Pendente';
      case LoanStatus.approved:
        return 'Aprovado';
      case LoanStatus.active:
        return 'Ativo';
      case LoanStatus.completed:
        return 'Completado';
      case LoanStatus.defaulted:
        return 'Incumprimento';
      case LoanStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Get remaining amount to pay
  double get remainingAmount => amount - amountPaid;

  /// Get remaining balance percentage
  double get remainingPercentage {
    if (amount == 0) return 0;
    return (remainingAmount / amount) * 100;
  }

  /// Get number of months paid
  int get monthsPaid {
    if (monthlyPayment == 0) return 0;
    return (amountPaid / monthlyPayment).toInt();
  }

  /// Get months remaining
  int get monthsRemaining => term - monthsPaid;

  /// Get total interest paid
  double get totalInterestCost {
    return (monthlyPayment * term) - amount;
  }

  /// Check if loan is overdue
  bool get isOverdue {
    if (nextPaymentDate == null) return false;
    return nextPaymentDate!.isBefore(DateTime.now());
  }

  /// Get formatted amount
  String formatAmount(double amt) {
    return '$currency ${amt.toStringAsFixed(2)}';
  }

  /// Get progress percentage (for UI)
  double get progressPercentage => 100 - remainingPercentage;

  @override
  String toString() {
    return 'LoanModel(type: $typeDisplayName, amount: ${formatAmount(amount)}, status: $statusDisplayName)';
  }
}
