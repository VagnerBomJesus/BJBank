import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/card_model.dart';
import '../models/mbway_contact_model.dart';
import 'firebase_config.dart';

/// Firestore Service for BJBank
/// Handles all database operations
class FirestoreService {
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _accountsCollection =>
      _db.collection('accounts');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _db.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _cardsCollection =>
      _db.collection('cards');

  // ============== USER OPERATIONS ==============

  /// Create user document
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toFirestore());
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user document
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCollection.doc(userId).update(data);
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Stream user changes
  Stream<UserModel?> streamUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Find user by email
  Future<UserModel?> findUserByEmail(String email) async {
    try {
      final query = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromFirestore(query.docs.first);
    } catch (e) {
      debugPrint('Error finding user by email: $e');
      return null;
    }
  }

  /// Find user by phone (for MB WAY)
  Future<UserModel?> findUserByPhone(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final query = await _usersCollection
          .where('phone', isEqualTo: cleanPhone)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromFirestore(query.docs.first);
    } catch (e) {
      debugPrint('Error finding user by phone: $e');
      return null;
    }
  }

  /// Find user by IBAN
  Future<UserModel?> findUserByIban(String iban) async {
    try {
      final cleanIban = iban.replaceAll(' ', '').toUpperCase();
      final query = await _usersCollection
          .where('iban', isEqualTo: cleanIban)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromFirestore(query.docs.first);
    } catch (e) {
      debugPrint('Error finding user by IBAN: $e');
      return null;
    }
  }

  /// Delete user data (for account deletion)
  Future<void> deleteUserData(String userId) async {
    try {
      // Delete transactions
      final transactions = await _transactionsCollection
          .where('senderId', isEqualTo: userId)
          .get();
      for (var doc in transactions.docs) {
        await doc.reference.delete();
      }

      // Delete cards
      final cards = await _cardsCollection
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in cards.docs) {
        await doc.reference.delete();
      }

      // Delete accounts
      final accounts = await _accountsCollection
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in accounts.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }

  // ============== ACCOUNT OPERATIONS ==============

  /// Create default account for new user with unique IBAN and card
  Future<AccountModel> createDefaultAccount(String userId, {String? userName}) async {
    try {
      final accountRef = _accountsCollection.doc();

      // Generate unique account number
      final accountNumber = await _generateUniqueAccountNumber();

      // Generate unique IBAN
      final iban = await _generateUniqueIban(accountNumber);

      final account = AccountModel(
        id: accountRef.id,
        userId: userId,
        iban: iban,
        accountNumber: accountNumber,
        type: AccountType.checking,
        status: AccountStatus.active,
        balance: 1000.0, // Initial demo balance
        availableBalance: 1000.0,
      );

      await accountRef.set(account.toFirestore());

      // Automatically create a debit card for the new account
      await createDefaultCard(
        userId: userId,
        accountId: accountRef.id,
        holderName: userName ?? 'Titular BJBank',
      );

      return account;
    } catch (e) {
      debugPrint('Error creating default account: $e');
      rethrow;
    }
  }

  /// Generate unique account number with collision check
  Future<String> _generateUniqueAccountNumber() async {
    return AccountNumberGenerator.generateUnique((accountNumber) async {
      final query = await _accountsCollection
          .where('accountNumber', isEqualTo: accountNumber)
          .limit(1)
          .get();
      return query.docs.isEmpty; // Return true if unique
    });
  }

  /// Generate unique IBAN with collision check
  Future<String> _generateUniqueIban(String accountNumber) async {
    String iban = IbanGenerator.generate(accountNumber: accountNumber);

    // Verify uniqueness
    int attempts = 0;
    while (attempts < 10) {
      final query = await _accountsCollection
          .where('iban', isEqualTo: iban)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return iban; // Unique IBAN found
      }

      // Generate new account number and IBAN
      final newAccountNumber = AccountNumberGenerator.generate();
      iban = IbanGenerator.generate(accountNumber: newAccountNumber);
      attempts++;
    }

    // Fallback with timestamp
    final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final fallbackAccountNumber = timestamp.substring(0, 11);
    return IbanGenerator.generate(accountNumber: fallbackAccountNumber);
  }

  /// Get user's primary account
  Future<AccountModel?> getPrimaryAccount(String userId) async {
    try {
      final query = await _accountsCollection
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'checking')
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return AccountModel.fromFirestore(query.docs.first);
    } catch (e) {
      debugPrint('Error getting primary account: $e');
      return null;
    }
  }

  /// Get all user accounts
  Future<List<AccountModel>> getUserAccounts(String userId) async {
    try {
      final query = await _accountsCollection
          .where('userId', isEqualTo: userId)
          .get();
      return query.docs.map((doc) => AccountModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user accounts: $e');
      return [];
    }
  }

  /// Stream user accounts
  Stream<List<AccountModel>> streamUserAccounts(String userId) {
    return _accountsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AccountModel.fromFirestore(doc)).toList();
    });
  }

  /// Find account by IBAN
  Future<AccountModel?> findAccountByIban(String iban) async {
    try {
      final cleanIban = iban.replaceAll(' ', '').toUpperCase();
      final query = await _accountsCollection
          .where('iban', isEqualTo: cleanIban)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return AccountModel.fromFirestore(query.docs.first);
    } catch (e) {
      debugPrint('Error finding account by IBAN: $e');
      return null;
    }
  }

  /// Find account by phone (MB WAY)
  Future<AccountModel?> findAccountByPhone(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final query = await _accountsCollection
          .where('mbWayPhone', isEqualTo: cleanPhone)
          .where('mbWayLinked', isEqualTo: true)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return AccountModel.fromFirestore(query.docs.first);
    } catch (e) {
      debugPrint('Error finding account by phone: $e');
      return null;
    }
  }

  /// Update account balance (internal use)
  Future<void> _updateAccountBalance(
    String accountId,
    double newBalance,
    double newAvailableBalance,
  ) async {
    await _accountsCollection.doc(accountId).update({
      'balance': newBalance,
      'availableBalance': newAvailableBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Link MB WAY to account (simple version)
  Future<void> linkMbWay(String accountId, String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      await _accountsCollection.doc(accountId).update({
        'mbWayLinked': true,
        'mbWayPhone': cleanPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error linking MB WAY: $e');
      rethrow;
    }
  }

  /// Link MB WAY with verification and full setup
  Future<void> linkMbWayVerified(String accountId, String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      await _accountsCollection.doc(accountId).update({
        'mbWayLinked': true,
        'mbWayPhone': cleanPhone,
        'mbWayLinkedAt': FieldValue.serverTimestamp(),
        'mbWayDailyLimit': 1000.0,
        'mbWayPerTransactionLimit': 500.0,
        'mbWayDailyUsed': 0.0,
        'mbWayLastResetDate': FieldValue.serverTimestamp(),
        'mbWayLookupCount': 0,
        'mbWayLastLookup': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error linking MB WAY verified: $e');
      rethrow;
    }
  }

  /// Unlink MB WAY from account
  Future<void> unlinkMbWay(String accountId) async {
    try {
      await _accountsCollection.doc(accountId).update({
        'mbWayLinked': false,
        'mbWayPhone': null,
        'mbWayLinkedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error unlinking MB WAY: $e');
      rethrow;
    }
  }

  /// Update MB WAY limits
  Future<void> updateMbWayLimits(
    String accountId, {
    double? dailyLimit,
    double? perTransactionLimit,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (dailyLimit != null) updates['mbWayDailyLimit'] = dailyLimit;
      if (perTransactionLimit != null) {
        updates['mbWayPerTransactionLimit'] = perTransactionLimit;
      }
      await _accountsCollection.doc(accountId).update(updates);
    } catch (e) {
      debugPrint('Error updating MB WAY limits: $e');
      rethrow;
    }
  }

  /// Check and update MB WAY daily usage
  /// Returns true if transaction is allowed, false if limit exceeded
  Future<bool> checkAndUpdateMbWayUsage(String accountId, double amount) async {
    try {
      return await _db.runTransaction((txn) async {
        final doc = await txn.get(_accountsCollection.doc(accountId));
        if (!doc.exists) return false;

        final data = doc.data()!;
        final now = DateTime.now();

        // Check if daily reset is needed
        final lastReset = (data['mbWayLastResetDate'] as Timestamp?)?.toDate();
        double dailyUsed = (data['mbWayDailyUsed'] ?? 0.0).toDouble();

        if (lastReset == null || !_isSameDay(lastReset, now)) {
          dailyUsed = 0.0;
        }

        final dailyLimit = (data['mbWayDailyLimit'] ?? 1000.0).toDouble();
        final perTxLimit = (data['mbWayPerTransactionLimit'] ?? 500.0).toDouble();

        // Check limits
        if (amount > perTxLimit) {
          return false;
        }
        if ((dailyUsed + amount) > dailyLimit) {
          return false;
        }

        // Update usage
        txn.update(doc.reference, {
          'mbWayDailyUsed': dailyUsed + amount,
          'mbWayLastResetDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error checking MB WAY usage: $e');
      return false;
    }
  }

  /// Get MB WAY usage information
  Future<Map<String, dynamic>> getMbWayUsageInfo(String accountId) async {
    try {
      final doc = await _accountsCollection.doc(accountId).get();
      if (!doc.exists) {
        return {
          'dailyLimit': 1000.0,
          'perTransactionLimit': 500.0,
          'dailyUsed': 0.0,
          'remaining': 1000.0,
        };
      }

      final data = doc.data()!;
      final now = DateTime.now();

      final lastReset = (data['mbWayLastResetDate'] as Timestamp?)?.toDate();
      double dailyUsed = (data['mbWayDailyUsed'] ?? 0.0).toDouble();

      if (lastReset == null || !_isSameDay(lastReset, now)) {
        dailyUsed = 0.0;
      }

      final dailyLimit = (data['mbWayDailyLimit'] ?? 1000.0).toDouble();

      return {
        'dailyLimit': dailyLimit,
        'perTransactionLimit': (data['mbWayPerTransactionLimit'] ?? 500.0).toDouble(),
        'dailyUsed': dailyUsed,
        'remaining': (dailyLimit - dailyUsed).clamp(0.0, dailyLimit),
      };
    } catch (e) {
      debugPrint('Error getting MB WAY usage: $e');
      return {
        'dailyLimit': 1000.0,
        'perTransactionLimit': 500.0,
        'dailyUsed': 0.0,
        'remaining': 1000.0,
      };
    }
  }

  /// Check rate limit for phone lookups (max 10 per hour)
  Future<bool> checkMbWayLookupRateLimit(String accountId) async {
    try {
      return await _db.runTransaction((txn) async {
        final doc = await txn.get(_accountsCollection.doc(accountId));
        if (!doc.exists) return false;

        final data = doc.data()!;
        final now = DateTime.now();

        final lastLookup = (data['mbWayLastLookup'] as Timestamp?)?.toDate();
        int lookupCount = (data['mbWayLookupCount'] ?? 0).toInt();

        // Reset if more than 1 hour has passed
        if (lastLookup == null || now.difference(lastLookup).inHours >= 1) {
          lookupCount = 0;
        }

        if (lookupCount >= 10) {
          return false; // Rate limited
        }

        // Update lookup count
        txn.update(doc.reference, {
          'mbWayLookupCount': lookupCount + 1,
          'mbWayLastLookup': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error checking rate limit: $e');
      return false;
    }
  }

  /// Find account by phone with rate limiting
  Future<AccountModel?> findAccountByPhoneRateLimited(
    String phone,
    String requestingAccountId,
  ) async {
    final allowed = await checkMbWayLookupRateLimit(requestingAccountId);
    if (!allowed) {
      throw Exception('Limite de pesquisas excedido. Aguarde 1 hora.');
    }
    return findAccountByPhone(phone);
  }

  // ============== MB WAY CONTACTS ==============

  /// Add or update recent MB WAY contact
  Future<void> addMbWayRecentContact(String userId, MbWayContact contact) async {
    try {
      final contactsRef = _usersCollection.doc(userId).collection('mbway_contacts');

      // Check if contact already exists
      final existing = await contactsRef
          .where('phone', isEqualTo: contact.phone)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Update existing contact
        await existing.docs.first.reference.update({
          'name': contact.name,
          'avatarUrl': contact.avatarUrl,
          'lastUsed': FieldValue.serverTimestamp(),
          'useCount': FieldValue.increment(1),
        });
      } else {
        // Check if we have 10 contacts, delete oldest if so
        final all = await contactsRef
            .orderBy('lastUsed', descending: true)
            .get();

        if (all.docs.length >= 10) {
          await all.docs.last.reference.delete();
        }

        // Add new contact
        await contactsRef.add(contact.toFirestore());
      }
    } catch (e) {
      debugPrint('Error adding MB WAY contact: $e');
      rethrow;
    }
  }

  /// Get recent MB WAY contacts
  Future<List<MbWayContact>> getMbWayRecentContacts(String userId) async {
    try {
      final snapshot = await _usersCollection
          .doc(userId)
          .collection('mbway_contacts')
          .orderBy('lastUsed', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => MbWayContact.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting MB WAY contacts: $e');
      return [];
    }
  }

  /// Stream recent MB WAY contacts
  Stream<List<MbWayContact>> streamMbWayRecentContacts(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('mbway_contacts')
        .orderBy('lastUsed', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MbWayContact.fromFirestore(doc))
          .toList();
    });
  }

  /// Delete MB WAY contact
  Future<void> deleteMbWayContact(String userId, String contactId) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('mbway_contacts')
          .doc(contactId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting MB WAY contact: $e');
      rethrow;
    }
  }

  /// Get MB WAY transactions for account
  Future<List<Transaction>> getMbWayTransactions(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final sentQuery = await _transactionsCollection
          .where('senderId', isEqualTo: userId)
          .where('type', isEqualTo: 'mbway')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final receivedQuery = await _transactionsCollection
          .where('receiverId', isEqualTo: userId)
          .where('type', isEqualTo: 'mbway')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      // Merge and deduplicate
      final docsMap = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in sentQuery.docs) {
        docsMap[doc.id] = doc;
      }
      for (final doc in receivedQuery.docs) {
        docsMap[doc.id] = doc;
      }

      final allDocs = docsMap.values.toList();
      allDocs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return allDocs.take(limit).map((doc) {
        return _parseTransaction(doc, userId);
      }).toList();
    } catch (e) {
      debugPrint('Error getting MB WAY transactions: $e');
      return [];
    }
  }

  /// Helper: Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============== CARD OPERATIONS ==============

  /// Create default debit card for new account
  Future<CardModel> createDefaultCard({
    required String userId,
    required String accountId,
    required String holderName,
    CardType type = CardType.debit,
    CardBrand brand = CardBrand.visa,
  }) async {
    try {
      final cardRef = _cardsCollection.doc();

      // Generate unique card number
      final cardNumber = await _generateUniqueCardNumber(brand);
      final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
      final cvv = CardNumberGenerator.generateCVV();
      final expiryDate = CardNumberGenerator.generateExpiryDate();

      final card = CardModel(
        id: cardRef.id,
        userId: userId,
        accountId: accountId,
        cardNumber: cardNumber,
        lastFourDigits: lastFourDigits,
        expiryDate: expiryDate,
        cvv: cvv,
        type: type,
        brand: brand,
        status: CardStatus.active,
        holderName: holderName.toUpperCase(),
        dailyLimit: type == CardType.credit ? 2500.0 : 1000.0,
        monthlyLimit: type == CardType.credit ? 10000.0 : 5000.0,
        contactlessEnabled: true,
        onlinePaymentsEnabled: true,
        internationalEnabled: false,
      );

      await cardRef.set(card.toFirestore());
      return card;
    } catch (e) {
      debugPrint('Error creating card: $e');
      rethrow;
    }
  }

  /// Generate unique card number
  Future<String> _generateUniqueCardNumber(CardBrand brand) async {
    String cardNumber;
    int attempts = 0;

    do {
      cardNumber = CardNumberGenerator.generateByBrand(brand);
      final query = await _cardsCollection
          .where('cardNumber', isEqualTo: cardNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return cardNumber;
      }
      attempts++;
    } while (attempts < 100);

    // Should never happen with 16-digit card numbers, but fallback
    return CardNumberGenerator.generateByBrand(brand);
  }

  /// Get user cards
  Future<List<CardModel>> getUserCards(String userId) async {
    try {
      final query = await _cardsCollection
          .where('userId', isEqualTo: userId)
          .get();
      return query.docs.map((doc) => CardModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user cards: $e');
      return [];
    }
  }

  /// Get cards for account
  Future<List<CardModel>> getAccountCards(String accountId) async {
    try {
      final query = await _cardsCollection
          .where('accountId', isEqualTo: accountId)
          .get();
      return query.docs.map((doc) => CardModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting account cards: $e');
      return [];
    }
  }

  /// Stream user cards
  Stream<List<CardModel>> streamUserCards(String userId) {
    return _cardsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CardModel.fromFirestore(doc)).toList();
    });
  }

  /// Update card status (block/unblock)
  Future<void> updateCardStatus(String cardId, CardStatus status) async {
    try {
      await _cardsCollection.doc(cardId).update({
        'status': status.name,
      });
    } catch (e) {
      debugPrint('Error updating card status: $e');
      rethrow;
    }
  }

  /// Update card limits
  Future<void> updateCardLimits(
    String cardId, {
    double? dailyLimit,
    double? monthlyLimit,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (dailyLimit != null) updates['dailyLimit'] = dailyLimit;
      if (monthlyLimit != null) updates['monthlyLimit'] = monthlyLimit;

      if (updates.isNotEmpty) {
        await _cardsCollection.doc(cardId).update(updates);
      }
    } catch (e) {
      debugPrint('Error updating card limits: $e');
      rethrow;
    }
  }

  /// Update card settings
  Future<void> updateCardSettings(
    String cardId, {
    bool? contactlessEnabled,
    bool? onlinePaymentsEnabled,
    bool? internationalEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (contactlessEnabled != null) {
        updates['contactlessEnabled'] = contactlessEnabled;
      }
      if (onlinePaymentsEnabled != null) {
        updates['onlinePaymentsEnabled'] = onlinePaymentsEnabled;
      }
      if (internationalEnabled != null) {
        updates['internationalEnabled'] = internationalEnabled;
      }

      if (updates.isNotEmpty) {
        await _cardsCollection.doc(cardId).update(updates);
      }
    } catch (e) {
      debugPrint('Error updating card settings: $e');
      rethrow;
    }
  }

  /// Delete card
  Future<void> deleteCard(String cardId) async {
    try {
      await _cardsCollection.doc(cardId).delete();
    } catch (e) {
      debugPrint('Error deleting card: $e');
      rethrow;
    }
  }

  // ============== TRANSACTION OPERATIONS ==============

  /// Create transfer transaction (with PQC signature)
  Future<Transaction> createTransfer({
    required String senderId,
    required String senderAccountId,
    required String receiverId,
    required String receiverAccountId,
    required double amount,
    required String description,
    required TransactionType type,
    String? pqcSignature,
  }) async {
    try {
      // Get accounts
      final senderAccountDoc = await _accountsCollection.doc(senderAccountId).get();
      final receiverAccountDoc = await _accountsCollection.doc(receiverAccountId).get();

      if (!senderAccountDoc.exists || !receiverAccountDoc.exists) {
        throw Exception('Conta não encontrada');
      }

      final senderAccount = AccountModel.fromFirestore(senderAccountDoc);
      final receiverAccount = AccountModel.fromFirestore(receiverAccountDoc);

      // Check balance
      if (senderAccount.availableBalance < amount) {
        throw Exception('Saldo insuficiente');
      }

      // Create transaction using Firestore transaction for atomicity
      final transactionRef = _transactionsCollection.doc();

      await _db.runTransaction((firestoreTransaction) async {
        // Debit sender
        firestoreTransaction.update(_accountsCollection.doc(senderAccountId), {
          'balance': senderAccount.balance - amount,
          'availableBalance': senderAccount.availableBalance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Credit receiver
        firestoreTransaction.update(_accountsCollection.doc(receiverAccountId), {
          'balance': receiverAccount.balance + amount,
          'availableBalance': receiverAccount.availableBalance + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create transaction record
        firestoreTransaction.set(transactionRef, {
          'senderId': senderId,
          'senderAccountId': senderAccountId,
          'receiverId': receiverId,
          'receiverAccountId': receiverAccountId,
          'amount': amount,
          'description': description,
          'type': type.name,
          'status': 'completed',
          'pqcSignature': pqcSignature,
          'isEncrypted': pqcSignature != null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // Return created transaction
      return Transaction(
        id: transactionRef.id,
        description: description,
        amount: amount,
        date: DateTime.now(),
        type: type,
        senderId: senderId,
        receiverId: receiverId,
        signature: pqcSignature,
        status: TransactionStatus.completed,
      );
    } catch (e) {
      debugPrint('Error creating transfer: $e');
      rethrow;
    }
  }

  /// Get user transactions
  Future<List<Transaction>> getUserTransactions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      // Get transactions where user is sender
      final sentQuery = await _transactionsCollection
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      // Get transactions where user is receiver
      final receivedQuery = await _transactionsCollection
          .where('receiverId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      // Merge and deduplicate
      final docsMap = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in sentQuery.docs) {
        docsMap[doc.id] = doc;
      }
      for (final doc in receivedQuery.docs) {
        docsMap[doc.id] = doc;
      }

      final allDocs = docsMap.values.toList();
      allDocs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return allDocs.take(limit).map((doc) {
        return _parseTransaction(doc, userId);
      }).toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  /// Parse transaction document to Transaction model
  Transaction _parseTransaction(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUserId,
  ) {
    final data = doc.data()!;
    final isSender = data['senderId'] == currentUserId;
    final originalType = _parseTransactionType(data['type']);

    // Determine display type based on sender/receiver
    TransactionType displayType;
    if (isSender) {
      // User sent money - always an expense
      displayType = originalType == TransactionType.mbway
          ? TransactionType.mbway
          : originalType == TransactionType.transfer
              ? TransactionType.transfer
              : TransactionType.expense;
    } else {
      // User received money - always income
      displayType = TransactionType.income;
    }

    // Build description
    String description = data['description'] ?? '';
    if (description.isEmpty) {
      description = isSender ? 'Transferência enviada' : 'Transferência recebida';
    }

    // Determine category based on type
    String? category;
    if (originalType == TransactionType.mbway) {
      category = 'MB WAY';
    } else if (originalType == TransactionType.transfer) {
      category = 'Transferência';
    } else if (data['category'] != null) {
      category = data['category'];
    }

    return Transaction(
      id: doc.id,
      description: description,
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: displayType,
      category: category,
      isEncrypted: data['isEncrypted'] ?? data['pqcSignature'] != null,
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      signature: data['pqcSignature'],
      status: _parseTransactionStatus(data['status']),
    );
  }

  TransactionType _parseTransactionType(String? type) {
    switch (type) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      case 'mbway':
        return TransactionType.mbway;
      case 'payment':
        return TransactionType.payment;
      default:
        return TransactionType.transfer;
    }
  }

  /// Stream user transactions (both sent and received)
  Stream<List<Transaction>> streamUserTransactions(String userId) {
    // Stream sent transactions
    final sentStream = _transactionsCollection
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    // Stream received transactions
    final receivedStream = _transactionsCollection
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    // Combine both streams
    return sentStream.asyncMap((sentSnapshot) async {
      final receivedSnapshot = await _transactionsCollection
          .where('receiverId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      // Merge and deduplicate
      final docsMap = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in sentSnapshot.docs) {
        docsMap[doc.id] = doc;
      }
      for (final doc in receivedSnapshot.docs) {
        docsMap[doc.id] = doc;
      }

      final allDocs = docsMap.values.toList();
      allDocs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return allDocs.take(50).map((doc) {
        return _parseTransaction(doc, userId);
      }).toList();
    });
  }

  TransactionStatus _parseTransactionStatus(String? status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.completed;
    }
  }
}
