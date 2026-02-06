import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/nordigen_config.dart';
import '../models/deposit_model.dart';
import '../models/external_account_model.dart';
import '../models/nordigen_models.dart';
import 'firebase_config.dart';
import 'nordigen_service.dart';
import 'nordigen_service_interface.dart';
import 'mock_nordigen_service.dart';
import 'pqc_service.dart';

/// Deposit Service for BJBank
///
/// Orchestrates deposits from external bank accounts to BJBank accounts
/// via Open Banking (Nordigen/GoCardless)
///
/// Automatically uses MockNordigenService when real credentials are not available.
class DepositService {
  DepositService({
    INordigenService? nordigenService,
    PqcService? pqcService,
  })  : _nordigenService = nordigenService ?? _createNordigenService(),
        _pqcService = pqcService ?? PqcService();

  final INordigenService _nordigenService;
  final PqcService _pqcService;

  /// Create appropriate Nordigen service based on configuration
  static INordigenService _createNordigenService() {
    if (NordigenConfig.useMockService || !NordigenConfig.hasRealCredentials) {
      debugPrint('DepositService: Using MockNordigenService (Demo Mode)');
      return MockNordigenService();
    } else {
      debugPrint('DepositService: Using real NordigenService');
      return NordigenService();
    }
  }

  /// Check if running in demo mode
  bool get isDemoMode =>
      NordigenConfig.useMockService || !NordigenConfig.hasRealCredentials;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _depositsCollection =>
      _db.collection('deposits');

  CollectionReference<Map<String, dynamic>> get _externalAccountsCollection =>
      _db.collection('external_accounts');

  CollectionReference<Map<String, dynamic>> get _accountsCollection =>
      _db.collection('accounts');

  /// Initialize the service
  Future<void> initialize() async {
    await _nordigenService.initialize();
    debugPrint('DepositService initialized');
  }

  // ============== EXTERNAL ACCOUNTS ==============

  /// Get list of Portuguese banks
  Future<List<NordigenInstitution>> getAvailableBanks() async {
    return await _nordigenService.getPortugueseBanks();
  }

  /// Start bank connection process
  /// Returns the authorization URL for the WebView
  Future<({String authUrl, String requisitionId})> startBankConnection({
    required String userId,
    required String institutionId,
  }) async {
    try {
      // Generate unique reference
      final reference = _nordigenService.generateReference(userId);

      // Create agreement for PSD2 compliance
      final agreement = await _nordigenService.createAgreement(
        institutionId: institutionId,
      );

      // Create requisition with agreement
      final requisition = await _nordigenService.createRequisition(
        institutionId: institutionId,
        reference: reference,
        agreementId: agreement.id,
      );

      if (requisition.link == null) {
        throw Exception('No authorization link received');
      }

      debugPrint('Bank connection started: ${requisition.id}');
      return (authUrl: requisition.link!, requisitionId: requisition.id);
    } catch (e) {
      debugPrint('Error starting bank connection: $e');
      rethrow;
    }
  }

  /// Complete bank connection after user authorization
  Future<List<ExternalAccountModel>> completeBankConnection({
    required String userId,
    required String requisitionId,
  }) async {
    try {
      // Get requisition status
      final requisition = await _nordigenService.getRequisition(requisitionId);

      if (!requisition.isLinked) {
        throw Exception('Bank connection not completed. Status: ${requisition.status}');
      }

      if (requisition.accounts.isEmpty) {
        throw Exception('No accounts found in the bank connection');
      }

      // Get institution info
      NordigenInstitution? institution;
      if (requisition.institutionId != null) {
        institution = await _nordigenService.getInstitution(
          requisition.institutionId!,
        );
      }

      final linkedAccounts = <ExternalAccountModel>[];
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 90));

