import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart' as tx;
import '../services/transfer_service.dart';

/// Transfer Provider for managing transfers
class TransferProvider extends ChangeNotifier {
  final TransferService _transferService = TransferService();

  List<tx.Transaction> _recentTransfers = [];
  List<tx.Transaction> _pendingTransfers = [];
  List<Map<String, String>> _recipientSuggestions = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _transfersSubscription;
  String? _currentUserId;

  // Getters
  List<tx.Transaction> get recentTransfers => _recentTransfers;
  List<tx.Transaction> get pendingTransfers => _pendingTransfers;
  List<Map<String, String>> get recipientSuggestions => _recipientSuggestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPendingTransfers => _pendingTransfers.isNotEmpty;

  /// Initialize provider
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToTransfers(userId);
    _loadRecipientSuggestions(userId);
  }

  /// Listen to recent transfers
  void _listenToTransfers(String userId) {
    _transfersSubscription?.cancel();
    _transfersSubscription = _transferService
        .streamRecentTransfers(userId, limit: 50)
        .listen(
      (transfers) {
        _recentTransfers = transfers;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming transfers: $error');
        _errorMessage = 'Erro ao carregar transferências';
        notifyListeners();
      },
    );
  }

  /// Load recipient suggestions
  Future<void> _loadRecipientSuggestions(String userId) async {
    try {
      _recipientSuggestions = await _transferService.getRecipientSuggestions(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recipient suggestions: $e');
    }
  }

  /// Initiate a transfer
  Future<bool> initiateTransfer({
    required String recipientName,
    required String recipientIban,
    required double amount,
    required String description,
    String? concept,
    required String senderName,
  }) async {
    if (_currentUserId == null) {
      _errorMessage = 'Utilizador não autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _transferService.initiateTransfer(
        senderId: _currentUserId!,
        senderName: senderName,
        recipientId: '', // Will be determined from IBAN lookup
        recipientName: recipientName,
        recipientIban: recipientIban,
        amount: amount,
        description: description,
        concept: concept,
      );

      _isLoading = false;

      if (success) {
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao processar transferência';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Load pending transfers
  Future<void> loadPendingTransfers() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingTransfers =
          await _transferService.getPendingTransfers(_currentUserId!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar transferências pendentes';
      notifyListeners();
    }
  }

  /// Cancel a transfer
  Future<bool> cancelTransfer(String transferId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success =
          await _transferService.cancelTransfer(_currentUserId!, transferId);

      _isLoading = false;

      if (success) {
        // Remove from pending transfers
        _pendingTransfers.removeWhere((t) => t.id == transferId);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao cancelar transferência';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Validate IBAN
  bool validateIBAN(String iban) {
    return TransferService.isValidIBAN(iban);
  }

  /// Format IBAN for display
  String formatIBAN(String iban) {
    return TransferService.formatIBAN(iban);
  }

  /// Add recipient to suggestions
  void addRecipientSuggestion(Map<String, String> recipient) {
    if (!_recipientSuggestions.any((r) => r['iban'] == recipient['iban'])) {
      _recipientSuggestions.insert(0, recipient);
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh transfers
  Future<void> refreshTransfers() async {
    if (_currentUserId != null) {
      await loadPendingTransfers();
    }
  }

  @override
  void dispose() {
    _transfersSubscription?.cancel();
    super.dispose();
  }
}
