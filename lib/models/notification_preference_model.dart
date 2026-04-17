/// Notification Type Enum
enum NotificationType {
  transaction, // Transactions and transfers
  security,    // Security alerts and logins
  bill,        // Bill reminders
  loan,        // Loan payment reminders
  goal,        // Savings goal updates
  marketing,   // Promotional and marketing
}

/// Notification Preference Model
///
/// Stores user preferences for different types of notifications
/// including sound, vibration, quiet hours, and enable/disable settings
class NotificationPreference {
  /// Unique preference ID
  final String id;

  /// User ID
  final String userId;

  /// Notification type
  final NotificationType type;

  /// Whether notifications of this type are enabled
  final bool enabled;

  /// Whether to play sound for this notification type
  final bool soundEnabled;

  /// Whether to vibrate for this notification type
  final bool vibrationEnabled;

  /// Custom notification sound (optional)
  /// Default system sound if null
  final String? customSound;

  /// Start time for quiet hours (HH:mm format)
  /// Null means no quiet hours
  final String? quietHoursStart;

  /// End time for quiet hours (HH:mm format)
  /// Null means no quiet hours
  final String? quietHoursEnd;

  /// When this preference was created
  final DateTime createdAt;

  /// When this preference was last updated
  final DateTime updatedAt;

  const NotificationPreference({
    required this.id,
    required this.userId,
    required this.type,
    required this.enabled,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.customSound,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if notification should be sent based on quiet hours
  bool isWithinQuietHours() {
    if (quietHoursStart == null || quietHoursEnd == null) {
      return false; // No quiet hours set
    }

    final now = DateTime.now();
    final startTime = _parseTime(quietHoursStart!);
    final endTime = _parseTime(quietHoursEnd!);

    if (endTime.isBefore(startTime)) {
      // Quiet hours span midnight (e.g., 22:00 - 06:00)
      return now.isAfter(startTime) || now.isBefore(endTime);
    } else {
      // Quiet hours don't span midnight
      return now.isAfter(startTime) && now.isBefore(endTime);
    }
  }

  /// Check if notification should be sent
  bool shouldSendNotification() {
    if (!enabled) return false;
    if (isWithinQuietHours()) return false;
    return true;
  }

  /// Parse time string (HH:mm) to TimeOfDay
  static DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) {
      return DateTime.now();
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Get notification type label in Portuguese
  String getTypeLabel() {
    switch (type) {
      case NotificationType.transaction:
        return 'Transações';
      case NotificationType.security:
        return 'Segurança';
      case NotificationType.bill:
        return 'Faturas';
      case NotificationType.loan:
        return 'Empréstimos';
      case NotificationType.goal:
        return 'Objetivos';
      case NotificationType.marketing:
        return 'Marketing';
    }
  }

  /// Get notification type icon
  String getTypeIcon() {
    switch (type) {
      case NotificationType.transaction:
        return '💳';
      case NotificationType.security:
        return '🔐';
      case NotificationType.bill:
        return '📋';
      case NotificationType.loan:
        return '💰';
      case NotificationType.goal:
        return '🎯';
      case NotificationType.marketing:
        return '📢';
    }
  }

  /// Create a copy with updated fields
  NotificationPreference copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    bool? enabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? customSound,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      customSound: customSound ?? this.customSound,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'enabled': enabled,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'customSound': customSound,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Create from JSON
  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.values.byName(json['type'] ?? 'transaction'),
      enabled: json['enabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      customSound: json['customSound'],
      quietHoursStart: json['quietHoursStart'],
      quietHoursEnd: json['quietHoursEnd'],
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'NotificationPreference(type: $type, enabled: $enabled, sound: $soundEnabled)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationPreference &&
        other.id == id &&
        other.userId == userId &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ type.hashCode;
}
