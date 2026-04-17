import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';

/// Loan Provider for managing loans portfolio
class LoanProvider extends ChangeNotifier {
  final LoanService _loanService = LoanService();

  List<LoanModel> _loans = [];
  LoanModel? _selectedLoan;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _loansSubscription;
  String? _currentUserId;

  // Statistics
  double _totalBorrowed = 0.0;
  double _totalPaid = 0.0;
  double _totalRemaining = 0.0;
  int _activeLoans = 0;
  int _completedLoans = 0;
  int _overdueLoans = 0;

  // Getters
  List<LoanModel> get loans => _loans;
  LoanModel? get selectedLoan => _selectedLoan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoans => _loans.isNotEmpty;

  // Statistics getters
  double get totalBorrowed => _totalBorrowed;
  double get totalPaid => _totalPaid;
  double get totalRemaining => _totalRemaining;
  int get activeLoans => _activeLoans;
  int get completedLoans => _completedLoans;
  int get overdueLoans => _overdueLoans;
  int get loanCount => _loans.length;

  /// Initialize provider
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToLoans(userId);
    _loadStatistics(userId);
  }

  /// Listen to real-time loan updates
  void _listenToLoans(String userId) {
    _loansSubscription?.cancel();
    _loansSubscription = _loanService.streamLoansForUser(userId).listen(
      (loans) {
        _loans = loans;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming loans: $error');
        _errorMessage = 'Erro ao carregar empréstimos';
        notifyListeners();
      },
    );
  }

  /// Load statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      final stats = await _loanService.getLoanStatistics(userId);
      _totalBorrowed = stats['totalBorrowed'] ?? 0.0;
      _totalPaid = stats['totalPaid'] ?? 0.0;
      _totalRemaining = stats['totalRemaining'] ?? 0.0;
      _activeLoans = stats['activeLoans'] ?? 0;
      _completedLoans = stats['completedLoans'] ?? 0;

      // Calculate overdue loans
      final overdueLoans = await _loanService.getOverdueLoans(userId);
      _overdueLoans = overdueLoans.length;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Create a new loan
  Future<bool> createLoan({
    required LoanType type,
    required double amount,
    required double interestRate,
    required int term,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
    double monthlyPayment = 0.0,
    String collateral = '',
    String notes = '',
    String currency = 'EUR',
  }) async {
    if (_currentUserId == null) {
      _errorMessage = 'Utilizador não autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loan = await _loanService.createLoan(
        userId: _currentUserId!,
        type: type,
        amount: amount,
        interestRate: interestRate,
        term: term,
        startDate: startDate,
        endDate: endDate,
        description: description,
        monthlyPayment: monthlyPayment,
        collateral: collateral,
        notes: notes,
        currency: currency,
      );

      _isLoading = false;

      if (loan != null) {
        _loans.add(loan);
        _selectedLoan = loan;
        await _loadStatistics(_currentUserId!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao criar empréstimo';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Select a loan
  void selectLoan(LoanModel loan) {
    _selectedLoan = loan;
    notifyListeners();
  }

  /// Update loan status
  Future<bool> updateLoanStatus(
    String loanId,
    LoanStatus status,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _loanService.updateLoanStatus(
        _currentUserId!,
        loanId,
        status,
      );

      _isLoading = false;

      if (success) {
        final index = _loans.indexWhere((loan) => loan.id == loanId);
        if (index != -1) {
          _loans[index] = _loans[index].copyWith(status: status);
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar estado do empréstimo';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Record a loan payment
  Future<bool> recordPayment(
    String loanId,
    double paymentAmount,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _loanService.recordPayment(
        _currentUserId!,
        loanId,
        paymentAmount,
      );

      _isLoading = false;

      if (success) {
        final index = _loans.indexWhere((loan) => loan.id == loanId);
        if (index != -1) {
          final loan = _loans[index];
          final newAmountPaid = loan.amountPaid + paymentAmount;
          _loans[index] = loan.copyWith(
            amountPaid: newAmountPaid,
            nextPaymentDate: DateTime.now().add(const Duration(days: 30)),
          );
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao registar pagamento';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Get active loans
  List<LoanModel> get activeLoansList {
    return _loans.where((loan) => loan.status == LoanStatus.active).toList();
  }

  /// Get overdue loans
  List<LoanModel> get overdueLoansList {
    return _loans.where((loan) => loan.isOverdue && loan.status == LoanStatus.active).toList();
  }

  /// Get upcoming payments (next 30 days)
  Future<List<LoanModel>> getUpcomingPayments() async {
    if (_currentUserId == null) return [];
    return await _loanService.getUpcomingPayments(_currentUserId!);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh loan portfolio
  Future<void> refreshPortfolio() async {
    if (_currentUserId != null) {
      await _loadStatistics(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _loansSubscription?.cancel();
    super.dispose();
  }
}
