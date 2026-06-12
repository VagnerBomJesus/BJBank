import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/financial_summary.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../history/history_screen.dart';
import 'widgets/balance_line_chart.dart';

/// Statistics screen (UI-kit inspired): current balance, smooth monthly
/// spending line, month selector and the selected month's transactions.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, this.onBack});

  /// Called by the top back button. When shown as a tab, the parent passes a
  /// callback (e.g. go to Home); when pushed, it defaults to Navigator.pop.
  final VoidCallback? onBack;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _selectedIndex = -1; // index into monthly breakdown; -1 => last

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final summary = accountProvider.getFinancialSummary();
    final months = summary.monthlyBreakdown;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: BJBankSpacing.sm),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: BJBankColors.surfaceVariant.withValues(alpha: 0.5),
              foregroundColor: BJBankColors.onSurface,
            ),
            onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          ),
        ),
        title: const Text('Estatísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificações - Em breve'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: months.isEmpty
          ? _buildEmptyState(accountProvider.balance)
          : _buildContent(context, accountProvider, months),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AccountProvider accountProvider,
    List<MonthlySummary> months,
  ) {
    // Clamp selected index (default to most recent month)
    final selected =
        _selectedIndex < 0 || _selectedIndex >= months.length
            ? months.length - 1
            : _selectedIndex;
    final selectedMonth = months[selected];

    // Line = monthly spending (always positive, reads like the mockup curve)
    final values = months.map((m) => m.expenses).toList();

    final monthTxns = accountProvider.transactions
        .where((t) =>
            t.date.year == selectedMonth.year &&
            t.date.month == selectedMonth.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // Current balance hero
        Center(
          child: Column(
            children: [
              Text(
                'Saldo Atual',
                style: BJBankTypography.bodyMedium.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: BJBankSpacing.xxs),
              Text(
                '€ ${_formatAmount(accountProvider.balance)}',
                style: BJBankTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BJBankColors.onSurface,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: BJBankSpacing.lg),

        // Line chart
        BalanceLineChart(values: values, selectedIndex: selected),

        const SizedBox(height: BJBankSpacing.md),

        // Month selector pills
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: months.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: BJBankSpacing.xs),
            itemBuilder: (context, i) {
              final isSel = i == selected;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isSel
                        ? BJBankColors.primary
                        : BJBankColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    months[i].label,
                    style: BJBankTypography.labelLarge.copyWith(
                      color: isSel
                          ? BJBankColors.onPrimary
                          : BJBankColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: BJBankSpacing.lg),

        // Selected month income / spending summary
        Row(
          children: [
            Expanded(
              child: _miniStat(
                'Recebido',
                selectedMonth.formattedIncome,
                BJBankColors.success,
                Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: BJBankSpacing.sm),
            Expanded(
              child: _miniStat(
                'Gasto',
                selectedMonth.formattedExpenses,
                BJBankColors.error,
                Icons.north_east_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: BJBankSpacing.lg),

        // Transactions header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transações',
              style: BJBankTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: BJBankColors.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: Text(
                'Ver tudo',
                style: BJBankTypography.labelLarge.copyWith(
                  color: BJBankColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: BJBankSpacing.sm),

        if (monthTxns.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.xl),
            child: Center(
              child: Text(
                'Sem transações neste mês',
                style: BJBankTypography.bodyMedium.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          for (final t in monthTxns.take(8)) _buildTransactionRow(t),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: BJBankTypography.labelSmall.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BJBankTypography.valueSmall.copyWith(
                    color: BJBankColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: t.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(t.icon, size: 20, color: t.iconColor),
          ),
          const SizedBox(width: BJBankSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BJBankTypography.bodyMedium.copyWith(
                    color: BJBankColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.formattedDate,
                  style: BJBankTypography.bodySmall.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            t.formattedAmount,
            style: BJBankTypography.valueSmall.copyWith(
              color: t.amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double balance) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'Saldo Atual',
                style: BJBankTypography.bodyMedium.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: BJBankSpacing.xxs),
              Text(
                '€ ${_formatAmount(balance)}',
                style: BJBankTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BJBankColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BJBankSpacing.xxl),
        Icon(
          Icons.bar_chart_rounded,
          size: 64,
          color: BJBankColors.outline.withValues(alpha: 0.5),
        ),
        const SizedBox(height: BJBankSpacing.md),
        Center(
          child: Text(
            'Ainda não há dados para estatísticas',
            style: BJBankTypography.bodyMedium.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]}';
  }
}
