import 'package:bjbank/compat/firestore_compat.dart';

/// Savings Goal Status Enum
enum SavingsGoalStatus {
  active,      // Ativa
  paused,      // Pausada
  completed,   // Completada
  cancelled,   // Cancelada
}

/// Savings Goal Priority Enum
enum SavingsGoalPriority {
  low,         // Baixa
  medium,      // Média
  high,        // Alta
  critical,    // Crítica
}

/// Savings Goal Category Enum
enum SavingsGoalCategory {
  vacation,       // Férias
  emergency,      // Emergência
  home,           // Casa
  education,      // Educação
  vehicle,        // Veículo
  wedding,        // Casamento
  investment,     // Investimento
  other,          // Outro
}

/// Savings Goal Model
class SavingsGoalModel {
  const SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.targetAmount,
    required this.currentAmount,
    required this.priority,
    required this.targetDate,
    this.status = SavingsGoalStatus.active,
    this.currency = 'EUR',
    this.icon = '💰',
    this.color = '#6200EE',
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final SavingsGoalCategory category;
  final double targetAmount;
  final double currentAmount;
  final SavingsGoalPriority priority;
  final DateTime targetDate;
  final SavingsGoalStatus status;
  final String currency;
  final String icon;
  final String color;
  final DateTime? createdAt;
  final DateTime? completedAt;

  /// Create from Firestore document
  factory SavingsGoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsGoalModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: _parseCategory(data['category']),
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      priority: _parsePriority(data['priority']),
      targetDate: (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status']),
      currency: data['currency'] ?? 'EUR',
      icon: data['icon'] ?? '💰',
      color: data['color'] ?? '#6200EE',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'category': category.name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'priority': priority.name,
      'targetDate': Timestamp.fromDate(targetDate),
      'status': status.name,
      'currency': currency,
      'icon': icon,
      'color': color,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  SavingsGoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    SavingsGoalCategory? category,
    double? targetAmount,
    double? currentAmount,
    SavingsGoalPriority? priority,
    DateTime? targetDate,
    SavingsGoalStatus? status,
    String? currency,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      priority: priority ?? this.priority,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static SavingsGoalCategory _parseCategory(String? category) {
    switch (category) {
      case 'vacation':
        return SavingsGoalCategory.vacation;
      case 'emergency':
        return SavingsGoalCategory.emergency;
      case 'home':
        return SavingsGoalCategory.home;
      case 'education':
        return SavingsGoalCategory.education;
      case 'vehicle':
        return SavingsGoalCategory.vehicle;
      case 'wedding':
        return SavingsGoalCategory.wedding;
      case 'investment':
        return SavingsGoalCategory.investment;
      default:
        return SavingsGoalCategory.other;
    }
  }

  static SavingsGoalPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'low':
        return SavingsGoalPriority.low;
      case 'medium':
        return SavingsGoalPriority.medium;
      case 'high':
        return SavingsGoalPriority.high;
      case 'critical':
        return SavingsGoalPriority.critical;
      default:
        return SavingsGoalPriority.medium;
    }
  }

  static SavingsGoalStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return SavingsGoalStatus.active;
      case 'paused':
        return SavingsGoalStatus.paused;
      case 'completed':
        return SavingsGoalStatus.completed;
      case 'cancelled':
        return SavingsGoalStatus.cancelled;
      default:
        return SavingsGoalStatus.active;
    }
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case SavingsGoalCategory.vacation:
        return 'Férias';
      case SavingsGoalCategory.emergency:
        return 'Emergência';
      case SavingsGoalCategory.home:
        return 'Casa';
      case SavingsGoalCategory.education:
        return 'Educação';
      case SavingsGoalCategory.vehicle:
        return 'Veículo';
      case SavingsGoalCategory.wedding:
        return 'Casamento';
      case SavingsGoalCategory.investment:
        return 'Investimento';
      case SavingsGoalCategory.other:
        return 'Outro';
    }
  }

  /// Get priority display name
  String get priorityDisplayName {
    switch (priority) {
      case SavingsGoalPriority.low:
        return 'Baixa';
      case SavingsGoalPriority.medium:
        return 'Média';
      case SavingsGoalPriority.high:
        return 'Alta';
      case SavingsGoalPriority.critical:
        return 'Crítica';
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case SavingsGoalStatus.active:
        return 'Ativa';
      case SavingsGoalStatus.paused:
        return 'Pausada';
      case SavingsGoalStatus.completed:
        return 'Completada';
      case SavingsGoalStatus.cancelled:
        return 'Cancelada';
    }
  }

  /// Get remaining amount to save
  double get remainingAmount => targetAmount - currentAmount;

  /// Get progress percentage
  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount) * 100;
  }

  /// Check if goal is completed
  bool get isCompleted => currentAmount >= targetAmount;

  /// Get days remaining until target date
  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  /// Check if target date is passed
  bool get isOverdue => daysRemaining < 0 && !isCompleted;

  /// Get formatted amount
  String formatAmount(double amt) {
    return '$currency ${amt.toStringAsFixed(2)}';
  }

  /// Get daily savings needed to reach target
  double get dailySavingsNeeded {
    if (daysRemaining <= 0) return 0;
    return remainingAmount / daysRemaining;
  }

  /// Get monthly savings needed to reach target
  double get monthlySavingsNeeded {
    if (daysRemaining <= 0) return 0;
    final monthsRemaining = daysRemaining / 30;
    return remainingAmount / monthsRemaining;
  }

  @override
  String toString() {
    return 'SavingsGoalModel(name: $name, target: ${formatAmount(targetAmount)}, progress: $progressPercentage%, status: $statusDisplayName)';
  }
}
