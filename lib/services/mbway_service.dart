import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/mbway_contact_model.dart';
import '../models/transaction_model.dart' as tx;

/// MB WAY Service for managing MB WAY transactions (Portuguese instant payments)
class MbWayService {
  static final MbWayService _instance = MbWayService._internal();
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  MbWayService._internal();

  factory MbWayService() {
    return _instance;
  }

  /// Collection reference for MB WAY transactions
  CollectionReference<Map<String, dynamic>> _mbwayCollection(String userId) {
    return _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('mbway_transactions');
  }

  /// Collection reference for MB WAY contacts
  CollectionReference<Map<String, dynamic>> _contactsCollection(String userId) {
    return _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('mbway_contacts');
  }

  /// Initiate MB WAY payment
  Future<bool> initiateMbWayPayment({
    required String senderId,
    required String senderName,
    required String recipientPhone,
    required String recipientName,
    required double amount,
    required String description,
    String? reference,
  }) async {
    try {
      final transactionId = _firebaseFirestore.collection('_').doc().id;
      final timestamp = DateTime.now();

      // Create transaction record
      await _mbwayCollection(senderId).add({
        'id': transactionId,
        'description': description,
        'amount': amount,
        'recipientPhone': recipientPhone,
        'recipientName': recipientName,
        'reference': reference,
        'date': Timestamp.fromDate(timestamp),
        'status': tx.TransactionStatus.processing.name,
        'senderId': senderId,
        'senderName': senderName,
        'createdAt': Timestamp.fromDate(timestamp),
      });

      // Add to contacts if not already there
      await _updateOrCreateContact(
        senderId,
        recipientName,
        recipientPhone,
      );

      debugPrint('MB WAY payment initiated: $transactionId');
      return true;
    } catch (e) {
      debugPrint('Error initiating MB WAY payment: $e');
      return false;
    }
  }

  /// Update or create contact
  Future<void> _updateOrCreateContact(
    String userId,
    String name,
    String phone,
  ) async {
    try {
      // Check if contact already exists
      final snapshot = await _contactsCollection(userId)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Update existing contact
        await snapshot.docs.first.reference.update({
          'lastUsed': Timestamp.fromDate(DateTime.now()),
          'useCount': FieldValue.increment(1),
        });
      } else {
        // Create new contact
        await _contactsCollection(userId).add({
          'name': name,
          'phone': phone,
          'lastUsed': Timestamp.fromDate(DateTime.now()),
          'useCount': 1,
        });
      }
    } catch (e) {
      debugPrint('Error updating contact: $e');
    }
  }

  /// Get MB WAY contacts
  Future<List<MbWayContact>> getContacts(String userId) async {
    try {
      final snapshot = await _contactsCollection(userId)
          .orderBy('lastUsed', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => MbWayContact.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      return [];
    }
  }

  /// Stream of MB WAY contacts
  Stream<List<MbWayContact>> streamContacts(String userId) {
    try {
      return _contactsCollection(userId)
          .orderBy('lastUsed', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MbWayContact.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming contacts: $e');
      return Stream.value([]);
    }
  }

  /// Get frequently used contacts (top 5)
  Future<List<MbWayContact>> getFrequentContacts(String userId) async {
    try {
      final snapshot = await _contactsCollection(userId)
          .orderBy('useCount', descending: true)
          .limit(5)
          .get();
      return snapshot.docs
          .map((doc) => MbWayContact.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching frequent contacts: $e');
      return [];
    }
  }

  /// Delete contact
  Future<bool> deleteContact(String userId, String contactId) async {
    try {
      await _contactsCollection(userId).doc(contactId).delete();
      debugPrint('Contact deleted: $contactId');
      return true;
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      return false;
    }
  }

  /// Get MB WAY transaction history
  Future<List<Map<String, dynamic>>> getMbWayHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _mbwayCollection(userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching MB WAY history: $e');
      return [];
    }
  }

  /// Stream MB WAY transaction history
  Stream<List<Map<String, dynamic>>> streamMbWayHistory(
    String userId, {
    int limit = 20,
  }) {
    try {
      return _mbwayCollection(userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      debugPrint('Error streaming MB WAY history: $e');
      return Stream.value([]);
    }
  }

  /// Validate Portuguese phone number
  static bool isValidPhoneNumber(String phone) {
    // Remove non-digit characters except +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Portuguese numbers should start with +351 or be 9 digits
    if (cleaned.startsWith('+351')) {
      return cleaned.length == 13; // +351 + 9 digits
    } else if (cleaned.startsWith('00351')) {
      return cleaned.length == 14; // 00351 + 9 digits
    } else if (cleaned.startsWith('351')) {
      return cleaned.length == 12; // 351 + 9 digits
    } else {
      return cleaned.length == 9 && cleaned.startsWith('9'); // 9 digits starting with 9
    }
  }

  /// Format Portuguese phone number
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Convert to +351 format
    String normalized;
    if (cleaned.startsWith('+351')) {
      normalized = cleaned;
    } else if (cleaned.startsWith('00351')) {
      normalized = '+${cleaned.substring(2)}';
    } else if (cleaned.startsWith('351')) {
      normalized = '+$cleaned';
    } else if (cleaned.startsWith('9') && cleaned.length == 9) {
      normalized = '+351$cleaned';
    } else {
      return phone; // Return original if format is unclear
    }

    // Format as +351 912 345 678
    if (normalized.length == 13) {
      return '${normalized.substring(0, 4)} ${normalized.substring(4, 7)} ${normalized.substring(7, 10)} ${normalized.substring(10)}';
    }
    return normalized;
  }

  /// Get total MB WAY amount (last 30 days)
  Future<double> getTotalMbWayAmount(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _mbwayCollection(userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      return snapshot.docs.fold<double>(
        0.0,
        (total, doc) => total + ((doc['amount'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Error calculating total MB WAY amount: $e');
      return 0.0;
    }
  }

  /// Get MB WAY transaction count
  Future<int> getMbWayTransactionCount(String userId) async {
    try {
      final snapshot = await _mbwayCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error fetching transaction count: $e');
      return 0;
    }
  }
}
