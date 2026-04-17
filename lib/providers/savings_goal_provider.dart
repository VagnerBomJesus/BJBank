import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';

/// Savings Goal Provider for managing savings goals
class SavingsGoalProvider extends ChangeNotifier {
  final SavingsGoalService _savingsGoalService = SavingsGoalService();

  List<SavingsGoalModel> _savingsGoals = [];
  SavingsGoalModel? _selectedGoal;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _goalsSubscription;
  String? _currentUserId;

  // Statistics
  double _totalTarget = 0.0;
  double _totalSaved = 0.0;
  double _totalRemaining = 0.0;
  double _totalProgressPercentage = 0.0;
  int _activeGoals = 0;
  int _completedGoals = 0;
  int _overdueGoals = 0;

  // Getters
  List<SavingsGoalModel> get savingsGoals => _savingsGoals;
  SavingsGoalModel? get selectedGoal => _selectedGoal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasGoals => _savingsGoals.isNotEmpty;

  // Statistics getters
  double get totalTarget => _totalTarget;
  double get totalSaved => _totalSaved;
  double get totalRemaining => _totalRemaining;
  double get totalProgressPercentage => _totalProgressPercentage;
  int get activeGoals => _activeGoals;
  int get completedGoals => _completedGoals;
  int get overdueGoals => _overdueGoals;
  int get goalCount => _savingsGoals.length;

  /// Initialize provider
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToGoals(userId);
    _loadStatistics(userId);
  }

  /// Listen to real-time savings goals updates
  void _listenToGoals(String userId) {
    _goalsSubscription?.cancel();
    _goalsSubscription =
        _savingsGoalService.streamSavingsGoalsForUser(userId).listen(
      (goals) {
        _savingsGoals = goals;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming savings goals: $error');
        _errorMessage = 'Erro ao carregar metas de poupança';
        notifyListeners();
      },
    );
  }

  /// Load statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      final stats = await _savingsGoalService.getSavingsStatistics(userId);
      _totalTarget = stats['totalTarget'] ?? 0.0;
      _totalSaved = stats['totalSaved'] ?? 0.0;
      _totalRemaining = stats['totalRemaining'] ?? 0.0;
      _totalProgressPercentage = stats['totalProgressPercentage'] ?? 0.0;
      _activeGoals = stats['activeGoals'] ?? 0;
      _completedGoals = stats['completedGoals'] ?? 0;
      _overdueGoals = stats['overdueGoals'] ?? 0;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Create a new savings goal
  Future<bool> createSavingsGoal({
    required String name,
    required String description,
    required SavingsGoalCategory category,
    required double targetAmount,
    required SavingsGoalPriority priority,
    required DateTime targetDate,
    String currency = 'EUR',
    String icon = '💰',
    String color = '#6200EE',
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
      final goal = await _savingsGoalService.createSavingsGoal(
        userId: _currentUserId!,
        name: name,
        description: description,
        category: category,
        targetAmount: targetAmount,
        priority: priority,
        targetDate: targetDate,
        currency: currency,
        icon: icon,
        color: color,
      );

      _isLoading = false;

      if (goal != null) {
        _savingsGoals.add(goal);
        _selectedGoal = goal;
        await _loadStatistics(_currentUserId!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao criar meta de poupança';
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

  /// Select a savings goal
  void selectGoal(SavingsGoalModel goal) {
    _selectedGoal = goal;
    notifyListeners();
  }

  /// Add savings to a goal
  Future<bool> addSavings(String goalId, double amount) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _savingsGoalService.addSavings(
        _currentUserId!,
        goalId,
        amount,
      );

      _isLoading = false;

      if (success) {
        final index = _savingsGoals.indexWhere((goal) => goal.id == goalId);
        if (index != -1) {
          final goal = _savingsGoals[index];
          final newAmount = goal.currentAmount + amount;
          _savingsGoals[index] = goal.copyWith(currentAmount: newAmount);

          // Check if completed
          if (newAmount >= goal.targetAmount) {
            _savingsGoals[index] = _savingsGoals[index].copyWith(
              status: SavingsGoalStatus.completed,
              completedAt: DateTime.now(),
            );
          }

          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao adicionar poupança';
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

  /// Update goal status
  Future<bool> updateGoalStatus(
    String goalId,
    SavingsGoalStatus status,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _savingsGoalService.updateGoalStatus(
        _currentUserId!,
        goalId,
        status,
      );

      _isLoading = false;

      if (success) {
        final index = _savingsGoals.indexWhere((goal) => goal.id == goalId);
        if (index != -1) {
          _savingsGoals[index] = _savingsGoals[index].copyWith(status: status);
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar meta';
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

  /// Delete a savings goal
  Future<bool> deleteGoal(String goalId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _savingsGoalService.deleteSavingsGoal(
        _currentUserId!,
        goalId,
      );

      _isLoading = false;

      if (success) {
        final index = _savingsGoals.indexWhere((goal) => goal.id == goalId);
        if (index != -1) {
          _savingsGoals[index] = _savingsGoals[index].copyWith(
            status: SavingsGoalStatus.cancelled,
          );
          if (_selectedGoal?.id == goalId) {
            _selectedGoal = null;
          }
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao eliminar meta';
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

  /// Get active goals
  List<SavingsGoalModel> get activeGoalsList {
    return _savingsGoals.where((goal) => goal.status == SavingsGoalStatus.active).toList();
  }

  /// Get completed goals
  List<SavingsGoalModel> get completedGoalsList {
    return _savingsGoals.where((goal) => goal.status == SavingsGoalStatus.completed).toList();
  }

  /// Get goals by category
  List<SavingsGoalModel> getGoalsByCategory(SavingsGoalCategory category) {
    return _savingsGoals.where((goal) => goal.category == category).toList();
  }

  /// Get priority sorted goals
  List<SavingsGoalModel> get prioritySortedGoals {
    final sorted = [..._savingsGoals];
    sorted.sort((a, b) {
      const priorityOrder = {
        SavingsGoalPriority.critical: 0,
        SavingsGoalPriority.high: 1,
        SavingsGoalPriority.medium: 2,
        SavingsGoalPriority.low: 3,
      };
      return (priorityOrder[a.priority] ?? 4).compareTo(priorityOrder[b.priority] ?? 4);
    });
    return sorted;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh savings goals
  Future<void> refreshGoals() async {
    if (_currentUserId != null) {
      await _loadStatistics(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _goalsSubscription?.cancel();
    super.dispose();
  }
}
