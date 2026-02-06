import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'widgets/summary_cards.dart';
import 'widgets/monthly_chart.dart';

/// Financial Analysis Screen with monthly filter
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int? _selectedYear;
  int? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final availableMonths = accountProvider.getAvailableMonths();
    final summary = accountProvider.getFinancialSummary(
      year: _selectedYear,
      month: _selectedMonth,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise Pessoal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          // Period indicator
          Text(
            _selectedMonth != null
                ? _getMonthLabel(_selectedYear!, _selectedMonth!)
                : 'Período: ${_formatDate(summary.periodStart)} - ${_formatDate(summary.periodEnd)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
          ),

          const SizedBox(height: BJBankSpacing.sm),

          // Month filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: BJBankSpacing.xs),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: _selectedMonth == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedYear = null;
                        _selectedMonth = null;
                      });
                    },
                  ),
                ),
                for (final m in availableMonths)
                  Padding(
                    padding: const EdgeInsets.only(right: BJBankSpacing.xs),
                    child: FilterChip(
                      label: Text(m.fullLabel),
                      selected:
                          _selectedYear == m.year && _selectedMonth == m.month,
                      onSelected: (_) {
                        setState(() {
                          _selectedYear = m.year;
                          _selectedMonth = m.month;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Summary cards
          SummaryCards(summary: summary),

          const SizedBox(height: BJBankSpacing.lg),

          // Monthly chart (only when showing all months)
          if (_selectedMonth == null && summary.monthlyBreakdown.isNotEmpty)
            MonthlyChart(months: summary.monthlyBreakdown),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getMonthLabel(int year, int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Mar\u00E7o', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return '${months[month - 1]} $year';
  }
}
