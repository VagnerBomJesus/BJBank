import 'package:cloud_firestore/cloud_firestore.dart';

/// Budget Status Enum
enum BudgetStatus {
  active,      // Ativa
  paused,      // Pausada
  completed,   // Completada (período terminou)
  exceeded,    // Excedida
  cancelled,   // Cancelada
}

/// Budget Period Enum
enum BudgetPeriod {
  weekly,      // Semanal
  monthly,     // Mensal
  quarterly,   // Trimestral
  yearly,      // Anual
}

/// Budget Model
class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.status = BudgetStatus.active,
    this.currency = 'EUR',
    this.alertThreshold = 80.0,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String category;
  final double limitAmount;
  final double spentAmount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final BudgetStatus status;
  final String currency;
  final double alertThreshold;  // Percentage (0-100)
  final DateTime? createdAt;

  /// Create from Firestore document
  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      limitAmount: (data['limitAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      period: _parsePeriod(data['period']),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status']),
      currency: data['currency'] ?? 'EUR',
      alertThreshold: (data['alertThreshold'] ?? 80.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'period': period.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
      'currency': currency,
      'alertThreshold': alertThreshold,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  BudgetModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    double? limitAmount,
    double? spentAmount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    BudgetStatus? status,
    String? currency,
    double? alertThreshold,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static BudgetPeriod _parsePeriod(String? period) {
    switch (period) {
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'monthly':
        return BudgetPeriod.monthly;
      case 'quarterly':
        return BudgetPeriod.quarterly;
      case 'yearly':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }

  static BudgetStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return BudgetStatus.active;
      case 'paused':
        return BudgetStatus.paused;
      case 'completed':
        return BudgetStatus.completed;
      case 'exceeded':
        return BudgetStatus.exceeded;
      case 'cancelled':
        return BudgetStatus.cancelled;
      default:
        return BudgetStatus.active;
    }
  }

  /// Get period display name
  String get periodDisplayName {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Semanal';
      case BudgetPeriod.monthly:
        return 'Mensal';
      case BudgetPeriod.quarterly:
        return 'Trimestral';
      case BudgetPeriod.yearly:
        return 'Anual';
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case BudgetStatus.active:
        return 'Ativa';
      case BudgetStatus.paused:
        return 'Pausada';
      case BudgetStatus.completed:
        return 'Completada';
      case BudgetStatus.exceeded:
        return 'Excedida';
      case BudgetStatus.cancelled:
        return 'Cancelada';
    }
  }

  /// Get remaining budget
  double get remainingBudget => limitAmount - spentAmount;

  /// Get spent percentage
  double get spentPercentage {
    if (limitAmount == 0) return 0;
    return (spentAmount / limitAmount) * 100;
  }

  /// Check if budget is exceeded
  bool get isExceeded => spentAmount > limitAmount;

  /// Check if alert threshold is reached
  bool get isAlertThresholdReached => spentPercentage >= alertThreshold;

  /// Check if budget is active (period is ongoing)
  bool get isPeriodActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get days remaining in budget period
  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Get formatted amount
  String formatAmount(double amt) {
    return '$currency ${amt.toStringAsFixed(2)}';
  }

  /// Get daily budget remaining
  double get dailyBudgetRemaining {
    if (daysRemaining <= 0) return 0;
    return remainingBudget / daysRemaining;
  }

  @override
  String toString() {
    return 'BudgetModel(name: $name, category: $category, limit: ${formatAmount(limitAmount)}, spent: ${formatAmount(spentAmount)}, status: $statusDisplayName)';
  }
}
