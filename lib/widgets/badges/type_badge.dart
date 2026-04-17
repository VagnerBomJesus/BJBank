import 'package:flutter/material.dart';
import '../../theme/spacing.dart';

/// Transaction Type Enum
enum TransactionType {
  transfer,        // Bank transfer
  deposit,         // Deposit
  withdrawal,      // Withdrawal
  payment,         // Payment/Bill
  qrPayment,       // QR code payment
  cardTransaction, // Card purchase
  salary,          // Salary/Income
  investment,      // Investment
  savings,         // Savings transfer
  loan,            // Loan transaction
  fee,             // Bank fees
  refund,          // Refund
  other,           // Other
}

/// Type Badge Widget
///
/// Displays transaction type with icon and label
/// Available variants:
/// - TypeBadge: Full badge with icon and label
/// - TypeIconBadge: Icon-only badge
/// - TypePillBadge: Pill-shaped badge
///
/// Example:
/// ```dart
/// TypeBadge(type: TransactionType.transfer)
/// TypeIconBadge(type: TransactionType.qrPayment)
/// TypePillBadge(type: TransactionType.salary, label: 'Salário')
/// ```
class TypeBadge extends StatelessWidget {
  /// Transaction type
  final TransactionType type;

  /// Optional custom label
  final String? label;

  /// Badge size
  final double size;

  /// Show label
  final bool showLabel;

  /// Custom colors
  final Color? backgroundColor;
  final Color? foregroundColor;

  const TypeBadge({
    Key? key,
    required this.type,
    this.label,
    this.size = 48,
    this.showLabel = true,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeData = _getTypeData(type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                backgroundColor ?? typeData.color.withValues(alpha: 0.15),
            border: Border.all(
              color: typeData.color.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Icon(
              typeData.icon,
              color: foregroundColor ?? typeData.color,
              size: size * 0.5,
            ),
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: BJBankSpacing.xs),
          Text(
            label ?? typeData.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  _TypeData _getTypeData(TransactionType type) {
    return switch (type) {
      TransactionType.transfer => _TypeData(
          icon: Icons.compare_arrows,
          label: 'Transferência',
          color: Colors.blue,
        ),
      TransactionType.deposit => _TypeData(
          icon: Icons.arrow_downward,
          label: 'Depósito',
          color: Colors.green,
        ),
      TransactionType.withdrawal => _TypeData(
          icon: Icons.arrow_upward,
          label: 'Levantamento',
          color: Colors.orange,
        ),
      TransactionType.payment => _TypeData(
          icon: Icons.receipt,
          label: 'Pagamento',
          color: Colors.purple,
        ),
      TransactionType.qrPayment => _TypeData(
          icon: Icons.qr_code_2,
          label: 'Pagamento QR',
          color: Colors.indigo,
        ),
      TransactionType.cardTransaction => _TypeData(
          icon: Icons.credit_card,
          label: 'Cartão',
          color: Colors.red,
        ),
      TransactionType.salary => _TypeData(
          icon: Icons.attach_money,
          label: 'Salário',
          color: Colors.green,
        ),
      TransactionType.investment => _TypeData(
          icon: Icons.trending_up,
          label: 'Investimento',
          color: Colors.teal,
        ),
      TransactionType.savings => _TypeData(
          icon: Icons.savings,
          label: 'Poupança',
          color: Colors.amber,
        ),
      TransactionType.loan => _TypeData(
          icon: Icons.account_balance,
          label: 'Empréstimo',
          color: Colors.cyan,
        ),
      TransactionType.fee => _TypeData(
          icon: Icons.info,
          label: 'Taxa',
          color: Colors.grey,
        ),
      TransactionType.refund => _TypeData(
          icon: Icons.undo,
          label: 'Reembolso',
          color: Colors.lightGreen,
        ),
      TransactionType.other => _TypeData(
          icon: Icons.more_horiz,
          label: 'Outro',
          color: Colors.blueGrey,
        ),
    };
  }
}

/// Type Icon Badge - Icon only
class TypeIconBadge extends StatelessWidget {
  /// Transaction type
  final TransactionType type;

  /// Icon size
  final double iconSize;

  /// Custom colors
  final Color? color;
  final Color? backgroundColor;

  const TypeIconBadge({
    Key? key,
    required this.type,
    this.iconSize = 24,
    this.color,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeData = _getTypeData(type);

    return Container(
      width: iconSize * 1.5,
      height: iconSize * 1.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? typeData.color.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Icon(
          typeData.icon,
          color: color ?? typeData.color,
          size: iconSize,
        ),
      ),
    );
  }

  _TypeData _getTypeData(TransactionType type) {
    return TypeBadge(type: type)._getTypeData(type);
  }
}

/// Type Pill Badge - Horizontal layout
class TypePillBadge extends StatelessWidget {
  /// Transaction type
  final TransactionType type;

  /// Optional custom label
  final String? label;

  /// Custom colors
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Show amount (optional)
  final String? amount;

  const TypePillBadge({
    Key? key,
    required this.type,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeData = TypeBadge(type: type)._getTypeData(type);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.md,
        vertical: BJBankSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? typeData.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeData.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            typeData.icon,
            color: foregroundColor ?? typeData.color,
            size: 18,
          ),
          SizedBox(width: BJBankSpacing.sm),
          Text(
            label ?? typeData.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foregroundColor ?? typeData.color,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (amount != null) ...[
            SizedBox(width: BJBankSpacing.sm),
            Text(
              amount!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foregroundColor ?? typeData.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Internal type data class
class _TypeData {
  final IconData icon;
  final String label;
  final Color color;

  _TypeData({
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// Transaction type helper extensions
extension TransactionTypeExtension on TransactionType {
  /// Get Portuguese label
  String get label {
    return TypeBadge(type: this)._getTypeData(this).label;
  }

  /// Get icon
  IconData get icon {
    return TypeBadge(type: this)._getTypeData(this).icon;
  }

  /// Get color
  Color get color {
    return TypeBadge(type: this)._getTypeData(this).color;
  }

  /// Check if transaction is incoming
  bool get isIncoming {
    return switch (this) {
      TransactionType.deposit ||
      TransactionType.salary ||
      TransactionType.refund =>
        true,
      _ => false,
    };
  }

  /// Check if transaction is outgoing
  bool get isOutgoing {
    return !isIncoming;
  }
}
