import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/savings_goal_model.dart';

/// Savings Goal Service for managing savings goals in Firestore
class SavingsGoalService {
  static final SavingsGoalService _instance = SavingsGoalService._internal();
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  SavingsGoalService._internal();

  factory SavingsGoalService() {
    return _instance;
  }

  /// Collection reference for savings goals
  CollectionReference<Map<String, dynamic>> _savingsGoalsCollection(String userId) {
    return _firebaseFirestore.collection('users').doc(userId).collection('savingsGoals');
  }

  /// Create a new savings goal
  Future<SavingsGoalModel?> createSavingsGoal({
    required String userId,
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
    try {
      final goal = SavingsGoalModel(
        id: '',
        userId: userId,
        name: name,
        description: description,
        category: category,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        priority: priority,
        targetDate: targetDate,
        status: SavingsGoalStatus.active,
        currency: currency,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
      );

      final docRef = await _savingsGoalsCollection(userId).add(goal.toFirestore());

      debugPrint('Savings goal created: ${docRef.id}');

      return goal.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating savings goal: $e');
      return null;
    }
  }

  /// Get all savings goals for a user
  Future<List<SavingsGoalModel>> getSavingsGoalsForUser(String userId) async {
    try {
      final snapshot = await _savingsGoalsCollection(userId)
          .orderBy('priority', descending: true)
          .orderBy('targetDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => SavingsGoalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching savings goals: $e');
      return [];
    }
  }

  /// Stream of savings goals for a user
  Stream<List<SavingsGoalModel>> streamSavingsGoalsForUser(String userId) {
    try {
      return _savingsGoalsCollection(userId)
          .orderBy('priority', descending: true)
          .orderBy('targetDate', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SavingsGoalModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming savings goals: $e');
      return Stream.value([]);
    }
  }

  /// Get a single savings goal
  Future<SavingsGoalModel?> getSavingsGoal(String userId, String goalId) async {
    try {
      final doc = await _savingsGoalsCollection(userId).doc(goalId).get();
      if (doc.exists) {
        return SavingsGoalModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching savings goal: $e');
      return null;
    }
  }

  /// Add savings to a goal
  Future<bool> addSavings(String userId, String goalId, double amount) async {
    try {
      final goal = await getSavingsGoal(userId, goalId);
      if (goal == null) return false;

      final newAmount = goal.currentAmount + amount;
      final isCompleted = newAmount >= goal.targetAmount;

      final updates = <String, dynamic>{
        'currentAmount': newAmount,
      };

      if (isCompleted) {
        updates['status'] = SavingsGoalStatus.completed.name;
        updates['completedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _savingsGoalsCollection(userId).doc(goalId).update(updates);
      debugPrint('Savings added: $amount');
      return true;
    } catch (e) {
      debugPrint('Error adding savings: $e');
      return false;
    }
  }

  /// Update goal status
  Future<bool> updateGoalStatus(
    String userId,
    String goalId,
    SavingsGoalStatus status,
  ) async {
    try {
      await _savingsGoalsCollection(userId).doc(goalId).update({
        'status': status.name,
      });
      debugPrint('Goal status updated: $status');
      return true;
    } catch (e) {
      debugPrint('Error updating goal status: $e');
      return false;
    }
  }

  /// Get active savings goals
  Future<List<SavingsGoalModel>> getActiveSavingsGoals(String userId) async {
    try {
      final snapshot = await _savingsGoalsCollection(userId)
          .where('status', isEqualTo: SavingsGoalStatus.active.name)
          .orderBy('targetDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => SavingsGoalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active savings goals: $e');
      return [];
    }
  }

  /// Get completed savings goals
  Future<List<SavingsGoalModel>> getCompletedSavingsGoals(String userId) async {
    try {
      final snapshot = await _savingsGoalsCollection(userId)
          .where('status', isEqualTo: SavingsGoalStatus.completed.name)
          .orderBy('completedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => SavingsGoalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching completed savings goals: $e');
      return [];
    }
  }

  /// Get savings goals by category
  Future<List<SavingsGoalModel>> getSavingsGoalsByCategory(
    String userId,
    SavingsGoalCategory category,
  ) async {
    try {
      final snapshot = await _savingsGoalsCollection(userId)
          .where('category', isEqualTo: category.name)
          .orderBy('targetDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => SavingsGoalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching savings goals by category: $e');
      return [];
    }
  }

  /// Get savings goals by priority
  Future<List<SavingsGoalModel>> getSavingsGoalsByPriority(
    String userId,
    SavingsGoalPriority priority,
  ) async {
    try {
      final snapshot = await _savingsGoalsCollection(userId)
          .where('priority', isEqualTo: priority.name)
          .orderBy('targetDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => SavingsGoalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching savings goals by priority: $e');
      return [];
    }
  }

  /// Get overdue savings goals (not completed)
  Future<List<SavingsGoalModel>> getOverdueSavingsGoals(String userId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _savingsGoalsCollection(userId)
          .where('status', isEqualTo: SavingsGoalStatus.active.name)
          .where('targetDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('targetDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => SavingsGoalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching overdue savings goals: $e');
      return [];
    }
  }

  /// Delete savings goal (mark as cancelled)
  Future<bool> deleteSavingsGoal(String userId, String goalId) async {
    try {
      await _savingsGoalsCollection(userId).doc(goalId).update({
        'status': SavingsGoalStatus.cancelled.name,
      });
      debugPrint('Savings goal marked as cancelled');
      return true;
    } catch (e) {
      debugPrint('Error deleting savings goal: $e');
      return false;
    }
  }

  /// Get savings statistics
  Future<Map<String, dynamic>> getSavingsStatistics(String userId) async {
    try {
      final goals = await getSavingsGoalsForUser(userId);

      double totalTarget = 0;
      double totalSaved = 0;
      double totalRemaining = 0;
      int activeGoals = 0;
      int completedGoals = 0;
      int overdueGoals = 0;

      for (final goal in goals) {
        if (goal.status == SavingsGoalStatus.active) {
          totalTarget += goal.targetAmount;
          totalSaved += goal.currentAmount;
          totalRemaining += goal.remainingAmount;
          activeGoals++;

          if (goal.isOverdue) {
            overdueGoals++;
          }
        } else if (goal.status == SavingsGoalStatus.completed) {
          totalSaved += goal.targetAmount;
          completedGoals++;
        }
      }

      final totalProgressPercentage = totalTarget > 0
          ? (totalSaved / totalTarget) * 100
          : 0.0;

      return {
        'totalTarget': totalTarget,
        'totalSaved': totalSaved,
        'totalRemaining': totalRemaining,
        'totalProgressPercentage': totalProgressPercentage,
        'activeGoals': activeGoals,
        'completedGoals': completedGoals,
        'overdueGoals': overdueGoals,
        'totalGoals': goals.length,
      };
    } catch (e) {
      debugPrint('Error fetching savings statistics: $e');
      return {};
    }
  }
}
