import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/account_model.dart';
import '../models/financial_summary.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

/// Account Provider for BJBank
/// Manages account data and transactions across the app
class AccountProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  AccountModel? _primaryAccount;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  bool _isLoadingTransactions = false;
  String? _errorMessage;
  String? _currentUserId;
  StreamSubscription? _accountSubscription;
  StreamSubscription? _transactionsSubscription;

  AccountModel? get primaryAccount => _primaryAccount;
  List<Transaction> get transactions => _transactions;
  double get balance => _primaryAccount?.balance ?? 0.0;
  double get availableBalance => _primaryAccount?.availableBalance ?? 0.0;
  String get iban => _primaryAccount?.iban ?? '';
  String get accountNumber => _primaryAccount?.accountNumber ?? '';
  bool get isLoading => _isLoading;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get hasTransactions => _transactions.isNotEmpty;
  String? get errorMessage => _errorMessage;

  /// Load account data for a user
  Future<void> loadAccount(String userId) async {
    if (_currentUserId == userId && _primaryAccount != null) {
      // Already loaded for this user
      return;
    }

    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Stream account changes for real-time updates
      _accountSubscription?.cancel();
      _accountSubscription = _firestoreService
          .streamUserAccounts(userId)
          .listen(
        (accounts) {
          if (accounts.isNotEmpty) {
            _primaryAccount = accounts.firstWhere(
              (a) => a.type == AccountType.checking,
              orElse: () => accounts.first,
            );
          } else {
            _primaryAccount = null;
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error streaming accounts: $error');
          _errorMessage = 'Erro ao carregar conta';
          _isLoading = false;
          notifyListeners();
        },
      );

      // Stream transactions for real-time updates
      _transactionsSubscription?.cancel();
      _transactionsSubscription = _firestoreService
          .streamUserTransactions(userId)
          .listen(
        (transactions) {
          _transactions = transactions;
          _isLoadingTransactions = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error streaming transactions: $error');
          _isLoadingTransactions = false;
          notifyListeners();
        },
      );

      // Also load initial transactions
      _isLoadingTransactions = true;
      notifyListeners();
      await refreshTransactions(userId);
    } catch (e) {
      debugPrint('Error loading account: $e');
      _errorMessage = 'Erro ao carregar dados da conta';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh transactions from Firestore
  Future<void> refreshTransactions(String userId) async {
    try {
      _transactions = await _firestoreService.getUserTransactions(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }

  /// Refresh account data
  Future<void> refreshAccount() async {
    if (_currentUserId == null) return;
    try {
      final accounts = await _firestoreService.getUserAccounts(_currentUserId!);
      if (accounts.isNotEmpty) {
        _primaryAccount = accounts.firstWhere(
          (a) => a.type == AccountType.checking,
          orElse: () => accounts.first,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing account: $e');
    }
  }

  /// Get financial summary, optionally filtered by year/month
  FinancialSummary getFinancialSummary({int? year, int? month}) {
    final txns = _transactions;

    if (txns.isEmpty) {
      return FinancialSummary(
        totalIncome: 0,
        totalExpenses: 0,
        netFlow: 0,
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
        monthlyBreakdown: [],
      );
    }

    List<Transaction> filtered;
    if (year != null && month != null) {
      filtered = txns
          .where((t) => t.date.year == year && t.date.month == month)
          .toList();
    } else {
      filtered = txns;
    }

    double totalIncome = 0;
    double totalExpenses = 0;
    for (final t in filtered) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
      }
    }

    // Build monthly breakdown
    final monthMap = <String, MonthlySummary>{};
    for (final t in txns) {
      final key = '${t.date.year}-${t.date.month}';
      final existing = monthMap[key];
      final inc = (existing?.income ?? 0) + (t.isIncome ? t.amount : 0);
      final exp = (existing?.expenses ?? 0) + (t.isExpense ? t.amount : 0);
      monthMap[key] = MonthlySummary(
        year: t.date.year,
        month: t.date.month,
        income: inc,
        expenses: exp,
      );
    }
    final breakdown = monthMap.values.toList()
      ..sort((a, b) {
        final cmp = a.year.compareTo(b.year);
        return cmp != 0 ? cmp : a.month.compareTo(b.month);
      });

    final dates = txns.map((t) => t.date).toList()..sort();
    final periodStart = dates.isNotEmpty ? dates.first : DateTime.now();
    final periodEnd = DateTime.now();

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netFlow: totalIncome - totalExpenses,
      periodStart: periodStart,
      periodEnd: periodEnd,
      monthlyBreakdown: breakdown,
    );
  }

  /// Get list of available months that have transactions (for filter chips)
  List<MonthlySummary> getAvailableMonths() {
    final txns = _transactions;

    if (txns.isEmpty) return [];

    final seen = <String>{};
    final months = <MonthlySummary>[];
    for (final t in txns) {
      final key = '${t.date.year}-${t.date.month}';
      if (seen.add(key)) {
        months.add(MonthlySummary(
          year: t.date.year,
          month: t.date.month,
          income: 0,
          expenses: 0,
        ));
      }
    }
    months.sort((a, b) {
      final cmp = a.year.compareTo(b.year);
      return cmp != 0 ? cmp : a.month.compareTo(b.month);
    });
    return months;
  }

  /// Clear all data (on logout)
  void clear() {
    _accountSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _primaryAccount = null;
    _transactions = [];
    _isLoading = false;
    _isLoadingTransactions = false;
    _errorMessage = null;
    _currentUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
