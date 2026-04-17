import 'package:cloud_firestore/cloud_firestore.dart';

/// Bill Status Enum
enum BillStatus {
  pending,     // Por pagar
  paid,        // Pago
  overdue,     // Vencido
  scheduled,   // Agendado
  cancelled,   // Cancelado
}

/// Bill Frequency Enum
enum BillFrequency {
  once,        // Única vez
  weekly,      // Semanal
  monthly,     // Mensal
  quarterly,   // Trimestral
  yearly,      // Anual
}

/// Bill Category Enum
enum BillCategory {
  utilities,        // Serviços (água, luz, gás)
  insurance,        // Seguros
  subscription,     // Subscrições
  rent,            // Renda
  education,       // Educação
  healthcare,      // Saúde
  transport,       // Transporte
  entertainment,   // Entretenimento
  telecommunications, // Telecomunicações
  other,           // Outro
}

/// Bill Model for BJBank
class BillModel {
  const BillModel({
    required this.id,
    required this.userId,
    required this.creditorName,
    required this.amount,
    required this.dueDate,
    required this.category,
    this.status = BillStatus.pending,
    this.description = '',
    this.reference = '',
    this.frequency = BillFrequency.once,
    this.nextDueDate,
    this.lastPaidDate,
    this.notes = '',
    this.autoPayEnabled = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String creditorName;
  final double amount;
  final DateTime dueDate;
  final BillCategory category;
  final BillStatus status;
  final String description;
  final String reference;      // Reference number for payment
  final BillFrequency frequency;
  final DateTime? nextDueDate;
  final DateTime? lastPaidDate;
  final String notes;
  final bool autoPayEnabled;
  final DateTime? createdAt;

  /// Create BillModel from Firestore document
  factory BillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      creditorName: data['creditorName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: _parseCategory(data['category']),
      status: _parseStatus(data['status']),
      description: data['description'] ?? '',
      reference: data['reference'] ?? '',
      frequency: _parseFrequency(data['frequency']),
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate(),
      lastPaidDate: (data['lastPaidDate'] as Timestamp?)?.toDate(),
      notes: data['notes'] ?? '',
      autoPayEnabled: data['autoPayEnabled'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'creditorName': creditorName,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'category': category.name,
      'status': status.name,
      'description': description,
      'reference': reference,
      'frequency': frequency.name,
      'nextDueDate': nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
      'lastPaidDate': lastPaidDate != null ? Timestamp.fromDate(lastPaidDate!) : null,
      'notes': notes,
      'autoPayEnabled': autoPayEnabled,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  BillModel copyWith({
    String? id,
    String? userId,
    String? creditorName,
    double? amount,
    DateTime? dueDate,
    BillCategory? category,
    BillStatus? status,
    String? description,
    String? reference,
    BillFrequency? frequency,
    DateTime? nextDueDate,
    DateTime? lastPaidDate,
    String? notes,
    bool? autoPayEnabled,
    DateTime? createdAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      creditorName: creditorName ?? this.creditorName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      status: status ?? this.status,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastPaidDate: lastPaidDate ?? this.lastPaidDate,
      notes: notes ?? this.notes,
      autoPayEnabled: autoPayEnabled ?? this.autoPayEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static BillCategory _parseCategory(String? category) {
    switch (category) {
      case 'utilities':
        return BillCategory.utilities;
      case 'insurance':
        return BillCategory.insurance;
      case 'subscription':
        return BillCategory.subscription;
      case 'rent':
        return BillCategory.rent;
      case 'education':
        return BillCategory.education;
      case 'healthcare':
        return BillCategory.healthcare;
      case 'transport':
        return BillCategory.transport;
      case 'entertainment':
        return BillCategory.entertainment;
      case 'telecommunications':
        return BillCategory.telecommunications;
      default:
        return BillCategory.other;
    }
  }

  static BillStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return BillStatus.pending;
      case 'paid':
        return BillStatus.paid;
      case 'overdue':
        return BillStatus.overdue;
      case 'scheduled':
        return BillStatus.scheduled;
      case 'cancelled':
        return BillStatus.cancelled;
      default:
        return BillStatus.pending;
    }
  }

  static BillFrequency _parseFrequency(String? frequency) {
    switch (frequency) {
      case 'once':
        return BillFrequency.once;
      case 'weekly':
        return BillFrequency.weekly;
      case 'monthly':
        return BillFrequency.monthly;
      case 'quarterly':
        return BillFrequency.quarterly;
      case 'yearly':
        return BillFrequency.yearly;
      default:
        return BillFrequency.once;
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case BillStatus.pending:
        return 'Por Pagar';
      case BillStatus.paid:
        return 'Pago';
      case BillStatus.overdue:
        return 'Vencido';
      case BillStatus.scheduled:
        return 'Agendado';
      case BillStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case BillCategory.utilities:
        return 'Serviços';
      case BillCategory.insurance:
        return 'Seguros';
      case BillCategory.subscription:
        return 'Subscrições';
      case BillCategory.rent:
        return 'Renda';
      case BillCategory.education:
        return 'Educação';
      case BillCategory.healthcare:
        return 'Saúde';
      case BillCategory.transport:
        return 'Transporte';
      case BillCategory.entertainment:
        return 'Entretenimento';
      case BillCategory.telecommunications:
        return 'Telecomunicações';
      case BillCategory.other:
        return 'Outro';
    }
  }

  /// Get frequency display name
  String get frequencyDisplayName {
    switch (frequency) {
      case BillFrequency.once:
        return 'Única vez';
      case BillFrequency.weekly:
        return 'Semanal';
      case BillFrequency.monthly:
        return 'Mensal';
      case BillFrequency.quarterly:
        return 'Trimestral';
      case BillFrequency.yearly:
        return 'Anual';
    }
  }

  /// Check if bill is overdue
  bool get isOverdue => status == BillStatus.overdue ||
      (status == BillStatus.pending && dueDate.isBefore(DateTime.now()));

  /// Check if bill is due soon (within 7 days)
  bool get isDueSoon =>
      !isOverdue &&
      status == BillStatus.pending &&
      dueDate.difference(DateTime.now()).inDays <= 7;

  /// Get days until due date
  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }

  /// Get formatted amount
  String get formattedAmount {
    return '€ ${amount.toStringAsFixed(2)}';
  }

  /// Get formatted due date
  String get formattedDueDate {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Há ${-difference} dias';
    } else if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Amanhã';
    } else if (difference <= 7) {
      return 'Em $difference dias';
    } else {
      return '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
    }
  }

  @override
  String toString() {
    return 'BillModel(id: $id, creditor: $creditorName, amount: $formattedAmount)';
  }
}
