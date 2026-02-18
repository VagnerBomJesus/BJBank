import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_config.dart';

/// Seed Data Service for BJBank
/// Populates Firestore with demo users, accounts, and transactions
/// Use only in development/testing
class SeedDataService {
  static final FirebaseFirestore _db = FirebaseConfig.firestore;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Seed data for 10 demo users
  static final List<Map<String, dynamic>> _seedUsers = [
    {
      'email': 'joao.silva@bjbank.pt',
      'password': 'Joao123456',
      'name': 'João Silva',
      'phone': '+351912345678',
      'balance': 15250.75,
    },
    {
      'email': 'maria.santos@bjbank.pt',
      'password': 'Maria123456',
      'name': 'Maria Santos',
      'phone': '+351923456789',
      'balance': 8430.20,
    },
    {
      'email': 'pedro.costa@bjbank.pt',
      'password': 'Pedro123456',
      'name': 'Pedro Costa',
      'phone': '+351934567890',
      'balance': 22100.00,
    },
    {
      'email': 'ana.oliveira@bjbank.pt',
      'password': 'Ana1234567',
      'name': 'Ana Oliveira',
      'phone': '+351945678901',
      'balance': 5670.50,
    },
    {
      'email': 'carlos.ferreira@bjbank.pt',
      'password': 'Carlos123456',
      'name': 'Carlos Ferreira',
      'phone': '+351956789012',
      'balance': 31400.80,
    },
    {
      'email': 'sofia.rodrigues@bjbank.pt',
      'password': 'Sofia123456',
      'name': 'Sofia Rodrigues',
      'phone': '+351967890123',
      'balance': 12890.30,
    },
    {
      'email': 'miguel.pereira@bjbank.pt',
      'password': 'Miguel123456',
      'name': 'Miguel Pereira',
      'phone': '+351978901234',
      'balance': 7750.00,
    },
    {
      'email': 'ines.almeida@bjbank.pt',
      'password': 'Ines123456',
      'name': 'Inês Almeida',
      'phone': '+351989012345',
      'balance': 19200.60,
    },
    {
      'email': 'tiago.martins@bjbank.pt',
      'password': 'Tiago123456',
      'name': 'Tiago Martins',
      'phone': '+351990123456',
      'balance': 4320.15,
    },
    {
      'email': 'beatriz.sousa@bjbank.pt',
      'password': 'Beatriz123456',
      'name': 'Beatriz Sousa',
      'phone': '+351901234567',
      'balance': 27680.90,
    },
  ];

  /// Run full seed process
  static Future<SeedResult> seedAll() async {
    final result = SeedResult();

    try {
      debugPrint('=== BJBank Seed Data: Starting ===');

      // Step 1: Create users in Firebase Auth + Firestore
      final userIds = <String>[];
      final accountIds = <String>[];

      for (int i = 0; i < _seedUsers.length; i++) {
        final userData = _seedUsers[i];
        try {
          final ids = await _createUserWithAccount(userData, i);
          userIds.add(ids['userId']!);
          accountIds.add(ids['accountId']!);
          result.usersCreated++;
          debugPrint('  User ${i + 1}/10 created: ${userData['name']}');
        } catch (e) {
          if (e.toString().contains('email-already-in-use')) {
            // User already exists, try to get their data
            debugPrint('  User ${userData['email']} already exists, fetching...');
            final existing = await _getExistingUser(userData['email'] as String);
            if (existing != null) {
              userIds.add(existing['userId']!);
              accountIds.add(existing['accountId']!);
              result.usersSkipped++;
            } else {
              result.errors.add('Could not fetch existing user: ${userData['email']}');
              userIds.add('');
              accountIds.add('');
            }
          } else {
            result.errors.add('Error creating ${userData['name']}: $e');
            userIds.add('');
            accountIds.add('');
          }
        }
      }

      // Step 2: Create transactions between users
      await _createSeedTransactions(userIds, accountIds, result);

      debugPrint('=== BJBank Seed Data: Complete ===');
      debugPrint('  Users created: ${result.usersCreated}');
      debugPrint('  Users skipped: ${result.usersSkipped}');
      debugPrint('  Transactions created: ${result.transactionsCreated}');
      debugPrint('  Errors: ${result.errors.length}');

      result.success = true;
    } catch (e) {
      debugPrint('Seed data error: $e');
      result.errors.add('Fatal error: $e');
    }

    return result;
  }

