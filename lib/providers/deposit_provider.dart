import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/deposit_model.dart';
import '../models/external_account_model.dart';
import '../models/nordigen_models.dart';
import '../services/deposit_service.dart';

/// Deposit Provider for BJBank
///
/// Manages state for deposits and external bank accounts
class DepositProvider extends ChangeNotifier {
  DepositProvider({DepositService? depositService})
      : _depositService = depositService ?? DepositService();

  final DepositService _depositService;

  // State
  List<NordigenInstitution> _availableBanks = [];
  List<ExternalAccountModel> _linkedAccounts = [];
  List<DepositModel> _deposits = [];
  bool _isLoading = false;
  bool _isBanksLoading = false;
  String? _error;
  String? _currentUserId;

  // Stream subscriptions
  StreamSubscription? _linkedAccountsSubscription;
  StreamSubscription? _depositsSubscription;

  // Getters
  List<NordigenInstitution> get availableBanks => _availableBanks;
  List<ExternalAccountModel> get linkedAccounts => _linkedAccounts;
  List<ExternalAccountModel> get activeAccounts =>
      _linkedAccounts.where((a) => a.isUsable).toList();
  List<DepositModel> get deposits => _deposits;
  List<DepositModel> get recentDeposits => _deposits.take(5).toList();
  bool get isLoading => _isLoading;
  bool get isBanksLoading => _isBanksLoading;
  String? get error => _error;
  bool get hasLinkedAccounts => activeAccounts.isNotEmpty;
  bool get hasError => _error != null;
  bool get isDemoMode => _depositService.isDemoMode;

  /// Initialize provider with user ID
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _depositService.initialize();

      // Start listening to linked accounts
      _linkedAccountsSubscription?.cancel();
      _linkedAccountsSubscription = _depositService
          .streamLinkedAccounts(userId)
          .listen((accounts) {
        _linkedAccounts = accounts;
        notifyListeners();
      });

      // Start listening to deposits
      _depositsSubscription?.cancel();
      _depositsSubscription = _depositService
          .streamDeposits(userId)
          .listen((deposits) {
        _deposits = deposits;
        notifyListeners();
      });

      // Load initial data
      await Future.wait([
        _loadLinkedAccounts(userId),
        _loadDeposits(userId),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao inicializar: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load linked accounts
  Future<void> _loadLinkedAccounts(String userId) async {
    try {
      _linkedAccounts = await _depositService.getLinkedAccounts(userId);
    } catch (e) {
      debugPrint('Error loading linked accounts: $e');
    }
  }

  /// Load deposits
  Future<void> _loadDeposits(String userId) async {
    try {
      _deposits = await _depositService.getDepositHistory(userId);
    } catch (e) {
      debugPrint('Error loading deposits: $e');
    }
  }

  /// Load available Portuguese banks
  Future<void> loadAvailableBanks() async {
    if (_availableBanks.isNotEmpty) return;

    _isBanksLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableBanks = await _depositService.getAvailableBanks();
      _isBanksLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar bancos: $e';
      _isBanksLoading = false;
      notifyListeners();
    }
  }

  /// Search banks by name
  List<NordigenInstitution> searchBanks(String query) {
    if (query.isEmpty) return _availableBanks;

    final lowerQuery = query.toLowerCase();
    return _availableBanks.where((bank) {
      return bank.name.toLowerCase().contains(lowerQuery) ||
             bank.bic.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Start bank connection process
  /// Returns authorization URL for WebView
  Future<({String authUrl, String requisitionId})> startBankConnection(
    String institutionId,
  ) async {
    if (_currentUserId == null) {
      throw Exception('Utilizador não autenticado');
    }

    _error = null;
    notifyListeners();

    try {
      final result = await _depositService.startBankConnection(
        userId: _currentUserId!,
        institutionId: institutionId,
      );
      return result;
    } catch (e) {
      _error = 'Erro ao iniciar conexão: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Complete bank connection after user authorization
  Future<List<ExternalAccountModel>> completeBankConnection(
    String requisitionId,
  ) async {
    if (_currentUserId == null) {
      throw Exception('Utilizador não autenticado');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final accounts = await _depositService.completeBankConnection(
        userId: _currentUserId!,
        requisitionId: requisitionId,
      );

      _linkedAccounts.addAll(accounts);
      _isLoading = false;
      notifyListeners();

      return accounts;
    } catch (e) {
      _error = 'Erro ao completar conexão: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh external account balance
  Future<void> refreshAccountBalance(ExternalAccountModel account) async {
    try {
      final updatedAccount = await _depositService.refreshAccountBalance(account);

      final index = _linkedAccounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _linkedAccounts[index] = updatedAccount;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing balance: $e');
    }
  }

  /// Disconnect external account
  Future<void> disconnectAccount(ExternalAccountModel account) async {
    _error = null;
    notifyListeners();

    try {
      await _depositService.disconnectAccount(account);
      _linkedAccounts.removeWhere((a) => a.id == account.id);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao desconectar conta: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Create deposit
  Future<DepositModel> createDeposit({
    required String bjbankAccountId,
    required String externalAccountId,
    required double amount,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Utilizador não autenticado');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deposit = await _depositService.createDeposit(
        userId: _currentUserId!,
        bjbankAccountId: bjbankAccountId,
        externalAccountId: externalAccountId,
        amount: amount,
      );

      _deposits.insert(0, deposit);
      _isLoading = false;
      notifyListeners();

      return deposit;
    } catch (e) {
      _error = 'Erro ao criar depósito: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get deposit by ID
  Future<DepositModel?> getDeposit(String depositId) async {
    // First check local cache
    final local = _deposits.cast<DepositModel?>().firstWhere(
          (d) => d?.id == depositId,
          orElse: () => null,
        );

    if (local != null) return local;

    // Fetch from service
    return await _depositService.getDeposit(depositId);
  }

  /// Cancel pending deposit
  Future<void> cancelDeposit(String depositId) async {
    _error = null;
    notifyListeners();

    try {
      await _depositService.cancelDeposit(depositId);

      final index = _deposits.indexWhere((d) => d.id == depositId);
      if (index != -1) {
        _deposits[index] = _deposits[index].copyWith(
          status: DepositStatus.cancelled,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao cancelar depósito: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _linkedAccountsSubscription?.cancel();
    _depositsSubscription?.cancel();
    _availableBanks = [];
    _linkedAccounts = [];
    _deposits = [];
    _isLoading = false;
    _isBanksLoading = false;
    _error = null;
    _currentUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _linkedAccountsSubscription?.cancel();
    _depositsSubscription?.cancel();
    super.dispose();
  }
}
