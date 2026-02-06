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
