import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bill_model.dart';
import '../services/bill_service.dart';

/// Bill Provider for managing bills state across the app
class BillProvider extends ChangeNotifier {
  final BillService _billService = BillService();

  List<BillModel> _bills = [];
  List<BillModel> _upcomingBills = [];
  List<BillModel> _overdueBills = [];
  BillModel? _selectedBill;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _billsSubscription;
  String? _currentUserId;

  // Statistics
  int _pendingCount = 0;
  int _paidCount = 0;
  int _overdueCount = 0;
  double _totalPending = 0.0;
  double _totalPaid = 0.0;

  // Getters
  List<BillModel> get bills => _bills;
  List<BillModel> get upcomingBills => _upcomingBills;
  List<BillModel> get overdueBills => _overdueBills;
  BillModel? get selectedBill => _selectedBill;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBills => _bills.isNotEmpty;
  bool get hasOverdueBills => _overdueBills.isNotEmpty;

  // Statistics getters
  int get pendingCount => _pendingCount;
  int get paidCount => _paidCount;
  int get overdueCount => _overdueCount;
  double get totalPending => _totalPending;
  double get totalPaid => _totalPaid;

  // Filtered getters
  List<BillModel> get pendingBills =>
      _bills.where((b) => b.status == BillStatus.pending).toList();
  List<BillModel> get paidBills =>
      _bills.where((b) => b.status == BillStatus.paid).toList();
  List<BillModel> get dueSoonBills =>
      _bills.where((b) => b.isDueSoon).toList();

  /// Initialize provider
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToBills(userId);
    _loadUpcomingBills(userId);
    _loadOverdueBills(userId);
    _loadStatistics(userId);
  }

  /// Listen to real-time bill updates
  void _listenToBills(String userId) {
    _billsSubscription?.cancel();
    _billsSubscription = _billService.streamBillsForUser(userId).listen(
      (bills) {
        _bills = bills;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming bills: $error');
        _errorMessage = 'Erro ao carregar contas';
        notifyListeners();
      },
    );
  }

  /// Load upcoming bills
  Future<void> _loadUpcomingBills(String userId) async {
    try {
      _upcomingBills = await _billService.getUpcomingBills(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading upcoming bills: $e');
    }
  }

  /// Load overdue bills
  Future<void> _loadOverdueBills(String userId) async {
    try {
      _overdueBills = await _billService.getOverdueBills(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading overdue bills: $e');
    }
  }

  /// Load statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      final stats = await _billService.getBillStatistics(userId);
      _pendingCount = stats['pendingCount'] ?? 0;
      _paidCount = stats['paidCount'] ?? 0;
      _overdueCount = stats['overdueCount'] ?? 0;
      _totalPending = stats['totalPending'] ?? 0.0;
      _totalPaid = stats['totalPaid'] ?? 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Create a new bill
  Future<bool> createBill({
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
    if (_currentUserId == null) {
      _errorMessage = 'Utilizador não autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bill = await _billService.createBill(
        userId: _currentUserId!,
        creditorName: creditorName,
        amount: amount,
        dueDate: dueDate,
        category: category,
        description: description,
        reference: reference,
        frequency: frequency,
        nextDueDate: nextDueDate,
        notes: notes,
        autoPayEnabled: autoPayEnabled,
      );

      _isLoading = false;

      if (bill != null) {
        _bills.add(bill);
        _selectedBill = bill;
        await _loadStatistics(_currentUserId!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao criar conta';
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

  /// Load bills for user
  Future<void> loadBills(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bills = await _billService.getBillsForUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar contas';
      notifyListeners();
    }
  }

  /// Select a bill
  void selectBill(BillModel bill) {
    _selectedBill = bill;
    notifyListeners();
  }

  /// Mark bill as paid
  Future<bool> markBillAsPaid(String billId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _billService.updateBillStatus(
        _currentUserId!,
        billId,
        BillStatus.paid,
      );

      _isLoading = false;

      if (success) {
        final index = _bills.indexWhere((bill) => bill.id == billId);
        if (index != -1) {
          _bills[index] = _bills[index].copyWith(status: BillStatus.paid);
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao marcar conta como paga';
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

  /// Update bill details
  Future<bool> updateBillDetails(
    String billId,
    double? amount,
    DateTime? dueDate,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _billService.updateBillDetails(
        _currentUserId!,
        billId,
        amount,
        dueDate,
      );

      _isLoading = false;

      if (success) {
        final index = _bills.indexWhere((bill) => bill.id == billId);
        if (index != -1) {
          _bills[index] = _bills[index].copyWith(
            amount: amount ?? _bills[index].amount,
            dueDate: dueDate ?? _bills[index].dueDate,
          );
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar conta';
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

  /// Toggle auto-pay
  Future<bool> toggleAutoPay(String billId, bool enabled) async {
    if (_currentUserId == null) return false;

    try {
      final success = await _billService.toggleAutoPay(
        _currentUserId!,
        billId,
        enabled,
      );

      if (success) {
        final index = _bills.indexWhere((bill) => bill.id == billId);
        if (index != -1) {
          _bills[index] = _bills[index].copyWith(autoPayEnabled: enabled);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling auto-pay: $e');
      return false;
    }
  }

  /// Delete bill
  Future<bool> deleteBill(String billId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _billService.deleteBill(_currentUserId!, billId);

      _isLoading = false;

      if (success) {
        final index = _bills.indexWhere((bill) => bill.id == billId);
        if (index != -1) {
          _bills[index] = _bills[index].copyWith(status: BillStatus.cancelled);
          if (_selectedBill?.id == billId) {
            _selectedBill = null;
          }
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao remover conta';
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

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh bills
  Future<void> refreshBills() async {
    if (_currentUserId != null) {
      await loadBills(_currentUserId!);
      await _loadUpcomingBills(_currentUserId!);
      await _loadOverdueBills(_currentUserId!);
      await _loadStatistics(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _billsSubscription?.cancel();
    super.dispose();
  }
}
