import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart' as tx;

/// Transfer Service for managing bank transfers
class TransferService {
  static final TransferService _instance = TransferService._internal();
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  TransferService._internal();

  factory TransferService() {
    return _instance;
  }

  /// Collection reference for transactions
  CollectionReference<Map<String, dynamic>> _transactionsCollection(
    String userId,
  ) {
    return _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  /// Initiate a transfer
  Future<bool> initiateTransfer({
    required String senderId,
    required String senderName,
    required String recipientId,
    required String recipientName,
    required String recipientIban,
    required double amount,
    required String description,
    String? concept,
  }) async {
    try {
      final transferId = _firebaseFirestore.collection('_').doc().id;
      final timestamp = DateTime.now();

      // Create sender transaction (expense)
      await _transactionsCollection(senderId).add({
        'id': transferId,
        'description': 'Transferência para $recipientName',
        'amount': amount,
        'date': Timestamp.fromDate(timestamp),
        'type': tx.TransactionType.transfer.name,
        'category': 'Transferência',
        'status': tx.TransactionStatus.processing.name,
        'senderId': senderId,
        'receiverId': recipientId,
        'recipientName': recipientName,
        'recipientIban': recipientIban,
        'concept': concept,
        'isEncrypted': true,
        'createdAt': Timestamp.fromDate(timestamp),
      });

      // If recipient is in the system, create recipient transaction (income)
      try {
        await _transactionsCollection(recipientId).add({
          'id': transferId,
          'description': 'Transferência de $senderName',
          'amount': amount,
          'date': Timestamp.fromDate(timestamp),
          'type': tx.TransactionType.income.name,
          'category': 'Transferência',
          'status': tx.TransactionStatus.completed.name,
          'senderId': senderId,
          'receiverId': recipientId,
          'senderName': senderName,
          'senderIban': '', // Not stored for security
          'concept': concept,
          'isEncrypted': true,
          'createdAt': Timestamp.fromDate(timestamp),
        });
      } catch (e) {
        debugPrint('Note: Recipient not found in system (external transfer): $e');
      }

      debugPrint('Transfer initiated successfully: $transferId');
      return true;
    } catch (e) {
      debugPrint('Error initiating transfer: $e');
      return false;
    }
  }

  /// Get pending transfers for a user
  Future<List<tx.Transaction>> getPendingTransfers(String userId) async {
    try {
      final snapshot = await _transactionsCollection(userId)
          .where('status', isEqualTo: tx.TransactionStatus.processing.name)
          .where('type', isEqualTo: tx.TransactionType.transfer.name)
          .orderBy('date', descending: true)
          .get();

      return _parseTransactions(snapshot.docs);
    } catch (e) {
      debugPrint('Error fetching pending transfers: $e');
      return [];
    }
  }

  /// Get completed transfers for a user
  Future<List<tx.Transaction>> getCompletedTransfers(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _transactionsCollection(userId)
          .where('type', isEqualTo: tx.TransactionType.transfer.name)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return _parseTransactions(snapshot.docs);
    } catch (e) {
      debugPrint('Error fetching completed transfers: $e');
      return [];
    }
  }

  /// Stream of recent transfers
  Stream<List<tx.Transaction>> streamRecentTransfers(
    String userId, {
    int limit = 20,
  }) {
    try {
      return _transactionsCollection(userId)
          .where('type', isEqualTo: tx.TransactionType.transfer.name)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => _parseTransactions(snapshot.docs));
    } catch (e) {
      debugPrint('Error streaming transfers: $e');
      return Stream.value([]);
    }
  }

  /// Cancel a transfer (only if pending)
  Future<bool> cancelTransfer(String userId, String transferId) async {
    try {
      // Get transfer
      final doc = await _transactionsCollection(userId)
          .where('id', isEqualTo: transferId)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return false;

      final transferDoc = doc.docs.first;
      final status =
          tx.TransactionStatus.values.byName(transferDoc['status'] ?? '');

      // Only allow cancellation if pending
      if (status != tx.TransactionStatus.processing) {
        return false;
      }

      // Update status to cancelled
      await transferDoc.reference.update({
        'status': tx.TransactionStatus.cancelled.name,
      });

      debugPrint('Transfer cancelled: $transferId');
      return true;
    } catch (e) {
      debugPrint('Error cancelling transfer: $e');
      return false;
    }
  }

  /// Validate IBAN format (basic validation)
  static bool isValidIBAN(String iban) {
    // Remove spaces
    final cleanIban = iban.replaceAll(' ', '').toUpperCase();

    // Portugal IBAN format: PT + 2 check digits + 4 bank code + 4 branch + 11 account + 2 check
    final portugueseIBAN = RegExp(r'^PT\d{2}\d{4}\d{4}\d{11}\d{2}$');

    return portugueseIBAN.hasMatch(cleanIban);
  }

  /// Format IBAN for display (PT 50 * 0033 * 0000 * 0001 62 67 50)
  static String formatIBAN(String iban) {
    final cleanIban = iban.replaceAll(RegExp(r'\s'), '');
    if (cleanIban.length != 25) return iban; // Invalid length

    final buffer = StringBuffer();
    for (int i = 0; i < cleanIban.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleanIban[i]);
    }
    return buffer.toString();
  }

  /// Get transfer recipient suggestions (previous transfers)
  Future<List<Map<String, String>>> getRecipientSuggestions(
    String userId,
  ) async {
    try {
      final snapshot = await _transactionsCollection(userId)
          .where('type', isEqualTo: tx.TransactionType.transfer.name)
          .where('senderId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      final recipients = <String, Map<String, String>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final recipientId = data['receiverId'] ?? '';
        final recipientName = data['recipientName'] ?? 'Unknown';
        final recipientIban = data['recipientIban'] ?? '';

        if (recipientId.isNotEmpty &&
            !recipients.containsKey(recipientId)) {
          recipients[recipientId] = {
            'id': recipientId,
            'name': recipientName,
            'iban': recipientIban,
          };
        }
      }

      return recipients.values.toList();
    } catch (e) {
      debugPrint('Error fetching recipient suggestions: $e');
      return [];
    }
  }

  /// Parse transaction documents
  List<tx.Transaction> _parseTransactions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      final data = doc.data();
      return tx.Transaction(
        id: data['id'] ?? doc.id,
        description: data['description'] ?? '',
        amount: (data['amount'] ?? 0).toDouble(),
        date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        type: tx.TransactionType.values
            .byName(data['type'] ?? tx.TransactionType.transfer.name),
        category: data['category'],
        isEncrypted: data['isEncrypted'] ?? true,
        senderId: data['senderId'],
        receiverId: data['receiverId'],
        signature: data['signature'],
        status: tx.TransactionStatus.values
            .byName(data['status'] ?? tx.TransactionStatus.completed.name),
      );
    }).toList();
  }
}
