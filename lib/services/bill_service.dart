import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/bill_model.dart';

/// Bill Service for managing bills in Firestore
class BillService {
  static final BillService _instance = BillService._internal();
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  BillService._internal();

  factory BillService() {
    return _instance;
  }

  /// Collection reference for bills
  CollectionReference<Map<String, dynamic>> _billsCollection(String userId) {
    return _firebaseFirestore.collection('users').doc(userId).collection('bills');
  }

  /// Create a new bill
  Future<BillModel?> createBill({
    required String userId,
    required String creditorName,
    required double amount,
    required DateTime dueDate,
    required BillCategory category,
    String description = '',
    String reference = '',
    BillFrequency frequency = BillFrequency.once,
    DateTime? nextDueDate,
    String notes = '',
    bool autoPayEnabled = false,
  }) async {
    try {
      final bill = BillModel(
        id: '',
        userId: userId,
        creditorName: creditorName,
        amount: amount,
        dueDate: dueDate,
        category: category,
        status: BillStatus.pending,
        description: description,
        reference: reference,
        frequency: frequency,
        nextDueDate: nextDueDate,
        notes: notes,
        autoPayEnabled: autoPayEnabled,
        createdAt: DateTime.now(),
      );

      final docRef = await _billsCollection(userId).add(bill.toFirestore());

      debugPrint('Bill created: ${docRef.id}');

      return bill.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating bill: $e');
      return null;
    }
  }

  /// Get all bills for a user
  Future<List<BillModel>> getBillsForUser(String userId) async {
    try {
      final snapshot = await _billsCollection(userId)
          .orderBy('dueDate', descending: false)
          .get();
      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching bills: $e');
      return [];
    }
  }

  /// Stream of bills for a user (real-time updates)
  Stream<List<BillModel>> streamBillsForUser(String userId) {
    try {
      return _billsCollection(userId)
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error streaming bills: $e');
      return Stream.value([]);
    }
  }

  /// Get a single bill
  Future<BillModel?> getBill(String userId, String billId) async {
    try {
      final doc = await _billsCollection(userId).doc(billId).get();
      if (doc.exists) {
        return BillModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching bill: $e');
      return null;
    }
  }

  /// Update bill status
  Future<bool> updateBillStatus(
    String userId,
    String billId,
    BillStatus status,
  ) async {
    try {
      final updates = <String, dynamic>{'status': status.name};

      // If marking as paid, set lastPaidDate
      if (status == BillStatus.paid) {
        updates['lastPaidDate'] = Timestamp.fromDate(DateTime.now());
      }

      await _billsCollection(userId).doc(billId).update(updates);
      debugPrint('Bill status updated: $status');
      return true;
    } catch (e) {
      debugPrint('Error updating bill status: $e');
      return false;
    }
  }

  /// Update bill amount and due date
  Future<bool> updateBillDetails(
    String userId,
    String billId,
    double? amount,
    DateTime? dueDate,
  ) async {
    try {
      final updates = <String, dynamic>{};
      if (amount != null) updates['amount'] = amount;
      if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);

      if (updates.isNotEmpty) {
        await _billsCollection(userId).doc(billId).update(updates);
        debugPrint('Bill details updated');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating bill details: $e');
      return false;
    }
  }

  /// Toggle auto-pay for a bill
  Future<bool> toggleAutoPay(
    String userId,
    String billId,
    bool enabled,
  ) async {
    try {
      await _billsCollection(userId).doc(billId).update({
        'autoPayEnabled': enabled,
      });
      debugPrint('Auto-pay toggled: $enabled');
      return true;
    } catch (e) {
      debugPrint('Error toggling auto-pay: $e');
      return false;
    }
  }

  /// Delete bill (mark as cancelled)
  Future<bool> deleteBill(String userId, String billId) async {
    try {
      await _billsCollection(userId).doc(billId).update({
        'status': BillStatus.cancelled.name,
      });
      debugPrint('Bill marked as cancelled');
      return true;
    } catch (e) {
      debugPrint('Error deleting bill: $e');
      return false;
    }
  }

  /// Get bills by status
  Future<List<BillModel>> getBillsByStatus(
    String userId,
    BillStatus status,
  ) async {
    try {
      final snapshot = await _billsCollection(userId)
          .where('status', isEqualTo: status.name)
          .orderBy('dueDate', descending: false)
          .get();
      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching bills by status: $e');
      return [];
    }
  }

  /// Get bills by category
  Future<List<BillModel>> getBillsByCategory(
    String userId,
    BillCategory category,
  ) async {
    try {
      final snapshot = await _billsCollection(userId)
          .where('category', isEqualTo: category.name)
          .orderBy('dueDate', descending: false)
          .get();
      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching bills by category: $e');
      return [];
    }
  }

  /// Get upcoming bills (due in next 30 days)
  Future<List<BillModel>> getUpcomingBills(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));

      final snapshot = await _billsCollection(userId)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysLater))
          .where('status', isNotEqualTo: BillStatus.paid.name)
          .orderBy('status')
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching upcoming bills: $e');
      return [];
    }
  }

  /// Get overdue bills
  Future<List<BillModel>> getOverdueBills(String userId) async {
    try {
      final now = DateTime.now();

      final snapshot = await _billsCollection(userId)
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .where('status', isNotEqualTo: BillStatus.paid.name)
          .orderBy('status')
          .orderBy('dueDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching overdue bills: $e');
      return [];
    }
  }

  /// Calculate total amount due (pending + overdue)
  Future<double> getTotalAmountDue(String userId) async {
    try {
      final bills = await getBillsByStatus(userId, BillStatus.pending);
      return bills.fold<double>(0.0, (total, bill) => total + bill.amount);
    } catch (e) {
      debugPrint('Error calculating total amount due: $e');
      return 0.0;
    }
  }

  /// Get bill statistics for dashboard
  Future<Map<String, dynamic>> getBillStatistics(String userId) async {
    try {
      final pendingBills = await getBillsByStatus(userId, BillStatus.pending);
      final paidBills = await getBillsByStatus(userId, BillStatus.paid);
      const overdueBills = [];

      final totalPending =
          pendingBills.fold<double>(0.0, (total, bill) => total + bill.amount);
      final totalPaid = paidBills.fold<double>(0.0, (total, bill) => total + bill.amount);

      return {
        'pendingCount': pendingBills.length,
        'paidCount': paidBills.length,
        'overdueCount': overdueBills.length,
        'totalPending': totalPending,
        'totalPaid': totalPaid,
      };
    } catch (e) {
      debugPrint('Error fetching bill statistics: $e');
      return {};
    }
  }
}