      // Process each account
      for (final accountId in requisition.accounts) {
        try {
          // Get account details
          final accountDetails = await _nordigenService.getAccountDetails(accountId);

          // Get balance
          final balance = await _nordigenService.getPrimaryBalance(accountId);

          // Create external account record
          final externalAccountRef = _externalAccountsCollection.doc();
          final externalAccount = ExternalAccountModel(
            id: externalAccountRef.id,
            userId: userId,
            nordigenAccountId: accountId,
            requisitionId: requisitionId,
            institutionId: requisition.institutionId ?? '',
            institutionName: institution?.name ?? 'Banco',
            institutionLogo: institution?.logo,
            iban: accountDetails.iban ?? '',
            ownerName: accountDetails.ownerName,
            currency: accountDetails.currency ?? 'EUR',
            linkedAt: now,
            expiresAt: expiresAt,
            isActive: true,
            lastBalance: balance?.amount,
            lastBalanceUpdate: now,
          );

          // Save to Firestore
          await externalAccountRef.set(externalAccount.toFirestore());
          linkedAccounts.add(externalAccount);

          debugPrint('Linked account: ${externalAccount.maskedIban}');
        } catch (e) {
          debugPrint('Error processing account $accountId: $e');
        }
      }

      return linkedAccounts;
    } catch (e) {
      debugPrint('Error completing bank connection: $e');
      rethrow;
    }
  }

  /// Get user's linked external accounts
  Future<List<ExternalAccountModel>> getLinkedAccounts(String userId) async {
    try {
      final query = await _externalAccountsCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => ExternalAccountModel.fromFirestore(doc))
          .where((account) => !account.isExpired)
          .toList();
    } catch (e) {
      debugPrint('Error getting linked accounts: $e');
      return [];
    }
  }

  /// Stream user's linked accounts
  Stream<List<ExternalAccountModel>> streamLinkedAccounts(String userId) {
    return _externalAccountsCollection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExternalAccountModel.fromFirestore(doc))
          .where((account) => !account.isExpired)
          .toList();
    });
  }

  /// Refresh external account balance
  Future<ExternalAccountModel> refreshAccountBalance(
    ExternalAccountModel account,
  ) async {
    try {
      final balance = await _nordigenService.getPrimaryBalance(
        account.nordigenAccountId,
      );

      final updatedAccount = account.copyWith(
        lastBalance: balance?.amount,
        lastBalanceUpdate: DateTime.now(),
      );

      await _externalAccountsCollection.doc(account.id).update({
        'lastBalance': balance?.amount,
        'lastBalanceUpdate': FieldValue.serverTimestamp(),
      });

      return updatedAccount;
    } catch (e) {
      debugPrint('Error refreshing balance: $e');
      return account;
    }
  }

  /// Disconnect external account
  Future<void> disconnectAccount(ExternalAccountModel account) async {
    try {
      // Delete requisition from Nordigen
      await _nordigenService.deleteRequisition(account.requisitionId);

      // Mark account as inactive
      await _externalAccountsCollection.doc(account.id).update({
        'isActive': false,
      });

      debugPrint('Account disconnected: ${account.id}');
    } catch (e) {
      debugPrint('Error disconnecting account: $e');
      rethrow;
    }
  }

  // ============== DEPOSITS ==============

  /// Create a deposit from external account to BJBank
  Future<DepositModel> createDeposit({
    required String userId,
    required String bjbankAccountId,
    required String externalAccountId,
    required double amount,
  }) async {
    try {
      // 1. Verify external account is active
      final externalAccountDoc = await _externalAccountsCollection
          .doc(externalAccountId)
          .get();

      if (!externalAccountDoc.exists) {
        throw Exception('Conta externa não encontrada');
      }

      final externalAccount = ExternalAccountModel.fromFirestore(externalAccountDoc);

      if (!externalAccount.isUsable) {
        throw Exception('Conta externa inativa ou expirada');
      }

      // 2. Get BJBank account
      final bjbankAccountDoc = await _accountsCollection
          .doc(bjbankAccountId)
          .get();

      if (!bjbankAccountDoc.exists) {
        throw Exception('Conta BJBank não encontrada');
      }

      // 3. Create deposit record
      final depositRef = _depositsCollection.doc();

      // 4. Sign deposit with PQC
      final pqcSignature = await _signDeposit(
        depositId: depositRef.id,
        userId: userId,
        fromAccountIban: externalAccount.iban,
        toAccountId: bjbankAccountId,
        amount: amount,
      );

      final deposit = DepositModel(
        id: depositRef.id,
        userId: userId,
        accountId: bjbankAccountId,
        externalAccountId: externalAccountId,
        amount: amount,
        currency: 'EUR',
        status: DepositStatus.pending,
        pqcSignature: pqcSignature,
        createdAt: DateTime.now(),
        externalAccountIban: externalAccount.maskedIban,
        externalBankName: externalAccount.institutionName,
      );

      // 5. Save deposit
      await depositRef.set(deposit.toFirestore());

      // 6. Process deposit (for demo - in production this would be async)
      await _processDeposit(deposit, bjbankAccountId);

      // 7. Get updated deposit
      final updatedDoc = await depositRef.get();
      return DepositModel.fromFirestore(updatedDoc);
    } catch (e) {
      debugPrint('Error creating deposit: $e');
      rethrow;
    }
  }

  /// Process deposit (credit BJBank account)
  /// In production, this would be triggered by a webhook from the payment processor
  Future<void> _processDeposit(
    DepositModel deposit,
    String bjbankAccountId,
  ) async {
    try {
      // Update status to processing
      await _depositsCollection.doc(deposit.id).update({
        'status': DepositStatus.processing.name,
      });

      // Simulate processing delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Credit BJBank account using Firestore transaction
      await _db.runTransaction((transaction) async {
        final accountDoc = await transaction.get(
          _accountsCollection.doc(bjbankAccountId),
        );

        if (!accountDoc.exists) {
          throw Exception('BJBank account not found');
        }

        final currentBalance = (accountDoc.data()!['balance'] ?? 0.0).toDouble();
        final currentAvailable = (accountDoc.data()!['availableBalance'] ?? 0.0).toDouble();

        // Credit the account
        transaction.update(_accountsCollection.doc(bjbankAccountId), {
          'balance': currentBalance + deposit.amount,
          'availableBalance': currentAvailable + deposit.amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update deposit status to completed
        transaction.update(_depositsCollection.doc(deposit.id), {
          'status': DepositStatus.completed.name,
          'completedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('Deposit processed: ${deposit.id}');
    } catch (e) {
      // Mark deposit as failed
      await _depositsCollection.doc(deposit.id).update({
        'status': DepositStatus.failed.name,
        'failureReason': e.toString(),
      });
      debugPrint('Deposit failed: ${deposit.id} - $e');
      rethrow;
    }
  }

  /// Sign deposit with PQC
  Future<String> _signDeposit({
    required String depositId,
    required String userId,
    required String fromAccountIban,
    required String toAccountId,
    required double amount,
  }) async {
    final keyPair = await _pqcService.getOrGenerateKeyPair();

    final depositData = jsonEncode({
      'action': 'deposit',
      'depositId': depositId,
      'userId': userId,
      'from': fromAccountIban,
      'to': toAccountId,
      'amount': amount,
      'currency': 'EUR',
      'timestamp': DateTime.now().toIso8601String(),
    });

    final signature = await _pqcService.signTransaction(
      transactionData: depositData,
      keyPair: keyPair,
    );

    return signature.toBase64();
  }

  /// Get user's deposit history
  Future<List<DepositModel>> getDepositHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final query = await _depositsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => DepositModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting deposit history: $e');
      return [];
    }
  }

  /// Stream user's deposits
  Stream<List<DepositModel>> streamDeposits(String userId) {
    return _depositsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DepositModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get deposit by ID
  Future<DepositModel?> getDeposit(String depositId) async {
    try {
      final doc = await _depositsCollection.doc(depositId).get();
      if (!doc.exists) return null;
      return DepositModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting deposit: $e');
      return null;
    }
  }

  /// Cancel pending deposit
  Future<void> cancelDeposit(String depositId) async {
    try {
      final doc = await _depositsCollection.doc(depositId).get();
      if (!doc.exists) {
        throw Exception('Depósito não encontrado');
      }

      final deposit = DepositModel.fromFirestore(doc);
      if (!deposit.isPending) {
        throw Exception('Apenas depósitos pendentes podem ser cancelados');
      }

      await _depositsCollection.doc(depositId).update({
        'status': DepositStatus.cancelled.name,
      });
    } catch (e) {
      debugPrint('Error cancelling deposit: $e');
      rethrow;
    }
  }
}
