import 'package:bjbank/compat/firestore_compat.dart';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';

/// Card Service
///
/// Manages card CRUD operations with Firestore backend.
/// Handles secure storage, real-time updates, and card operations.
///
/// Features:
/// - Create, read, update, delete cards
/// - Real-time card streaming
/// - Block/unblock cards
/// - Spending tracking
/// - Card statistics
///
/// Example:
/// ```dart
/// final cardService = CardService();
/// final cards = await cardService.getCards();
/// await cardService.blockCard('card_001');
/// ```
class CardService {
  // Singleton
  static final CardService _instance = CardService._internal();
  factory CardService() => _instance;
  CardService._internal();

  // Firestore
  final _firestore = FirebaseFirestore.instance;

  // Collection reference helper
  String _getCardsCollection(String userId) => 'users/$userId/cards';

  /// Create a new card
  Future<CardModel> createCard(CardModel card) async {
    try {
      debugPrint('Creating card: ${card.id}');

      final data = card.toJson();
      await _firestore
          .collection(_getCardsCollection(card.userId))
          .doc(card.id)
          .set(data);

      debugPrint('Card created successfully: ${card.id}');
      return card;
    } catch (e) {
      debugPrint('Error creating card: $e');
      rethrow;
    }
  }

  /// Get single card by ID
  Future<CardModel?> getCard(String userId, String cardId) async {
    try {
      debugPrint('Fetching card: $cardId');

      final doc = await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .get();

      if (!doc.exists) {
        debugPrint('Card not found: $cardId');
        return null;
      }

      return CardModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching card: $e');
      rethrow;
    }
  }

  /// Get all cards for user
  Future<List<CardModel>> getCards(String userId) async {
    try {
      debugPrint('Fetching all cards for user: $userId');

      final snapshot = await _firestore
          .collection(_getCardsCollection(userId))
          .orderBy('createdAt', descending: true)
          .get();

      final cards = snapshot.docs
          .map((doc) => CardModel.fromFirestore(doc))
          .toList();

      debugPrint('Found ${cards.length} cards');
      return cards;
    } catch (e) {
      debugPrint('Error fetching cards: $e');
      rethrow;
    }
  }

