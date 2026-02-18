import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Documents & Statements Screen
///
/// Shows transaction history grouped by month with PQC signature status
/// and export capability.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;

  List<int> get _availableYears {
    final now = DateTime.now();
    return [now.year, now.year - 1, now.year - 2];
  }

  List<String> get _months => [
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
      ];

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final authProvider = context.watch<AuthProvider>();
    final transactions = accountProvider.transactions;

    final filtered = _filterTransactions(transactions);
    final grouped = _groupByMonth(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos e Extratos'),
        actions: [
          if (filtered.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Exportar extrato',
              onPressed: () => _exportStatement(filtered, authProvider.user?.name ?? ''),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),

          // Content
          Expanded(
            child: accountProvider.isLoadingTransactions
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(grouped),
          ),
        ],
      ),
    );
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  Widget _buildFilters() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.md,
        vertical: BJBankSpacing.sm,
      ),
      child: Row(
        children: [
          // Year selector
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Ano',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: BJBankSpacing.sm,
                  vertical: BJBankSpacing.xs,
                ),
              ),
              items: _availableYears
                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (y) => setState(() {
                _selectedYear = y!;
                _selectedMonth = null;
              }),
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          // Month selector
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int?>(
              value: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Mês',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: BJBankSpacing.sm,
                  vertical: BJBankSpacing.xs,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos os meses'),
                ),
                ..._months.asMap().entries.map(
                      (e) => DropdownMenuItem<int?>(
                        value: e.key + 1,
                        child: Text(e.value),
                      ),
                    ),
              ],
              onChanged: (m) => setState(() => _selectedMonth = m),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction list ────────────────────────────────────────────────────────

  Widget _buildTransactionList(Map<String, List<Transaction>> grouped) {
    final keys = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final monthKey = keys[i];
        final txs = grouped[monthKey]!;
        final monthTotal = txs.fold<double>(
          0,
          (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
        );
        return _buildMonthSection(monthKey, txs, monthTotal);
      },
    );
  }

  Widget _buildMonthSection(
    String monthLabel,
    List<Transaction> transactions,
    double monthTotal,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.only(
            top: BJBankSpacing.md,
            bottom: BJBankSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: BJBankColors.onSurface,
                    ),
              ),
              Text(
                _formatAmount(monthTotal),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: monthTotal >= 0
                          ? BJBankColors.success
                          : BJBankColors.error,
                    ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < transactions.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _buildTransactionTile(transactions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: tx.iconColor.withValues(alpha: 0.15),
        child: Icon(tx.icon, color: tx.iconColor, size: 20),
      ),
      title: Text(
        tx.description,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Row(
        children: [
          Text(
            _formatFullDate(tx.date),
            style: const TextStyle(fontSize: 12),
          ),
          if (tx.signature != null) ...[
            const SizedBox(width: BJBankSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: BJBankColors.quantum.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'PQC',
                style: TextStyle(
                  fontSize: 9,
                  color: BJBankColors.quantum,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        tx.formattedAmount,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: tx.amountColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: BJBankSpacing.iconXxl,
              color: BJBankColors.onSurfaceVariant,
            ),
            const SizedBox(height: BJBankSpacing.lg),
            Text(
              'Sem movimentos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.sm),
            Text(
              'Não existem transações para o período selecionado.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> _exportStatement(List<Transaction> txs, String userName) async {
    final buf = StringBuffer();
    final period = _selectedMonth != null
        ? '${_months[_selectedMonth! - 1]} $_selectedYear'
        : 'Ano $_selectedYear';

    buf.writeln('EXTRATO BANCÁRIO — BJBank');
    buf.writeln('Período: $period');
    buf.writeln('Titular: $userName');
    buf.writeln('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    buf.writeln('Segurança: Assinaturas CRYSTALS-Dilithium (NIST FIPS 204)');
    buf.writeln('═' * 50);
    buf.writeln();

    final grouped = _groupByMonth(txs);
    for (final entry in grouped.entries) {
      buf.writeln('── ${entry.key} ──');
      double monthTotal = 0;
      for (final tx in entry.value) {
        final sign = tx.isIncome ? '+' : '-';
        final pqc = tx.signature != null ? ' [PQC✓]' : '';
        buf.writeln(
          '${_formatFullDate(tx.date).padRight(12)} '
          '${tx.description.padRight(25)} '
          '$sign€ ${tx.amount.toStringAsFixed(2).padLeft(10)}$pqc',
        );
        monthTotal += tx.isIncome ? tx.amount : -tx.amount;
      }
      buf.writeln('Total do mês: ${_formatAmount(monthTotal)}');
      buf.writeln();
    }

    final total = txs.fold<double>(
      0,
      (s, t) => s + (t.isIncome ? t.amount : -t.amount),
    );
    buf.writeln('═' * 50);
    buf.writeln('SALDO DO PERÍODO: ${_formatAmount(total)}');

    await Share.share(
      buf.toString(),
      subject: 'Extrato BJBank — $period',
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<Transaction> _filterTransactions(List<Transaction> all) {
    return all.where((tx) {
      if (tx.date.year != _selectedYear) return false;
      if (_selectedMonth != null && tx.date.month != _selectedMonth) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, List<Transaction>> _groupByMonth(List<Transaction> txs) {
    final result = <String, List<Transaction>>{};
    for (final tx in txs) {
      final key = '${_months[tx.date.month - 1]} ${tx.date.year}';
      result.putIfAbsent(key, () => []).add(tx);
    }
    return result;
  }

  String _formatFullDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatAmount(double v) {
    final sign = v >= 0 ? '+' : '';
    return '$sign€ ${v.abs().toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
