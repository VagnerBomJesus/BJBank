/// Status of a money request (MB WAY "pedir dinheiro").
enum MoneyRequestStatus { pending, approved, declined, cancelled }

/// A request for money sent from one user (requester) to another (payer)
/// over MB WAY. The payer can approve (executes the payment) or decline.
class MoneyRequest {
  const MoneyRequest({
    required this.id,
    required this.requesterUserId,
    required this.requesterName,
    required this.requesterPhone,
    required this.payerPhone,
    this.payerUserId,
    required this.amount,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String requesterUserId;
  final String requesterName;
  final String requesterPhone;
  final String payerPhone;
  final String? payerUserId;
  final double amount;
  final String? description;
  final MoneyRequestStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  bool get isPending => status == MoneyRequestStatus.pending;

  String get formattedAmount {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '€ $intPart,${parts[1]}';
  }

  static MoneyRequestStatus statusFromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'APPROVED':
        return MoneyRequestStatus.approved;
      case 'DECLINED':
        return MoneyRequestStatus.declined;
      case 'CANCELLED':
        return MoneyRequestStatus.cancelled;
      default:
        return MoneyRequestStatus.pending;
    }
  }

  factory MoneyRequest.fromRow(Map<String, dynamic> row) {
    return MoneyRequest(
      id: row['id'] as String,
      requesterUserId: row['requester_user_id'] as String,
      requesterName: (row['requester_name'] as String?) ?? 'Utilizador',
      requesterPhone: (row['requester_phone'] as String?) ?? '',
      payerPhone: (row['payer_phone'] as String?) ?? '',
      payerUserId: row['payer_user_id'] as String?,
      amount: (row['amount'] as num).toDouble(),
      description: row['description'] as String?,
      status: statusFromString(row['status'] as String?),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      resolvedAt: row['resolved_at'] != null
          ? DateTime.tryParse(row['resolved_at'] as String)
          : null,
    );
  }
}
