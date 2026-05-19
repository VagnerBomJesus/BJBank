import 'package:bjbank/compat/firestore_compat.dart';

/// User Status Enum
enum UserStatus {
  active,
  inactive,
  suspended,
  pendingVerification,
}

/// User Model for BJBank
/// Represents a registered user with PQC security
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.iban,
    this.pqcPublicKey,
    this.photoUrl,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.status = UserStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final String? phone;           // Portuguese format: +351 xxx xxx xxx
  final String? iban;            // Portuguese IBAN: PT50 xxxx xxxx xxxx xxxx xxxx x
  final String? pqcPublicKey;    // Dilithium public key (Base64)
  final String? photoUrl;        // Profile photo (base64 or local path)
  final bool emailVerified;
  final bool phoneVerified;
  final UserStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Create UserModel from a generic map (Supabase row, JSON).
  factory UserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    DateTime? parse(dynamic v) =>
        v is String ? DateTime.tryParse(v) : (v is DateTime ? v : null);
    return UserModel(
      id: id ?? data['id']?.toString() ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? data['nome_completo'] ?? '',
      phone: data['phone'],
      iban: data['iban'],
      pqcPublicKey: data['pqcPublicKey'] ?? data['pqc_public_key_base64'],
      photoUrl: data['photoUrl'] ?? data['photo_url'],
      emailVerified: data['emailVerified'] ?? data['email_verified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? data['phone_verified'] ?? false,
      status: _parseStatus(data['status']),
      createdAt: parse(data['createdAt'] ?? data['created_at']),
      updatedAt: parse(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'phone': phone,
        'iban': iban,
        'pqc_public_key_base64': pqcPublicKey,
        'photo_url': photoUrl,
        'email_verified': emailVerified,
        'phone_verified': phoneVerified,
        'status': status.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  // Aliases legacy para nao quebrar firestore_service e seed_data_service.
  factory UserModel.fromFirestore(DocumentSnapshot doc) =>
      UserModel.fromMap((doc.data() as Map<String, dynamic>?) ?? const {},
          id: doc.id);
  Map<String, dynamic> toFirestore() => toMap();

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? iban,
    String? pqcPublicKey,
    String? photoUrl,
    bool? emailVerified,
    bool? phoneVerified,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      iban: iban ?? this.iban,
      pqcPublicKey: pqcPublicKey ?? this.pqcPublicKey,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parse status string to enum
  static UserStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'suspended':
        return UserStatus.suspended;
      case 'pendingVerification':
        return UserStatus.pendingVerification;
      default:
        return UserStatus.active;
    }
  }

  /// Check if user has completed profile
  bool get hasCompleteProfile =>
      name.isNotEmpty &&
      email.isNotEmpty &&
      phone != null &&
      phone!.isNotEmpty;

  /// Check if user has PQC keys configured
  bool get hasPqcKeys => pqcPublicKey != null && pqcPublicKey!.isNotEmpty;

  /// Get formatted phone number
  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return '';
    // Format: +351 912 345 678
    final cleaned = phone!.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length >= 12) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7, 10)} ${cleaned.substring(10)}';
    }
    return phone!;
  }

  /// Get masked IBAN for display
  String get maskedIban {
    if (iban == null || iban!.isEmpty) return '';
    if (iban!.length > 8) {
      return '${iban!.substring(0, 4)} •••• •••• ${iban!.substring(iban!.length - 4)}';
    }
    return iban!;
  }

  /// Get first name
  String get firstName {
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }

  /// Get initials
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
