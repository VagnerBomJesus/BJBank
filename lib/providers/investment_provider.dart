import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/investment_model.dart';
import '../services/investment_service.dart';

/// Investment Provider for managing investments portfolio
class InvestmentProvider extends ChangeNotifier {
  final InvestmentService _investmentService = InvestmentService();

  List<InvestmentModel> _investments = [];
  List<InvestmentModel> _topGainers = [];
  List<InvestmentModel> _topLosers = [];
  InvestmentModel? _selectedInvestment;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _investmentsSubscription;
  String? _currentUserId;

  // Statistics
  double _totalInvested = 0.0;
  double _totalValue = 0.0;
  double _totalGainLoss = 0.0;
  double _totalGainLossPercentage = 0.0;
  int _investmentCount = 0;
  Map<String, int> _typeBreakdown = {};

  // Getters
  List<InvestmentModel> get investments => _investments;
  List<InvestmentModel> get topGainers => _topGainers;
  List<InvestmentModel> get topLosers => _topLosers;
  InvestmentModel? get selectedInvestment => _selectedInvestment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasInvestments => _investments.isNotEmpty;

  // Statistics getters
  double get totalInvested => _totalInvested;
  double get totalValue => _totalValue;
  double get totalGainLoss => _totalGainLoss;
  double get totalGainLossPercentage => _totalGainLossPercentage;
  int get investmentCount => _investmentCount;
  Map<String, int> get typeBreakdown => _typeBreakdown;

  /// Initialize provider
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToInvestments(userId);
    _loadStatistics(userId);
  }

  /// Listen to real-time investment updates
  void _listenToInvestments(String userId) {
    _investmentsSubscription?.cancel();
    _investmentsSubscription =
        _investmentService.streamInvestmentsForUser(userId).listen(
      (investments) {
        _investments = investments;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming investments: $error');
        _errorMessage = 'Erro ao carregar investimentos';
        notifyListeners();
      },
    );
  }

  /// Load statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      final stats = await _investmentService.getPortfolioStatistics(userId);
      _totalInvested = stats['totalInvested'] ?? 0.0;
      _totalValue = stats['totalValue'] ?? 0.0;
      _totalGainLoss = stats['totalGainLoss'] ?? 0.0;
      _totalGainLossPercentage = stats['totalGainLossPercentage'] ?? 0.0;
      _investmentCount = stats['investmentCount'] ?? 0;
      _typeBreakdown =
          Map<String, int>.from(stats['typeBreakdown'] ?? {});

      // Load top gainers and losers
      _topGainers =
          await _investmentService.getTopGainers(userId, limit: 3);
      _topLosers = await _investmentService.getTopLosers(userId, limit: 3);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Create a new investment
  Future<bool> createInvestment({
    required String symbol,
    required String name,
    required InvestmentType type,
    required double quantity,
    required double purchasePrice,
    required double currentPrice,
    required DateTime investmentDate,
    String description = '',
    String currency = 'EUR',
    String notes = '',
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
      final investment = await _investmentService.createInvestment(
        userId: _currentUserId!,
        symbol: symbol,
        name: name,
        type: type,
        quantity: quantity,
        purchasePrice: purchasePrice,
        currentPrice: currentPrice,
        investmentDate: investmentDate,
        description: description,
        currency: currency,
        notes: notes,
      );

      _isLoading = false;

      if (investment != null) {
        _investments.add(investment);
        _selectedInvestment = investment;
        await _loadStatistics(_currentUserId!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao criar investimento';
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

  /// Select an investment
  void selectInvestment(InvestmentModel investment) {
    _selectedInvestment = investment;
    notifyListeners();
  }

  /// Update investment price
  Future<bool> updateInvestmentPrice(
    String investmentId,
    double currentPrice,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _investmentService.updateInvestmentPrice(
        _currentUserId!,
        investmentId,
        currentPrice,
      );

      _isLoading = false;

      if (success) {
        final index = _investments.indexWhere((inv) => inv.id == investmentId);
        if (index != -1) {
          _investments[index] = _investments[index].copyWith(
            currentPrice: currentPrice,
          );
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar preço';
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

  /// Close investment
  Future<bool> closeInvestment(String investmentId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _investmentService.deleteInvestment(
        _currentUserId!,
        investmentId,
      );

      _isLoading = false;

      if (success) {
        final index = _investments.indexWhere((inv) => inv.id == investmentId);
        if (index != -1) {
          _investments[index] = _investments[index].copyWith(
            status: InvestmentStatus.closed,
          );
          if (_selectedInvestment?.id == investmentId) {
            _selectedInvestment = null;
          }
          notifyListeners();
        }
        await _loadStatistics(_currentUserId!);
        return true;
      } else {
        _errorMessage = 'Erro ao fechar investimento';
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

  /// Refresh portfolio
  Future<void> refreshPortfolio() async {
    if (_currentUserId != null) {
      await _loadStatistics(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _investmentsSubscription?.cancel();
    super.dispose();
  }
}
