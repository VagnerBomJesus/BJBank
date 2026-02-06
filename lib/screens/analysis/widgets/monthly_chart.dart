import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/financial_summary.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Custom bar chart showing monthly income vs expenses
class MonthlyChart extends StatelessWidget {
  const MonthlyChart({super.key, required this.months});

  final List<MonthlySummary> months;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(BJBankSpacing.xl),
          child: Center(
            child: Text(
              'Sem dados para mostrar',
              style: TextStyle(color: BJBankColors.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final maxValue = months.fold<double>(0, (prev, m) {
      return math.max(prev, math.max(m.income, m.expenses));
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo Mensal',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.md),

            // Chart
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < months.length; i++) ...[
                    if (i > 0) const SizedBox(width: BJBankSpacing.xs),
                    Expanded(
                      child: _MonthBar(
                        month: months[i],
                        maxValue: maxValue,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: BJBankSpacing.md),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: BJBankColors.success, label: 'Rendimentos'),
                const SizedBox(width: BJBankSpacing.lg),
                _LegendItem(color: BJBankColors.error, label: 'Gastos'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.month, required this.maxValue});

  final MonthlySummary month;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final incomeRatio = maxValue > 0 ? month.income / maxValue : 0.0;
    final expenseRatio = maxValue > 0 ? month.expenses / maxValue : 0.0;
    const maxBarHeight = 140.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                height: math.max(incomeRatio * maxBarHeight, 4),
                decoration: BoxDecoration(
                  color: BJBankColors.success,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Container(
                height: math.max(expenseRatio * maxBarHeight, 4),
                decoration: BoxDecoration(
                  color: BJBankColors.error,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BJBankSpacing.xxs),
        Text(
          month.label,
          style: TextStyle(
            fontSize: 11,
            color: BJBankColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: BJBankSpacing.xxs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: BJBankColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