  /// Get active cards only
  Future<List<CardModel>> getActiveCards(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_getCardsCollection(userId))
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs
          .map((doc) => CardModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active cards: $e');
      rethrow;
    }
  }

  /// Stream cards for real-time updates
  Stream<List<CardModel>> streamCards(String userId) {
    try {
      return _firestore
          .collection(_getCardsCollection(userId))
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CardModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming cards: $e');
      rethrow;
    }
  }

  /// Update card details
  Future<void> updateCard(String userId, String cardId, CardModel updatedCard) async {
    try {
      debugPrint('Updating card: $cardId');

      final data = updatedCard.toJson();
      // Don't update createdAt
      data.remove('createdAt');

      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update(data);

      debugPrint('Card updated successfully: $cardId');
    } catch (e) {
      debugPrint('Error updating card: $e');
      rethrow;
    }
  }

  /// Update spent amount
  Future<void> updateSpentAmount(
    String userId,
    String cardId,
    double amount,
  ) async {
    try {
      debugPrint('Updating spent amount for card: $cardId');

      final docRef = _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId);

      await docRef.update({
        'spentAmount': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Spent amount updated: $cardId');
    } catch (e) {
      debugPrint('Error updating spent amount: $e');
      rethrow;
    }
  }

  /// Block a card
  Future<void> blockCard(String userId, String cardId) async {
    try {
      debugPrint('Blocking card: $cardId');

      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'status': 'blocked',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Card blocked: $cardId');
    } catch (e) {
      debugPrint('Error blocking card: $e');
      rethrow;
    }
  }

  /// Unblock a card
  Future<void> unblockCard(String userId, String cardId) async {
    try {
      debugPrint('Unblocking card: $cardId');

      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Card unblocked: $cardId');
    } catch (e) {
      debugPrint('Error unblocking card: $e');
      rethrow;
    }
  }

  /// Lock card for online purchases
  Future<void> lockForOnline(String userId, String cardId) async {
    try {
      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'lockedForOnline': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error locking card for online: $e');
      rethrow;
    }
  }

  /// Unlock card for online purchases
  Future<void> unlockForOnline(String userId, String cardId) async {
    try {
      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'lockedForOnline': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error unlocking card for online: $e');
      rethrow;
    }
  }

  /// Lock card for international purchases
  Future<void> lockForInternational(String userId, String cardId) async {
    try {
      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'lockedForInternational': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error locking card for international: $e');
      rethrow;
    }
  }

  /// Unlock card for international purchases
  Future<void> unlockForInternational(String userId, String cardId) async {
    try {
      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'lockedForInternational': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error unlocking card for international: $e');
      rethrow;
    }
  }

  /// Update card limit
  Future<void> updateCardLimit(
    String userId,
    String cardId,
    double newLimit,
  ) async {
    try {
      debugPrint('Updating card limit: $cardId');

      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'limit': newLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Card limit updated: $cardId');
    } catch (e) {
      debugPrint('Error updating card limit: $e');
      rethrow;
    }
  }

  /// Delete a card
  Future<void> deleteCard(String userId, String cardId) async {
    try {
      debugPrint('Deleting card: $cardId');

      // Soft delete: mark as cancelled
      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Card deleted (soft): $cardId');
    } catch (e) {
      debugPrint('Error deleting card: $e');
      rethrow;
    }
  }

  /// Get card statistics
  Future<CardStatistics> getCardStatistics(String userId) async {
    try {
      debugPrint('Fetching card statistics for user: $userId');

      final cards = await getCards(userId);

      if (cards.isEmpty) {
        return CardStatistics(
          totalCards: 0,
          activeCards: 0,
          blockedCards: 0,
          totalSpent: 0,
          totalAvailable: 0,
        );
      }

      final activeCards =
          cards.where((c) => c.status == CardStatus.active).toList();
      final blockedCards =
          cards.where((c) => c.status == CardStatus.blocked).toList();

      double totalSpent = 0;
      double totalAvailable = 0;

      for (final card in cards) {
        totalSpent += card.spentAmount;
        totalAvailable += card.availableBalance;
      }

      // Find most/least used cards
      CardModel? mostUsedCard;
      CardModel? leastUsedCard;

      if (cards.isNotEmpty) {
        mostUsedCard =
            cards.reduce((a, b) => a.spentAmount > b.spentAmount ? a : b);
        leastUsedCard =
            cards.reduce((a, b) => a.spentAmount < b.spentAmount ? a : b);
      }

      return CardStatistics(
        totalCards: cards.length,
        activeCards: activeCards.length,
        blockedCards: blockedCards.length,
        totalSpent: totalSpent,
        totalAvailable: totalAvailable,
        mostUsedCard: mostUsedCard,
        leastUsedCard: leastUsedCard,
      );
    } catch (e) {
      debugPrint('Error fetching card statistics: $e');
      rethrow;
    }
  }

  /// Reset spent amount (e.g., monthly reset)
  Future<void> resetSpentAmount(String userId, String cardId) async {
    try {
      debugPrint('Resetting spent amount for card: $cardId');

      await _firestore
          .collection(_getCardsCollection(userId))
          .doc(cardId)
          .update({
        'spentAmount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Spent amount reset: $cardId');
    } catch (e) {
      debugPrint('Error resetting spent amount: $e');
      rethrow;
    }
  }

  /// Batch reset spent amounts (e.g., monthly reset for all active cards)
  Future<void> resetAllSpentAmounts(String userId) async {
    try {
      debugPrint('Resetting spent amounts for all cards');

      final cards = await getActiveCards(userId);
      final batch = _firestore.batch();

      for (final card in cards) {
        final docRef = _firestore
            .collection(_getCardsCollection(userId))
            .doc(card.id);

        batch.update(docRef, {
          'spentAmount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('All spent amounts reset');
    } catch (e) {
      debugPrint('Error resetting all spent amounts: $e');
      rethrow;
    }
  }

  /// Get primary card (highest limit)
  Future<CardModel?> getPrimaryCard(String userId) async {
    try {
      final cards = await getActiveCards(userId);
      if (cards.isEmpty) return null;

      return cards.reduce((a, b) => a.limit > b.limit ? a : b);
    } catch (e) {
      debugPrint('Error getting primary card: $e');
      rethrow;
    }
  }

  /// Verify card password/PIN (simplified check)
  /// In production, this would be more secure
  bool verifyCardPin(CardModel card, String pin) {
    // This is a simplified version
    // In production, implement proper PIN verification
    return pin.length == 4;
  }
}
