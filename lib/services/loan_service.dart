import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/loan_model.dart';

/// Loan Service for managing loans in Firestore
class LoanService {
  static final LoanService _instance = LoanService._internal();
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  LoanService._internal();

  factory LoanService() {
    return _instance;
  }

  /// Collection reference for loans
  CollectionReference<Map<String, dynamic>> _loansCollection(String userId) {
    return _firebaseFirestore.collection('users').doc(userId).collection('loans');
  }

  /// Create a new loan
  Future<LoanModel?> createLoan({
    required String userId,
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
    try {
      final loan = LoanModel(
        id: '',
        userId: userId,
        type: type,
        amount: amount,
        interestRate: interestRate,
        term: term,
        startDate: startDate,
        endDate: endDate,
        status: LoanStatus.pending,
        description: description,
        monthlyPayment: monthlyPayment,
        collateral: collateral,
        notes: notes,
        currency: currency,
        createdAt: DateTime.now(),
      );

      final docRef = await _loansCollection(userId).add(loan.toFirestore());

      debugPrint('Loan created: ${docRef.id}');

      return loan.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating loan: $e');
      return null;
    }
  }

  /// Get all loans for a user
  Future<List<LoanModel>> getLoansForUser(String userId) async {
    try {
      final snapshot = await _loansCollection(userId)
          .orderBy('startDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => LoanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching loans: $e');
      return [];
    }
  }

  /// Stream of loans for a user
  Stream<List<LoanModel>> streamLoansForUser(String userId) {
    try {
      return _loansCollection(userId)
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => LoanModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming loans: $e');
      return Stream.value([]);
    }
  }

  /// Get a single loan
  Future<LoanModel?> getLoan(String userId, String loanId) async {
    try {
      final doc = await _loansCollection(userId).doc(loanId).get();
      if (doc.exists) {
        return LoanModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching loan: $e');
      return null;
    }
  }

  /// Update loan status
  Future<bool> updateLoanStatus(
    String userId,
    String loanId,
    LoanStatus status,
  ) async {
    try {
      await _loansCollection(userId).doc(loanId).update({
        'status': status.name,
      });
      debugPrint('Loan status updated: $status');
      return true;
    } catch (e) {
      debugPrint('Error updating loan status: $e');
      return false;
    }
  }

  /// Record loan payment
  Future<bool> recordPayment(
    String userId,
    String loanId,
    double paymentAmount,
  ) async {
    try {
      final loan = await getLoan(userId, loanId);
      if (loan == null) return false;

      final newAmountPaid = loan.amountPaid + paymentAmount;
      final nextPaymentDate = DateTime.now().add(const Duration(days: 30));

      // Check if loan is completed
      final isCompleted = newAmountPaid >= loan.amount;

      final updates = <String, dynamic>{
        'amountPaid': newAmountPaid,
        'nextPaymentDate': Timestamp.fromDate(nextPaymentDate),
      };

      if (isCompleted) {
        updates['status'] = LoanStatus.completed.name;
        updates['endDate'] = Timestamp.fromDate(DateTime.now());
      }

      await _loansCollection(userId).doc(loanId).update(updates);
      debugPrint('Payment recorded: $paymentAmount');
      return true;
    } catch (e) {
      debugPrint('Error recording payment: $e');
      return false;
    }
  }

  /// Get active loans
  Future<List<LoanModel>> getActiveLoans(String userId) async {
    try {
      final snapshot = await _loansCollection(userId)
          .where('status', isEqualTo: LoanStatus.active.name)
          .orderBy('nextPaymentDate', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => LoanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active loans: $e');
      return [];
    }
  }

  /// Get overdue loans
  Future<List<LoanModel>> getOverdueLoans(String userId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _loansCollection(userId)
          .where('status', isEqualTo: LoanStatus.active.name)
          .where('nextPaymentDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('nextPaymentDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => LoanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching overdue loans: $e');
      return [];
    }
  }

  /// Get loan by type
  Future<List<LoanModel>> getLoansByType(String userId, LoanType type) async {
    try {
      final snapshot = await _loansCollection(userId)
          .where('type', isEqualTo: type.name)
          .orderBy('startDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => LoanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching loans by type: $e');
      return [];
    }
  }

  /// Calculate loan statistics
  Future<Map<String, dynamic>> getLoanStatistics(String userId) async {
    try {
      final loans = await getLoansForUser(userId);

      double totalBorrowed = 0;
      double totalPaid = 0;
      double totalRemaining = 0;
      int activeLoans = 0;
      int completedLoans = 0;

      for (final loan in loans) {
        totalBorrowed += loan.amount;
        totalPaid += loan.amountPaid;
        totalRemaining += loan.remainingAmount;

        if (loan.status == LoanStatus.active) {
          activeLoans++;
        } else if (loan.status == LoanStatus.completed) {
          completedLoans++;
        }
      }

      return {
        'totalBorrowed': totalBorrowed,
        'totalPaid': totalPaid,
        'totalRemaining': totalRemaining,
        'activeLoans': activeLoans,
        'completedLoans': completedLoans,
        'totalLoans': loans.length,
      };
    } catch (e) {
      debugPrint('Error fetching loan statistics: $e');
      return {};
    }
  }

  /// Get upcoming loan payments (next 30 days)
  Future<List<LoanModel>> getUpcomingPayments(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));

      final snapshot = await _loansCollection(userId)
          .where('status', isEqualTo: LoanStatus.active.name)
          .where('nextPaymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('nextPaymentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysLater))
          .orderBy('nextPaymentDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => LoanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching upcoming payments: $e');
      return [];
    }
  }
}
