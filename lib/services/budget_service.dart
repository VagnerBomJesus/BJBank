import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';

/// Budget Service for managing budgets in Firestore
class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  BudgetService._internal();

  factory BudgetService() {
    return _instance;
  }

  /// Collection reference for budgets
  CollectionReference<Map<String, dynamic>> _budgetsCollection(String userId) {
    return _firebaseFirestore.collection('users').doc(userId).collection('budgets');
  }

  /// Create a new budget
  Future<BudgetModel?> createBudget({
    required String userId,
    required String name,
    required String category,
    required double limitAmount,
    required BudgetPeriod period,
    required DateTime startDate,
    required DateTime endDate,
    String currency = 'EUR',
    double alertThreshold = 80.0,
  }) async {
    try {
      final budget = BudgetModel(
        id: '',
        userId: userId,
        name: name,
        category: category,
        limitAmount: limitAmount,
        spentAmount: 0.0,
        period: period,
        startDate: startDate,
        endDate: endDate,
        status: BudgetStatus.active,
        currency: currency,
        alertThreshold: alertThreshold,
        createdAt: DateTime.now(),
      );

      final docRef = await _budgetsCollection(userId).add(budget.toFirestore());

      debugPrint('Budget created: ${docRef.id}');

      return budget.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating budget: $e');
      return null;
    }
  }

  /// Get all budgets for a user
  Future<List<BudgetModel>> getBudgetsForUser(String userId) async {
    try {
      final snapshot = await _budgetsCollection(userId)
          .where('status', isNotEqualTo: BudgetStatus.cancelled.name)
          .orderBy('status')
          .orderBy('endDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
      return [];
    }
  }

  /// Stream of budgets for a user
  Stream<List<BudgetModel>> streamBudgetsForUser(String userId) {
    try {
      return _budgetsCollection(userId)
          .where('status', isNotEqualTo: BudgetStatus.cancelled.name)
          .orderBy('status')
          .orderBy('endDate', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => BudgetModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming budgets: $e');
      return Stream.value([]);
    }
  }

  /// Get a single budget
  Future<BudgetModel?> getBudget(String userId, String budgetId) async {
    try {
      final doc = await _budgetsCollection(userId).doc(budgetId).get();
      if (doc.exists) {
        return BudgetModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching budget: $e');
      return null;
    }
  }

  /// Add spending to a budget
  Future<bool> addSpending(String userId, String budgetId, double amount) async {
    try {
      final budget = await getBudget(userId, budgetId);
      if (budget == null) return false;

      final newSpentAmount = budget.spentAmount + amount;
      final status = newSpentAmount > budget.limitAmount
          ? BudgetStatus.exceeded
          : BudgetStatus.active;

      await _budgetsCollection(userId).doc(budgetId).update({
        'spentAmount': newSpentAmount,
        'status': status.name,
      });
      debugPrint('Spending added: $amount');
      return true;
    } catch (e) {
      debugPrint('Error adding spending: $e');
      return false;
    }
  }

  /// Update budget status
  Future<bool> updateBudgetStatus(
    String userId,
    String budgetId,
    BudgetStatus status,
  ) async {
    try {
      await _budgetsCollection(userId).doc(budgetId).update({
        'status': status.name,
      });
      debugPrint('Budget status updated: $status');
      return true;
    } catch (e) {
      debugPrint('Error updating budget status: $e');
      return false;
    }
  }

  /// Update budget limit
  Future<bool> updateBudgetLimit(
    String userId,
    String budgetId,
    double newLimit,
  ) async {
    try {
      await _budgetsCollection(userId).doc(budgetId).update({
        'limitAmount': newLimit,
      });
      debugPrint('Budget limit updated');
      return true;
    } catch (e) {
      debugPrint('Error updating budget limit: $e');
      return false;
    }
  }

  /// Get active budgets
  Future<List<BudgetModel>> getActiveBudgets(String userId) async {
    try {
      final snapshot = await _budgetsCollection(userId)
          .where('status', isEqualTo: BudgetStatus.active.name)
          .orderBy('endDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active budgets: $e');
      return [];
    }
  }

  /// Get exceeded budgets
  Future<List<BudgetModel>> getExceededBudgets(String userId) async {
    try {
      final snapshot = await _budgetsCollection(userId)
          .where('status', isEqualTo: BudgetStatus.exceeded.name)
          .orderBy('endDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching exceeded budgets: $e');
      return [];
    }
  }

  /// Get budgets by period
  Future<List<BudgetModel>> getBudgetsByPeriod(
    String userId,
    BudgetPeriod period,
  ) async {
    try {
      final snapshot = await _budgetsCollection(userId)
          .where('period', isEqualTo: period.name)
          .orderBy('endDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching budgets by period: $e');
      return [];
    }
  }

  /// Get budgets by category
  Future<List<BudgetModel>> getBudgetsByCategory(
    String userId,
    String category,
  ) async {
    try {
      final snapshot = await _budgetsCollection(userId)
          .where('category', isEqualTo: category)
          .orderBy('endDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching budgets by category: $e');
      return [];
    }
  }

  /// Delete budget (mark as cancelled)
  Future<bool> deleteBudget(String userId, String budgetId) async {
    try {
      await _budgetsCollection(userId).doc(budgetId).update({
        'status': BudgetStatus.cancelled.name,
      });
      debugPrint('Budget marked as cancelled');
      return true;
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      return false;
    }
  }

  /// Get budget statistics
  Future<Map<String, dynamic>> getBudgetStatistics(String userId) async {
    try {
      final budgets = await getBudgetsForUser(userId);

      double totalBudget = 0;
      double totalSpent = 0;
      double totalRemaining = 0;
      int activeBudgets = 0;
      int exceededBudgets = 0;

      for (final budget in budgets) {
        if (budget.status == BudgetStatus.active ||
            budget.status == BudgetStatus.exceeded) {
          totalBudget += budget.limitAmount;
          totalSpent += budget.spentAmount;
          totalRemaining += budget.remainingBudget;

          if (budget.status == BudgetStatus.active) {
            activeBudgets++;
          } else if (budget.status == BudgetStatus.exceeded) {
            exceededBudgets++;
          }
        }
      }

      final totalSpentPercentage = totalBudget > 0
          ? (totalSpent / totalBudget) * 100
          : 0.0;

      return {
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'totalRemaining': totalRemaining,
        'totalSpentPercentage': totalSpentPercentage,
        'activeBudgets': activeBudgets,
        'exceededBudgets': exceededBudgets,
        'totalBudgets': budgets.length,
      };
    } catch (e) {
      debugPrint('Error fetching budget statistics: $e');
      return {};
    }
  }
}
