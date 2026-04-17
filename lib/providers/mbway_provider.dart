import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/mbway_contact_model.dart';
import '../services/mbway_service.dart';

/// MB WAY Provider for managing MB WAY payments and contacts
class MbWayProvider extends ChangeNotifier {
  final MbWayService _mbwayService = MbWayService();

  List<MbWayContact> _contacts = [];
  List<MbWayContact> _frequentContacts = [];
  List<Map<String, dynamic>> _transactionHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _contactsSubscription;
  StreamSubscription? _historySubscription;
  String? _currentUserId;

  // Statistics
  double _totalMbWayAmount = 0.0;
  int _transactionCount = 0;

  // Getters
  List<MbWayContact> get contacts => _contacts;
  List<MbWayContact> get frequentContacts => _frequentContacts;
  List<Map<String, dynamic>> get transactionHistory => _transactionHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasContacts => _contacts.isNotEmpty;
  double get totalMbWayAmount => _totalMbWayAmount;
  int get transactionCount => _transactionCount;

  /// Initialize provider
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToContacts(userId);
    _listenToHistory(userId);
    _loadStatistics(userId);
  }

  /// Listen to real-time contact updates
  void _listenToContacts(String userId) {
    _contactsSubscription?.cancel();
    _contactsSubscription = _mbwayService.streamContacts(userId).listen(
      (contacts) {
        _contacts = contacts;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming contacts: $error');
        _errorMessage = 'Erro ao carregar contactos';
        notifyListeners();
      },
    );
  }

  /// Listen to real-time transaction history
  void _listenToHistory(String userId) {
    _historySubscription?.cancel();
    _historySubscription = _mbwayService.streamMbWayHistory(userId).listen(
      (history) {
        _transactionHistory = history;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming history: $error');
        _errorMessage = 'Erro ao carregar histórico';
        notifyListeners();
      },
    );
  }

  /// Load statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      _totalMbWayAmount = await _mbwayService.getTotalMbWayAmount(userId);
      _transactionCount = await _mbwayService.getMbWayTransactionCount(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Load frequent contacts
  Future<void> loadFrequentContacts() async {
    if (_currentUserId == null) return;

    try {
      _frequentContacts =
          await _mbwayService.getFrequentContacts(_currentUserId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading frequent contacts: $e');
    }
  }

  /// Initiate MB WAY payment
  Future<bool> initiateMbWayPayment({
    required String recipientPhone,
    required String recipientName,
    required double amount,
    required String description,
    String? reference,
    required String senderName,
  }) async {
    if (_currentUserId == null) {
      _errorMessage = 'Utilizador não autenticado';
      notifyListeners();
      return false;
    }

    // Validate phone number
    if (!MbWayService.isValidPhoneNumber(recipientPhone)) {
      _errorMessage = 'Número de telefone inválido';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _mbwayService.initiateMbWayPayment(
        senderId: _currentUserId!,
        senderName: senderName,
        recipientPhone: recipientPhone,
        recipientName: recipientName,
        amount: amount,
        description: description,
        reference: reference,
      );

      _isLoading = false;

      if (success) {
        _errorMessage = null;
        await _loadStatistics(_currentUserId!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao processar pagamento MB WAY';
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

  /// Delete contact
  Future<bool> deleteContact(String contactId) async {
    if (_currentUserId == null) return false;

    try {
      final success =
          await _mbwayService.deleteContact(_currentUserId!, contactId);

      if (success) {
        _contacts.removeWhere((c) => c.id == contactId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      return false;
    }
  }

  /// Validate phone number
  bool validatePhoneNumber(String phone) {
    return MbWayService.isValidPhoneNumber(phone);
  }

  /// Format phone number
  String formatPhoneNumber(String phone) {
    return MbWayService.formatPhoneNumber(phone);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refreshData() async {
    if (_currentUserId != null) {
      await loadFrequentContacts();
      await _loadStatistics(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _contactsSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}
