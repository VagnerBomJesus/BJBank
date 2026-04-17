import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../services/card_service.dart';

/// Card Provider for managing card state across the app
class CardProvider extends ChangeNotifier {
  final CardService _cardService = CardService();

  List<CardModel> _cards = [];
  CardModel? _selectedCard;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _cardsSubscription;
  String? _currentUserId;

  // Getters
  List<CardModel> get cards => _cards;
  CardModel? get selectedCard => _selectedCard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCards => _cards.isNotEmpty;

  // Filtered getters
  List<CardModel> get activeCards =>
      _cards.where((card) => card.status == CardStatus.active).toList();
  List<CardModel> get blockedCards =>
      _cards.where((card) => card.status == CardStatus.blocked).toList();
  CardModel? get primaryCard => activeCards.isNotEmpty ? activeCards.first : null;

  /// Initialize provider and listen to cards for user
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToCards(userId);
  }

  /// Listen to real-time card updates
  void _listenToCards(String userId) {
    _cardsSubscription?.cancel();
    _cardsSubscription = _cardService.streamCardsForUser(userId).listen(
      (cards) {
        _cards = cards;
        // Clear error message when successfully loaded
        if (_cards.isNotEmpty || _errorMessage != null) {
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

  /// Create a new card
  Future<bool> createCard({
    required String accountId,
    required CardType type,
    required CardBrand brand,
    String? holderName,
    double dailyLimit = 1000.0,
    double monthlyLimit = 5000.0,
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
      final card = await _cardService.createCard(
        userId: _currentUserId!,
        accountId: accountId,
        type: type,
        brand: brand,
        holderName: holderName,
        dailyLimit: dailyLimit,
        monthlyLimit: monthlyLimit,
      );

      _isLoading = false;

      if (card != null) {
        _cards.add(card);
        _selectedCard = card;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao criar cartão';
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

  /// Load cards for user
  Future<void> loadCards(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cards = await _cardService.getCardsForUser(userId);
      _cards = cards;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar cartões';
      notifyListeners();
    }
  }

  /// Select a card
  void selectCard(CardModel card) {
    _selectedCard = card;
    notifyListeners();
  }

  /// Block/Unblock card
  Future<bool> updateCardStatus(String cardId, CardStatus status) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _cardService.updateCardStatus(
        _currentUserId!,
        cardId,
        status,
      );

      _isLoading = false;

      if (success) {
        final index = _cards.indexWhere((card) => card.id == cardId);
        if (index != -1) {
          _cards[index] = _cards[index].copyWith(status: status);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar cartão';
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

  /// Update card limits
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
      final success = await _cardService.updateCardLimits(
        _currentUserId!,
        cardId,
        dailyLimit,
        monthlyLimit,
      );

      _isLoading = false;

      if (success) {
        final index = _cards.indexWhere((card) => card.id == cardId);
        if (index != -1) {
          _cards[index] = _cards[index].copyWith(
            dailyLimit: dailyLimit ?? _cards[index].dailyLimit,
            monthlyLimit: monthlyLimit ?? _cards[index].monthlyLimit,
          );
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar limites';
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

  /// Toggle card feature
  Future<bool> toggleCardFeature(
    String cardId,
    String feature,
    bool enabled,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _cardService.toggleCardFeature(
        _currentUserId!,
        cardId,
        feature,
        enabled,
      );

      _isLoading = false;

      if (success) {
        final index = _cards.indexWhere((card) => card.id == cardId);
        if (index != -1) {
          final updates = <String, dynamic>{};

          switch (feature) {
            case 'contactlessEnabled':
              updates['contactlessEnabled'] = enabled;
              break;
            case 'onlinePaymentsEnabled':
              updates['onlinePaymentsEnabled'] = enabled;
              break;
            case 'internationalEnabled':
              updates['internationalEnabled'] = enabled;
              break;
          }

          _cards[index] = _cards[index].copyWith(
            contactlessEnabled: updates['contactlessEnabled'] ??
                _cards[index].contactlessEnabled,
            onlinePaymentsEnabled: updates['onlinePaymentsEnabled'] ??
                _cards[index].onlinePaymentsEnabled,
            internationalEnabled: updates['internationalEnabled'] ??
                _cards[index].internationalEnabled,
          );
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = 'Erro ao atualizar recurso do cartão';
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

  /// Delete/Cancel card
  Future<bool> deleteCard(String cardId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _cardService.deleteCard(_currentUserId!, cardId);

      _isLoading = false;

      if (success) {
        final index = _cards.indexWhere((card) => card.id == cardId);
        if (index != -1) {
          _cards[index] = _cards[index].copyWith(status: CardStatus.cancelled);
          if (_selectedCard?.id == cardId) {
            _selectedCard = null;
          }
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = 'Erro ao remover cartão';
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
