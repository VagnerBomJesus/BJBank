import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../services/card_service.dart';

/// Card Provider for managing card state across the app
///
/// Manages:
/// - Real-time card updates via Firestore streaming
/// - Card creation, update, deletion
/// - Card blocking/unblocking
/// - Card limits management
/// - Card statistics
class CardProvider extends ChangeNotifier {
  final CardService _cardService = CardService();

  List<CardModel> _cards = [];
  CardModel? _selectedCard;
  CardStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _cardsSubscription;
  String? _currentUserId;

  // Getters
  List<CardModel> get cards => _cards;
  CardModel? get selectedCard => _selectedCard;
  CardStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCards => _cards.isNotEmpty;

  // Filtered getters
  List<CardModel> get activeCards =>
      _cards.where((card) => card.status == CardStatus.active).toList();
  List<CardModel> get blockedCards =>
      _cards.where((card) => card.status == CardStatus.blocked).toList();
  List<CardModel> get physicalCards =>
      _cards.where((card) => card.type == CardType.physical).toList();
  List<CardModel> get virtualCards =>
      _cards.where((card) => card.type == CardType.virtual).toList();
  CardModel? get primaryCard {
    if (activeCards.isEmpty) return null;
    return activeCards.reduce((a, b) => a.limit > b.limit ? a : b);
  }

  /// Initialize provider and listen to cards for user
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToCards(userId);
    _loadStatistics(userId);
  }

  /// Listen to real-time card updates
  void _listenToCards(String userId) {
    _cardsSubscription?.cancel();
    _cardsSubscription = _cardService.streamCards(userId).listen(
      (cards) {
        _cards = cards;
        // Clear error message when successfully loaded
        if (_cards.isNotEmpty && _errorMessage != null) {
          _errorMessage = null;
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming cards: $error');
        _errorMessage = 'Erro ao carregar cartões';
        notifyListeners();
      },
    );
  }

  /// Load card statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      _statistics = await _cardService.getCardStatistics(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading card statistics: $e');
    }
  }

  /// Create a new card
  Future<bool> createCard(CardModel card) async {
    if (_currentUserId == null) {
      _errorMessage = 'Utilizador não autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.createCard(card);

      _isLoading = false;
      _cards.add(card);
      _selectedCard = card;
      await _loadStatistics(_currentUserId!);
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao criar cartão: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Load cards for user
  Future<void> loadCards(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cards = await _cardService.getCards(userId);
      _cards = cards;
      await _loadStatistics(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar cartões: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Select a card
  void selectCard(CardModel card) {
    _selectedCard = card;
    notifyListeners();
  }

  /// Block a card
  Future<bool> blockCard(String cardId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.blockCard(_currentUserId!, cardId);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(status: CardStatus.blocked);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao bloquear cartão: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Unblock a card
  Future<bool> unblockCard(String cardId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.unblockCard(_currentUserId!, cardId);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(status: CardStatus.active);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao desbloquear cartão: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update card spending limits (daily and monthly)
  Future<bool> updateCardLimits(
    String cardId,
    double? dailyLimit,
    double? monthlyLimit,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index == -1) {
        _errorMessage = 'Cartão não encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updatedCard = _cards[index].copyWith(
        dailyLimit: dailyLimit ?? _cards[index].dailyLimit,
        monthlyLimit: monthlyLimit ?? _cards[index].monthlyLimit,
      );

      await _cardService.updateCard(_currentUserId!, cardId, updatedCard);

      _cards[index] = updatedCard;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao atualizar limites: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update main card limit
  Future<bool> updateCardLimit(String cardId, double newLimit) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.updateCardLimit(_currentUserId!, cardId, newLimit);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(limit: newLimit);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao atualizar limite: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Lock card for online purchases
  Future<bool> lockCardForOnline(String cardId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.lockForOnline(_currentUserId!, cardId);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(lockedForOnline: true);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao bloquear para compras online: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Unlock card for online purchases
  Future<bool> unlockCardForOnline(String cardId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.unlockForOnline(_currentUserId!, cardId);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(lockedForOnline: false);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao desbloquear para compras online: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Lock card for international purchases
  Future<bool> lockCardForInternational(String cardId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.lockForInternational(_currentUserId!, cardId);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(lockedForInternational: true);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao bloquear para compras internacionais: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Unlock card for international purchases
  Future<bool> unlockCardForInternational(String cardId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.unlockForInternational(_currentUserId!, cardId);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(lockedForInternational: false);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao desbloquear para compras internacionais: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Toggle card feature (generic toggle for various card features)
  Future<bool> toggleCardFeature(String cardId, String feature) async {
    if (cardId.isEmpty) return false;

    final card = _cards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => CardModel(
        id: '',
        userId: '',
        cardNumber: '',
        cardHolder: '',
        expiryDate: '',
        cvv: '',
        limit: 0,
        spentAmount: 0,
        type: CardType.physical,
        status: CardStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (card.id.isEmpty) return false;

    return switch (feature) {
      'online' => card.lockedForOnline
          ? unlockCardForOnline(cardId)
          : lockCardForOnline(cardId),
      'international' => card.lockedForInternational
          ? unlockCardForInternational(cardId)
          : lockCardForInternational(cardId),
      'contactless' => card.lockedForOnline
          ? unlockCardForOnline(cardId)
          : lockCardForOnline(cardId),
      'onlinePaymentsEnabled' => card.lockedForOnline
          ? unlockCardForOnline(cardId)
          : lockCardForOnline(cardId),
      'contactlessEnabled' => card.lockedForOnline
          ? unlockCardForOnline(cardId)
          : lockCardForOnline(cardId),
      'internationalEnabled' => card.lockedForInternational
          ? unlockCardForInternational(cardId)
          : lockCardForInternational(cardId),
      _ => false,
    };
  }

  /// Delete/Cancel card (soft delete - marks as cancelled)
  Future<bool> deleteCard(String cardId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cardService.deleteCard(_currentUserId!, cardId);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(status: CardStatus.cancelled);
        if (_selectedCard?.id == cardId) {
          _selectedCard = null;
        }
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao remover cartão: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update spent amount for a card
  Future<bool> updateSpentAmount(String cardId, double amount) async {
    if (_currentUserId == null) return false;

    try {
      await _cardService.updateSpentAmount(_currentUserId!, cardId, amount);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        final newSpentAmount = _cards[index].spentAmount + amount;
        _cards[index] = _cards[index].copyWith(spentAmount: newSpentAmount);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating spent amount: $e');
      return false;
    }
  }

  /// Reset spent amount for a card
  Future<bool> resetSpentAmount(String cardId) async {
    if (_currentUserId == null) return false;

    try {
      await _cardService.resetSpentAmount(_currentUserId!, cardId);

      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(spentAmount: 0);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error resetting spent amount: $e');
      return false;
    }
  }

  /// Get card by ID
  CardModel? getCard(String cardId) {
    try {
      return _cards.firstWhere((card) => card.id == cardId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh cards for current user
  Future<void> refreshCards() async {
    if (_currentUserId != null) {
      await loadCards(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _cardsSubscription?.cancel();
    super.dispose();
  }
}
