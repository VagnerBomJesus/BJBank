import 'package:bjbank/compat/firestore_compat.dart';

/// MB WAY Contact Model
/// Represents a recent contact for MB WAY transfers
class MbWayContact {
  const MbWayContact({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.lastUsed,
    this.useCount = 1,
  });

  final String id;
  final String name;
  final String phone;       // +351XXXXXXXXX
  final String? avatarUrl;
  final DateTime lastUsed;
  final int useCount;

  /// Get formatted phone number (+351 912 345 678)
  String get formattedPhone {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length == 13 && cleaned.startsWith('+351')) {
      return '+351 ${cleaned.substring(4, 7)} ${cleaned.substring(7, 10)} ${cleaned.substring(10)}';
    }
    return phone;
  }

  /// Get initials from name (e.g., "João Silva" -> "JS")
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  /// Get first name
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts[0] : name;
  }

  /// Create from a generic map (Supabase row, JSON, etc.).
  factory MbWayContact.fromMap(Map<String, dynamic> data, {String? id}) {
    return MbWayContact(
      id: id ?? data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      avatarUrl: data['avatarUrl'] ?? data['avatar_url'],
      lastUsed: data['lastUsed'] is String
          ? DateTime.tryParse(data['lastUsed']) ?? DateTime.now()
          : data['last_used'] is String
              ? DateTime.tryParse(data['last_used']) ?? DateTime.now()
              : DateTime.now(),
      useCount: ((data['useCount'] ?? data['use_count']) ?? 1) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'last_used': lastUsed.toIso8601String(),
        'use_count': useCount,
      };

  // Aliases legacy
  factory MbWayContact.fromFirestore(DocumentSnapshot doc) =>
      MbWayContact.fromMap((doc.data() as Map<String, dynamic>?) ?? const {},
          id: doc.id);
  Map<String, dynamic> toFirestore() => toMap();

  /// Create a copy with updated fields
  MbWayContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? avatarUrl,
    DateTime? lastUsed,
    int? useCount,
  }) {
    return MbWayContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastUsed: lastUsed ?? this.lastUsed,
      useCount: useCount ?? this.useCount,
    );
  }

  @override
  String toString() {
    return 'MbWayContact(id: $id, name: $name, phone: $formattedPhone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MbWayContact && other.phone == phone;
  }

  @override
  int get hashCode => phone.hashCode;
}
