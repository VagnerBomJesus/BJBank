import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';

/// Budget Provider for managing budgets
class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

  List<BudgetModel> _budgets = [];
  BudgetModel? _selectedBudget;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _budgetsSubscription;
  String? _currentUserId;

  // Statistics
  double _totalBudget = 0.0;
  double _totalSpent = 0.0;
  double _totalRemaining = 0.0;
  double _totalSpentPercentage = 0.0;
  int _activeBudgets = 0;
  int _exceededBudgets = 0;

  // Getters
  List<BudgetModel> get budgets => _budgets;
  BudgetModel? get selectedBudget => _selectedBudget;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBudgets => _budgets.isNotEmpty;

  // Statistics getters
  double get totalBudget => _totalBudget;
  double get totalSpent => _totalSpent;
  double get totalRemaining => _totalRemaining;
  double get totalSpentPercentage => _totalSpentPercentage;
  int get activeBudgets => _activeBudgets;
  int get exceededBudgets => _exceededBudgets;
  int get budgetCount => _budgets.length;

  /// Initialize provider
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToBudgets(userId);
    _loadStatistics(userId);
  }

  /// Listen to real-time budgets updates
  void _listenToBudgets(String userId) {
    _budgetsSubscription?.cancel();
    _budgetsSubscription = _budgetService.streamBudgetsForUser(userId).listen(
      (budgets) {
        _budgets = budgets;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming budgets: $error');
        _errorMessage = 'Erro ao carregar orçamentos';
        notifyListeners();
      },
    );
  }

  /// Load statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      final stats = await _budgetService.getBudgetStatistics(userId);
      _totalBudget = stats['totalBudget'] ?? 0.0;
      _totalSpent = stats['totalSpent'] ?? 0.0;
      _totalRemaining = stats['totalRemaining'] ?? 0.0;
      _totalSpentPercentage = stats['totalSpentPercentage'] ?? 0.0;
      _activeBudgets = stats['activeBudgets'] ?? 0;
      _exceededBudgets = stats['exceededBudgets'] ?? 0;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Create a new budget
  Future<bool> createBudget({
    required String name,
    required String category,
    required double limitAmount,
    required BudgetPeriod period,
    required DateTime startDate,
    required DateTime endDate,
    String currency = 'EUR',
    double alertThreshold = 80.0,
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
      final budget = await _budgetService.createBudget(
        userId: _currentUserId!,
        name: name,
        category: category,
        limitAmount: limitAmount,
        period: period,
        startDate: startDate,
        endDate: endDate,
        currency: currency,
        alertThreshold: alertThreshold,
      );

      _isLoading = false;

      if (budget != null) {
        _budgets.add(budget);
        _selectedBudget = budget;
        await _loadStatistics(_currentUserId!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao criar orçamento';
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

  /// Select a budget
  void selectBudget(BudgetModel budget) {
    _selectedBudget = budget;
    notifyListeners();
  }

  /// Add spending to a budget
  Future<bool> addSpending(String budgetId, double amount) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _budgetService.addSpending(
        _currentUserId!,
        budgetId,
        amount,
      );

      _isLoading = false;

      if (success) {
        final index = _budgets.indexWhere((budget) => budget.id == budgetId);
        if (index != -1) {
          final budget = _budgets[index];
          final newSpentAmount = budget.spentAmount + amount;
          final status = newSpentAmount > budget.limitAmount
              ? BudgetStatus.exceeded
              : BudgetStatus.active;

          _budgets[index] = budget.copyWith(
            spentAmount: newSpentAmount,
            status: status,
          );
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao adicionar despesa';
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

  /// Update budget status
  Future<bool> updateBudgetStatus(
    String budgetId,
    BudgetStatus status,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _budgetService.updateBudgetStatus(
        _currentUserId!,
        budgetId,
        status,
      );

      _isLoading = false;

      if (success) {
        final index = _budgets.indexWhere((budget) => budget.id == budgetId);
        if (index != -1) {
          _budgets[index] = _budgets[index].copyWith(status: status);
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar orçamento';
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

  /// Update budget limit
  Future<bool> updateBudgetLimit(String budgetId, double newLimit) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _budgetService.updateBudgetLimit(
        _currentUserId!,
        budgetId,
        newLimit,
      );

      _isLoading = false;

      if (success) {
        final index = _budgets.indexWhere((budget) => budget.id == budgetId);
        if (index != -1) {
          _budgets[index] = _budgets[index].copyWith(limitAmount: newLimit);
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar limite';
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

  /// Delete a budget
  Future<bool> deleteBudget(String budgetId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _budgetService.deleteBudget(
        _currentUserId!,
        budgetId,
      );

      _isLoading = false;

      if (success) {
        final index = _budgets.indexWhere((budget) => budget.id == budgetId);
        if (index != -1) {
          _budgets[index] = _budgets[index].copyWith(
            status: BudgetStatus.cancelled,
          );
          if (_selectedBudget?.id == budgetId) {
            _selectedBudget = null;
          }
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao eliminar orçamento';
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

  /// Get active budgets
  List<BudgetModel> get activeBudgetsList {
    return _budgets.where((budget) => budget.status == BudgetStatus.active).toList();
  }

  /// Get exceeded budgets
  List<BudgetModel> get exceededBudgetsList {
    return _budgets.where((budget) => budget.status == BudgetStatus.exceeded).toList();
  }

  /// Get budgets with alert threshold reached
  List<BudgetModel> get alertBudgetsList {
    return _budgets.where((budget) => budget.isAlertThresholdReached).toList();
  }

  /// Get budgets by period
  List<BudgetModel> getBudgetsByPeriod(BudgetPeriod period) {
    return _budgets.where((budget) => budget.period == period).toList();
  }

  /// Get budgets by category
  List<BudgetModel> getBudgetsByCategory(String category) {
    return _budgets.where((budget) => budget.category == category).toList();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh budgets
  Future<void> refreshBudgets() async {
    if (_currentUserId != null) {
      await _loadStatistics(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _budgetsSubscription?.cancel();
    super.dispose();
  }
}
