import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_strings.dart';
import '../../../models/transaction_model.dart';

/// Transaction Tile Widget
/// Modern card-style transaction item
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BJBankSpacing.md,
            vertical: BJBankSpacing.sm,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: transaction.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.icon,
                  size: 22,
                  color: transaction.iconColor,
                ),
              ),

              const SizedBox(width: BJBankSpacing.md),

              // Description and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: BJBankTypography.bodyMedium.copyWith(
                        color: BJBankColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          transaction.formattedDate,
                          style: BJBankTypography.bodySmall.copyWith(
                            color: BJBankColors.onSurfaceVariant,
                          ),
                        ),
                        if (transaction.isEncrypted) ...[
                          const SizedBox(width: BJBankSpacing.xs),
                          Icon(
                            Icons.shield_outlined,
                            size: 12,
                            color: BJBankColors.quantum,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                transaction.formattedAmount,
                style: BJBankTypography.titleSmall.copyWith(
                  color: transaction.amountColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transaction List Widget
/// Shows a list of recent transactions in a card
class TransactionList extends StatelessWidget {
  const TransactionList({
    super.key,
    required this.transactions,
    this.limit,
    this.onTransactionTap,
    this.onViewAllTap,
  });

  final List<Transaction> transactions;
  final int? limit;
  final Function(Transaction)? onTransactionTap;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final displayTransactions = limit != null
        ? transactions.take(limit!).toList()
        : transactions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.homeRecentTransactions,
                style: BJBankTypography.titleMedium.copyWith(
                  color: BJBankColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onViewAllTap != null && displayTransactions.isNotEmpty)
                TextButton(
                  onPressed: onViewAllTap,
                  style: TextButton.styleFrom(
                    foregroundColor: BJBankColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppStrings.homeViewAll,
                    style: BJBankTypography.labelMedium.copyWith(
                      color: BJBankColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: BJBankSpacing.md),

          // Transaction Items in a card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: BJBankColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: displayTransactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: BJBankColors.surfaceVariant
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 28,
                              color: BJBankColors.outline,
                            ),
                          ),
                          const SizedBox(height: BJBankSpacing.md),
                          Text(
                            AppStrings.homeNoTransactions,
                            style: BJBankTypography.bodyMedium.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        for (int i = 0; i < displayTransactions.length; i++) ...[
                          TransactionTile(
                            transaction: displayTransactions[i],
                            onTap: () =>
                                onTransactionTap?.call(displayTransactions[i]),
                          ),
                          if (i < displayTransactions.length - 1)
                            Divider(
                              height: 1,
                              indent: BJBankSpacing.md + 48 + BJBankSpacing.md,
                              endIndent: BJBankSpacing.md,
                              color: BJBankColors.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Encrypted Transaction Badge - kept for backwards compatibility
class EncryptedTransactionBadge extends StatelessWidget {
  const EncryptedTransactionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.shield_outlined,
      size: 12,
      color: BJBankColors.quantum,
    );
  }
}
