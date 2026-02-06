/// Financial Summary Models for BJBank Analysis
class FinancialSummary {
  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netFlow,
    required this.periodStart,
    required this.periodEnd,
    this.monthlyBreakdown = const [],
  });

  final double totalIncome;
  final double totalExpenses;
  final double netFlow;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<MonthlySummary> monthlyBreakdown;

  String get formattedIncome => _formatEur(totalIncome);
  String get formattedExpenses => _formatEur(totalExpenses);
  String get formattedNetFlow => '${netFlow >= 0 ? '+' : ''}${_formatEur(netFlow)}';

  static String _formatEur(double value) {
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    final formatted = '$integerPart,${parts[1]}';
    return value < 0 ? '-\u20AC $formatted' : '\u20AC $formatted';
  }
}

/// Monthly breakdown for the chart and filter
class MonthlySummary {
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
  });

  final int year;
  final int month;
  final double income;
  final double expenses;

  double get netFlow => income - expenses;

  String get label {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return months[month - 1];
  }

  String get fullLabel {
    const months = [
      'Janeiro', 'Fevereiro', 'Mar\u00E7o', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return '${months[month - 1]} $year';
  }

  String get formattedIncome => FinancialSummary._formatEur(income);
  String get formattedExpenses => FinancialSummary._formatEur(expenses);
  String get formattedNetFlow => '${netFlow >= 0 ? '+' : ''}${FinancialSummary._formatEur(netFlow)}';
}