  /// Create a user in Firebase Auth and Firestore with account
  static Future<Map<String, String>> _createUserWithAccount(
    Map<String, dynamic> userData,
    int index,
  ) async {
    // Create Firebase Auth user
    final credential = await _auth.createUserWithEmailAndPassword(
      email: userData['email'] as String,
      password: userData['password'] as String,
    );

    final userId = credential.user!.uid;
    await credential.user!.updateDisplayName(userData['name'] as String);

    // Generate IBAN
    final accountRef = _db.collection('accounts').doc();
    final accountNumber = accountRef.id.substring(0, 11).padLeft(11, '0');
    final bankCode = '0002';
    final branchCode = '0123';
    final iban = 'PT50$bankCode$branchCode$accountNumber';

    // Create user document in Firestore
    await _db.collection('users').doc(userId).set({
      'email': userData['email'],
      'name': userData['name'],
      'phone': userData['phone'],
      'iban': iban,
      'pqcPublicKey': null,
      'emailVerified': true,
      'phoneVerified': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create account document
    final balance = (userData['balance'] as num).toDouble();
    await accountRef.set({
      'userId': userId,
      'iban': iban,
      'accountNumber': accountNumber,
      'type': 'checking',
      'status': 'active',
      'balance': balance,
      'availableBalance': balance,
      'currency': 'EUR',
      'bankCode': bankCode,
      'mbWayLinked': true,
      'mbWayPhone': userData['phone'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update user with IBAN
    await _db.collection('users').doc(userId).update({
      'iban': iban,
    });

    // Sign out so we don't stay logged in as this seed user
    await _auth.signOut();

    return {
      'userId': userId,
      'accountId': accountRef.id,
    };
  }

  /// Get existing user data if already seeded
  static Future<Map<String, String>?> _getExistingUser(String email) async {
    try {
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return null;

      final userId = userQuery.docs.first.id;

      final accountQuery = await _db
          .collection('accounts')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (accountQuery.docs.isEmpty) return null;

      return {
        'userId': userId,
        'accountId': accountQuery.docs.first.id,
      };
    } catch (e) {
      return null;
    }
  }

  /// Create seed transactions between users
  static Future<void> _createSeedTransactions(
    List<String> userIds,
    List<String> accountIds,
    SeedResult result,
  ) async {
    // Seed transaction definitions
    final seedTransactions = [
      // 1. João → Maria: Salary transfer
      {
        'senderIdx': 0,
        'receiverIdx': 1,
        'amount': 500.00,
        'description': 'Transferência - Almoço de equipa',
        'type': 'transfer',
        'daysAgo': 0,
      },
      // 2. Pedro → Ana: MB WAY payment
      {
        'senderIdx': 2,
        'receiverIdx': 3,
        'amount': 25.50,
        'description': 'MB WAY - Café e bolo',
        'type': 'mbway',
        'daysAgo': 1,
      },
      // 3. Carlos → Sofia: Rent
      {
        'senderIdx': 4,
        'receiverIdx': 5,
        'amount': 750.00,
        'description': 'Renda do mês de Fevereiro',
        'type': 'transfer',
        'daysAgo': 1,
      },
      // 4. Miguel → Inês: Gift
      {
        'senderIdx': 6,
        'receiverIdx': 7,
        'amount': 100.00,
        'description': 'Presente de aniversário',
        'type': 'mbway',
        'daysAgo': 2,
      },
      // 5. Tiago → Beatriz: Course payment
      {
        'senderIdx': 8,
        'receiverIdx': 9,
        'amount': 199.90,
        'description': 'Pagamento curso online',
        'type': 'transfer',
        'daysAgo': 2,
      },
      // 6. Maria → João: Payback
      {
        'senderIdx': 1,
        'receiverIdx': 0,
        'amount': 35.00,
        'description': 'MB WAY - Devolução jantar',
        'type': 'mbway',
        'daysAgo': 3,
      },
      // 7. Ana → Carlos: Shared expense
      {
        'senderIdx': 3,
        'receiverIdx': 4,
        'amount': 67.80,
        'description': 'Compras partilhadas supermercado',
        'type': 'transfer',
        'daysAgo': 3,
      },
      // 8. Sofia → Miguel: Electricity split
      {
        'senderIdx': 5,
        'receiverIdx': 6,
        'amount': 45.30,
        'description': 'Divisão conta eletricidade',
        'type': 'mbway',
        'daysAgo': 4,
      },
      // 9. Inês → Tiago: Freelance work
      {
        'senderIdx': 7,
        'receiverIdx': 8,
        'amount': 350.00,
        'description': 'Pagamento trabalho freelance',
        'type': 'transfer',
        'daysAgo': 5,
      },
      // 10. Beatriz → João: Investment return
      {
        'senderIdx': 9,
        'receiverIdx': 0,
        'amount': 1250.00,
        'description': 'Retorno investimento partilhado',
        'type': 'transfer',
        'daysAgo': 6,
      },
      // 11. João → Pedro: Concert tickets
      {
        'senderIdx': 0,
        'receiverIdx': 2,
        'amount': 85.00,
        'description': 'MB WAY - Bilhetes concerto',
        'type': 'mbway',
        'daysAgo': 7,
      },
      // 12. Carlos → Beatriz: Consulting fee
      {
        'senderIdx': 4,
        'receiverIdx': 9,
        'amount': 450.00,
        'description': 'Consultoria financeira',
        'type': 'transfer',
        'daysAgo': 8,
      },
    ];

    for (int i = 0; i < seedTransactions.length; i++) {
      final tx = seedTransactions[i];
      final senderIdx = tx['senderIdx'] as int;
      final receiverIdx = tx['receiverIdx'] as int;

      // Skip if either user was not created
      if (userIds[senderIdx].isEmpty || userIds[receiverIdx].isEmpty) {
        result.errors.add('Skipped transaction $i: missing user');
        continue;
      }

      try {
        final transactionRef = _db.collection('transactions').doc();
        final createdAt = DateTime.now().subtract(
          Duration(days: tx['daysAgo'] as int),
        );

        await transactionRef.set({
          'senderId': userIds[senderIdx],
          'senderAccountId': accountIds[senderIdx],
          'receiverId': userIds[receiverIdx],
          'receiverAccountId': accountIds[receiverIdx],
          'amount': tx['amount'],
          'description': tx['description'],
          'type': tx['type'],
          'status': 'completed',
          'pqcSignature': _generateMockSignature(),
          'isEncrypted': true,
          'createdAt': Timestamp.fromDate(createdAt),
        });

        result.transactionsCreated++;
        debugPrint('  Transaction ${i + 1}/${seedTransactions.length} created: ${tx['description']}');
      } catch (e) {
        result.errors.add('Error creating transaction $i: $e');
      }
    }
  }

  /// Generate a mock PQC signature for demo purposes
  static String _generateMockSignature() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'DILITHIUM3-SIG-$timestamp-BJBANK-PQC-DEMO';
  }

  /// Seed a demo account for Google Play review
  /// Email: demo@bjbank.com / Password: BjBank2026!
  static Future<SeedResult> seedDemoAccount() async {
    final result = SeedResult();

    try {
      debugPrint('=== BJBank: Seeding Demo Account for Google Play ===');

      // Step 1: Create demo user in Firebase Auth
      String demoUserId;
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: 'demo@bjbank.com',
          password: 'BjBank2026!',
        );
        demoUserId = credential.user!.uid;
        await credential.user!.updateDisplayName('Demo User');
        result.usersCreated++;
        debugPrint('  Demo user created in Firebase Auth');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          debugPrint('  Demo user already exists, fetching...');
          final existing = await _getExistingUser('demo@bjbank.com');
          if (existing != null) {
            demoUserId = existing['userId']!;
            result.usersSkipped++;
          } else {
            result.errors.add('Demo user exists in Auth but not in Firestore');
            result.success = false;
            return result;
          }
        } else {
          result.errors.add('Error creating demo user: $e');
          result.success = false;
          return result;
        }
      }

      // Step 2: Create demo user document in Firestore
      final demoIban = 'PT50003600019876543210001';
      await _db.collection('users').doc(demoUserId).set({
        'email': 'demo@bjbank.com',
        'name': 'Demo User',
        'phone': '+351910000000',
        'iban': demoIban,
        'pqcPublicKey': 'DILITHIUM3-PK-DEMO-BJBANK-GOOGLE-PLAY-REVIEW',
        'photoUrl': null,
        'emailVerified': true,
        'phoneVerified': true,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('  Demo user Firestore document created');

      // Step 3: Create demo account with healthy balance
      final demoAccountRef = _db.collection('accounts').doc();
      final demoAccountId = demoAccountRef.id;
      await demoAccountRef.set({
        'userId': demoUserId,
        'iban': demoIban,
        'accountNumber': '98765432100',
        'type': 'checking',
        'status': 'active',
        'balance': 12500.00,
        'availableBalance': 12500.00,
        'currency': 'EUR',
        'bankCode': '0036',
        'mbWayLinked': true,
        'mbWayPhone': '+351910000000',
        'mbWayDailyLimit': 1000.0,
        'mbWayPerTransactionLimit': 500.0,
        'mbWayDailyUsed': 0.0,
        'mbWayLastResetDate': FieldValue.serverTimestamp(),
        'mbWayLinkedAt': FieldValue.serverTimestamp(),
        'mbWayLookupCount': 0,
        'mbWayLastLookup': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('  Demo account created (EUR 12,500.00)');

      // Step 4: Create cards for demo account
      // Visa Debit
      await _db.collection('cards').doc().set({
        'userId': demoUserId,
        'accountId': demoAccountId,
        'cardNumber': '4532015112830366',
        'lastFourDigits': '0366',
        'expiryDate': '12/28',
        'cvv': '123',
        'type': 'debit',
        'brand': 'visa',
        'status': 'active',
        'holderName': 'DEMO USER',
        'dailyLimit': 1000.0,
        'monthlyLimit': 5000.0,
        'contactlessEnabled': true,
        'onlinePaymentsEnabled': true,
        'internationalEnabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('  Visa Debit card created');

      // Mastercard Credit
      await _db.collection('cards').doc().set({
        'userId': demoUserId,
        'accountId': demoAccountId,
        'cardNumber': '5425233430109903',
        'lastFourDigits': '9903',
        'expiryDate': '06/29',
        'cvv': '456',
        'type': 'credit',
        'brand': 'mastercard',
        'status': 'active',
        'holderName': 'DEMO USER',
        'dailyLimit': 2500.0,
        'monthlyLimit': 10000.0,
        'contactlessEnabled': true,
        'onlinePaymentsEnabled': true,
        'internationalEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('  Mastercard Credit card created');

      // Step 5: Create counterparty users for realistic transactions
      final counterparties = <Map<String, String>>[];
      final counterpartyData = [
        {'email': 'ana.review@bjbank.pt', 'name': 'Ana Oliveira', 'phone': '+351920000001'},
        {'email': 'pedro.review@bjbank.pt', 'name': 'Pedro Costa', 'phone': '+351920000002'},
        {'email': 'maria.review@bjbank.pt', 'name': 'Maria Santos', 'phone': '+351920000003'},
      ];

      for (final cp in counterpartyData) {
        String cpUserId;
        try {
          final cpCredential = await _auth.createUserWithEmailAndPassword(
            email: cp['email']!,
            password: 'Review123456',
          );
          cpUserId = cpCredential.user!.uid;
          await cpCredential.user!.updateDisplayName(cp['name']!);
          result.usersCreated++;
        } catch (e) {
          if (e.toString().contains('email-already-in-use')) {
            final existing = await _getExistingUser(cp['email']!);
            if (existing != null) {
              cpUserId = existing['userId']!;
              result.usersSkipped++;
            } else {
              continue;
            }
          } else {
            result.errors.add('Error creating ${cp['name']}: $e');
            continue;
          }
        }

        final cpAccountRef = _db.collection('accounts').doc();

        await _db.collection('users').doc(cpUserId).set({
          'email': cp['email'],
          'name': cp['name'],
          'phone': cp['phone'],
          'iban': 'PT500036000100000000${counterparties.length + 1}0001',
          'pqcPublicKey': null,
          'emailVerified': true,
          'phoneVerified': true,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await cpAccountRef.set({
          'userId': cpUserId,
          'iban': 'PT500036000100000000${counterparties.length + 1}0001',
          'accountNumber': '0000000${counterparties.length + 1}001',
          'type': 'checking',
          'status': 'active',
          'balance': 5000.0,
          'availableBalance': 5000.0,
          'currency': 'EUR',
          'bankCode': '0036',
          'mbWayLinked': true,
          'mbWayPhone': cp['phone'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        counterparties.add({
          'userId': cpUserId,
          'accountId': cpAccountRef.id,
          'name': cp['name']!,
        });
      }

      await _auth.signOut();
      debugPrint('  ${counterparties.length} counterparty users created');

      // Step 6: Create diverse transactions for demo account
      final now = DateTime.now();
      final demoTransactions = [
        // Incoming salary
        {
          'senderId': counterparties.isNotEmpty ? counterparties[0]['userId'] : demoUserId,
          'senderAccountId': counterparties.isNotEmpty ? counterparties[0]['accountId'] : demoAccountId,
          'receiverId': demoUserId,
          'receiverAccountId': demoAccountId,
          'amount': 2150.00,
          'description': 'Salary - February 2026',
          'type': 'income',
          'daysAgo': 1,
        },
        // Transfer sent
        {
          'senderId': demoUserId,
          'senderAccountId': demoAccountId,
          'receiverId': counterparties.length > 1 ? counterparties[1]['userId'] : demoUserId,
          'receiverAccountId': counterparties.length > 1 ? counterparties[1]['accountId'] : demoAccountId,
          'amount': 350.00,
          'description': 'Rent payment - February',
          'type': 'transfer',
          'daysAgo': 2,
        },
        // MB WAY received
        {
          'senderId': counterparties.length > 2 ? counterparties[2]['userId'] : demoUserId,
          'senderAccountId': counterparties.length > 2 ? counterparties[2]['accountId'] : demoAccountId,
          'receiverId': demoUserId,
          'receiverAccountId': demoAccountId,
          'amount': 45.00,
          'description': 'MB WAY - Dinner split',
          'type': 'mbway',
          'daysAgo': 2,
        },
        // MB WAY sent
        {
          'senderId': demoUserId,
          'senderAccountId': demoAccountId,
          'receiverId': counterparties.isNotEmpty ? counterparties[0]['userId'] : demoUserId,
          'receiverAccountId': counterparties.isNotEmpty ? counterparties[0]['accountId'] : demoAccountId,
          'amount': 15.50,
          'description': 'MB WAY - Coffee and pastry',
          'type': 'mbway',
          'daysAgo': 3,
        },
        // Payment
        {
          'senderId': demoUserId,
          'senderAccountId': demoAccountId,
          'receiverId': counterparties.length > 1 ? counterparties[1]['userId'] : demoUserId,
          'receiverAccountId': counterparties.length > 1 ? counterparties[1]['accountId'] : demoAccountId,
          'amount': 89.99,
          'description': 'Online shopping - Electronics',
          'type': 'payment',
          'daysAgo': 4,
        },
        // Transfer received
        {
          'senderId': counterparties.length > 1 ? counterparties[1]['userId'] : demoUserId,
          'senderAccountId': counterparties.length > 1 ? counterparties[1]['accountId'] : demoAccountId,
          'receiverId': demoUserId,
          'receiverAccountId': demoAccountId,
          'amount': 120.00,
          'description': 'Freelance work payment',
          'type': 'transfer',
          'daysAgo': 5,
        },
        // Expense
        {
          'senderId': demoUserId,
          'senderAccountId': demoAccountId,
          'receiverId': counterparties.length > 2 ? counterparties[2]['userId'] : demoUserId,
          'receiverAccountId': counterparties.length > 2 ? counterparties[2]['accountId'] : demoAccountId,
          'amount': 42.30,
          'description': 'Grocery store',
          'type': 'expense',
          'daysAgo': 5,
        },
        // MB WAY received
        {
          'senderId': counterparties.isNotEmpty ? counterparties[0]['userId'] : demoUserId,
          'senderAccountId': counterparties.isNotEmpty ? counterparties[0]['accountId'] : demoAccountId,
          'receiverId': demoUserId,
          'receiverAccountId': demoAccountId,
          'amount': 25.00,
          'description': 'MB WAY - Movie tickets refund',
          'type': 'mbway',
          'daysAgo': 6,
        },
        // Transfer sent
        {
          'senderId': demoUserId,
          'senderAccountId': demoAccountId,
          'receiverId': counterparties.length > 2 ? counterparties[2]['userId'] : demoUserId,
          'receiverAccountId': counterparties.length > 2 ? counterparties[2]['accountId'] : demoAccountId,
          'amount': 200.00,
          'description': 'Gym membership - monthly',
          'type': 'transfer',
          'daysAgo': 7,
        },
        // Previous month salary
        {
          'senderId': counterparties.isNotEmpty ? counterparties[0]['userId'] : demoUserId,
          'senderAccountId': counterparties.isNotEmpty ? counterparties[0]['accountId'] : demoAccountId,
          'receiverId': demoUserId,
          'receiverAccountId': demoAccountId,
          'amount': 2150.00,
          'description': 'Salary - January 2026',
          'type': 'income',
          'daysAgo': 30,
        },
        // Older transfer
        {
          'senderId': demoUserId,
          'senderAccountId': demoAccountId,
          'receiverId': counterparties.length > 1 ? counterparties[1]['userId'] : demoUserId,
          'receiverAccountId': counterparties.length > 1 ? counterparties[1]['accountId'] : demoAccountId,
          'amount': 350.00,
          'description': 'Rent payment - January',
          'type': 'transfer',
          'daysAgo': 31,
        },
        // Older MB WAY
        {
          'senderId': demoUserId,
          'senderAccountId': demoAccountId,
          'receiverId': counterparties.length > 2 ? counterparties[2]['userId'] : demoUserId,
          'receiverAccountId': counterparties.length > 2 ? counterparties[2]['accountId'] : demoAccountId,
          'amount': 30.00,
          'description': 'MB WAY - Birthday gift',
          'type': 'mbway',
          'daysAgo': 35,
        },
      ];

      for (int i = 0; i < demoTransactions.length; i++) {
        final tx = demoTransactions[i];
        try {
          final transactionRef = _db.collection('transactions').doc();
          final createdAt = now.subtract(Duration(days: tx['daysAgo'] as int));

          await transactionRef.set({
            'senderId': tx['senderId'],
            'senderAccountId': tx['senderAccountId'],
            'receiverId': tx['receiverId'],
            'receiverAccountId': tx['receiverAccountId'],
            'amount': tx['amount'],
            'description': tx['description'],
            'type': tx['type'],
            'status': 'completed',
            'pqcSignature': _generateMockSignature(),
            'isEncrypted': true,
            'createdAt': Timestamp.fromDate(createdAt),
          });

          result.transactionsCreated++;
        } catch (e) {
          result.errors.add('Error creating demo transaction $i: $e');
        }
      }

      // Step 7: Add MB WAY recent contacts for demo user
      if (counterparties.isNotEmpty) {
        for (final cp in counterparties) {
          await _db
              .collection('users')
              .doc(demoUserId)
              .collection('mbway_contacts')
              .doc()
              .set({
            'name': cp['name'],
            'phone': counterpartyData[counterparties.indexOf(cp)]['phone'],
            'avatarUrl': null,
            'lastUsed': FieldValue.serverTimestamp(),
            'useCount': 3,
          });
        }
        debugPrint('  MB WAY contacts added');
      }

      debugPrint('=== Demo Account Seed Complete ===');
      debugPrint('  Email: demo@bjbank.com');
      debugPrint('  Password: BjBank2026!');
      debugPrint('  Balance: EUR 12,500.00');
      debugPrint('  Cards: 2 (Visa Debit + Mastercard Credit)');
      debugPrint('  Transactions: ${result.transactionsCreated}');

      result.success = true;
    } catch (e) {
      debugPrint('Demo account seed error: $e');
      result.errors.add('Fatal error: $e');
    }

    return result;
  }

  /// Clear all seed data (use with caution!)
  static Future<void> clearAllData() async {
    debugPrint('=== Clearing all Firestore data ===');

    // Delete transactions
    final transactions = await _db.collection('transactions').get();
    for (var doc in transactions.docs) {
      await doc.reference.delete();
    }
    debugPrint('  Deleted ${transactions.docs.length} transactions');

    // Delete accounts
    final accounts = await _db.collection('accounts').get();
    for (var doc in accounts.docs) {
      await doc.reference.delete();
    }
    debugPrint('  Deleted ${accounts.docs.length} accounts');

    // Delete users
    final users = await _db.collection('users').get();
    for (var doc in users.docs) {
      await doc.reference.delete();
    }
    debugPrint('  Deleted ${users.docs.length} users');

    debugPrint('=== All Firestore data cleared ===');
  }

  /// Check if seed data already exists
  static Future<bool> isSeedDataPresent() async {
    try {
      final users = await _db.collection('users').limit(1).get();
      return users.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Result of seed operation
class SeedResult {
  bool success = false;
  int usersCreated = 0;
  int usersSkipped = 0;
  int transactionsCreated = 0;
  List<String> errors = [];

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('Seed Data Result:');
    buffer.writeln('  Success: $success');
    buffer.writeln('  Users created: $usersCreated');
    buffer.writeln('  Users skipped: $usersSkipped');
    buffer.writeln('  Transactions: $transactionsCreated');
    if (errors.isNotEmpty) {
      buffer.writeln('  Errors:');
      for (var error in errors) {
        buffer.writeln('    - $error');
      }
    }
    return buffer.toString();
  }
}
