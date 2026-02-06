import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Transaction Type Enum
enum TransactionType {
  income,
  expense,
  transfer,
  mbway,  // Changed from pix to mbway (Portugal)
  payment,
}

/// Transaction Status
enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Transaction Model
class Transaction {
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.category,
    this.isEncrypted = true,
    this.senderId,
    this.receiverId,
    this.signature,
    this.status = TransactionStatus.completed,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? category;
  final bool isEncrypted;

  // PQC fields
  final String? senderId;
  final String? receiverId;
  final String? signature;  // Dilithium signature
  final TransactionStatus status;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense ||
                        type == TransactionType.transfer ||
                        type == TransactionType.mbway ||
                        type == TransactionType.payment;

  Color get amountColor {
    if (isIncome) return BJBankColors.success;
    return BJBankColors.error;
  }

  IconData get icon {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.mbway:
        return Icons.phone_android_rounded;  // MB WAY icon
      case TransactionType.payment:
        return Icons.receipt_long_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case TransactionType.income:
        return BJBankColors.success;
      case TransactionType.expense:
        return BJBankColors.error;
      case TransactionType.transfer:
        return BJBankColors.info;
      case TransactionType.mbway:
        return BJBankColors.primary;
      case TransactionType.payment:
        return BJBankColors.quantum;
    }
  }

  String get formattedAmount {
    final sign = type == TransactionType.income ? '+' : '-';
    return '$sign € ${_formatEuro(amount)}';  // Changed to Euro
  }

  String _formatEuro(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$integerPart,${parts[1]}';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }
}

/// Mock Transaction Data (Portugal/EUR)
class MockTransactions {
  MockTransactions._();

  static final List<Transaction> transactions = [
    Transaction(
      id: '1',
      description: 'Salário',
      amount: 2500.00,
      date: DateTime.now(),
      type: TransactionType.income,
      category: 'Rendimento',
    ),
    Transaction(
      id: '2',
      description: 'Netflix',
      amount: 15.99,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.expense,
      category: 'Streaming',
    ),
    Transaction(
      id: '3',
      description: 'Continente',
      amount: 87.50,
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.expense,
      category: 'Alimentação',
    ),
    Transaction(
      id: '4',
      description: 'MB WAY - João Silva',  // Changed from Pix
      amount: 50.00,
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.mbway,  // Changed from pix
      category: 'Transferência',
    ),
    Transaction(
      id: '5',
      description: 'Farmácia',
      amount: 23.90,
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: TransactionType.expense,
      category: 'Saúde',
    ),
    Transaction(
      id: '6',
      description: 'Freelance',
      amount: 450.00,
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: TransactionType.income,
      category: 'Rendimento Extra',
    ),
  ];
}
