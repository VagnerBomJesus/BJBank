import 'package:flutter/material.dart';
import '../../../models/financial_summary.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Summary Cards widget showing income, expenses, and net flow
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.summary});

  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Rendimentos',
                value: summary.formattedIncome,
                icon: Icons.arrow_downward_rounded,
                color: BJBankColors.success,
                backgroundColor: BJBankColors.successLight,
              ),
            ),
            const SizedBox(width: BJBankSpacing.sm),
            Expanded(
              child: _SummaryCard(
                title: 'Gastos',
                value: summary.formattedExpenses,
                icon: Icons.arrow_upward_rounded,
                color: BJBankColors.error,
                backgroundColor: BJBankColors.errorLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: BJBankSpacing.sm),
        _SummaryCard(
          title: 'Fluxo Líquido',
          value: summary.formattedNetFlow,
          icon: summary.netFlow >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: summary.netFlow >= 0 ? BJBankColors.success : BJBankColors.error,
          backgroundColor: summary.netFlow >= 0
              ? BJBankColors.successLight
              : BJBankColors.errorLight,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.fullWidth = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment:
              fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: fullWidth ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(BJBankSpacing.xs),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: BJBankSpacing.xs),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BJBankColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
