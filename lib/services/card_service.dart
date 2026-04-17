import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';

/// Card Service for managing cards in Firestore
class CardService {
  static final CardService _instance = CardService._internal();
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  CardService._internal();

  factory CardService() {
    return _instance;
  }

  /// Collection reference for cards
  CollectionReference<Map<String, dynamic>> _cardsCollection(String userId) {
    return _firebaseFirestore.collection('users').doc(userId).collection('cards');
  }

  /// Create a new card
  Future<CardModel?> createCard({
    required String userId,
    required String accountId,
    required CardType type,
    required CardBrand brand,
    String? holderName,
    double dailyLimit = 1000.0,
    double monthlyLimit = 5000.0,
  }) async {
    try {
      // Generate card details
      final cardNumber = CardNumberGenerator.generateByBrand(brand);
      final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
      final expiryDate = CardNumberGenerator.generateExpiryDate();
      final cvv = CardNumberGenerator.generateCVV();

      final card = CardModel(
        id: '', // Will be set by Firestore
        userId: userId,
        accountId: accountId,
        cardNumber: cardNumber,
        lastFourDigits: lastFourDigits,
        expiryDate: expiryDate,
        cvv: cvv,
        type: type,
        brand: brand,
        status: CardStatus.active,
        holderName: holderName ?? '',
        dailyLimit: dailyLimit,
        monthlyLimit: monthlyLimit,
        createdAt: DateTime.now(),
      );

      final docRef = await _cardsCollection(userId).add(card.toFirestore());

      debugPrint('Card created: ${docRef.id}');

      return card.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating card: $e');
      return null;
    }
  }

  /// Get all cards for a user
  Future<List<CardModel>> getCardsForUser(String userId) async {
    try {
      final snapshot = await _cardsCollection(userId).get();
      return snapshot.docs
          .map((doc) => CardModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching cards: $e');
      return [];
    }
  }

  /// Stream of cards for a user (real-time updates)
  Stream<List<CardModel>> streamCardsForUser(String userId) {
    try {
      return _cardsCollection(userId).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => CardModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      debugPrint('Error streaming cards: $e');
      return Stream.value([]);
    }
  }

  /// Get a single card
  Future<CardModel?> getCard(String userId, String cardId) async {
    try {
      final doc = await _cardsCollection(userId).doc(cardId).get();
      if (doc.exists) {
        return CardModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching card: $e');
      return null;
    }
  }

  /// Update card status (block/unblock)
  Future<bool> updateCardStatus(
    String userId,
    String cardId,
    CardStatus status,
  ) async {
    try {
      await _cardsCollection(userId).doc(cardId).update({
        'status': status.name,
      });
      debugPrint('Card status updated: $status');
      return true;
    } catch (e) {
      debugPrint('Error updating card status: $e');
      return false;
    }
  }

  /// Update card limits
  Future<bool> updateCardLimits(
    String userId,
    String cardId,
    double? dailyLimit,
    double? monthlyLimit,
  ) async {
    try {
      final updates = <String, dynamic>{};
      if (dailyLimit != null) updates['dailyLimit'] = dailyLimit;
      if (monthlyLimit != null) updates['monthlyLimit'] = monthlyLimit;

      if (updates.isNotEmpty) {
        await _cardsCollection(userId).doc(cardId).update(updates);
        debugPrint('Card limits updated');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating card limits: $e');
      return false;
    }
  }

  /// Toggle card feature (contactless, online payments, international)
  Future<bool> toggleCardFeature(
    String userId,
    String cardId,
    String feature,
    bool enabled,
  ) async {
    try {
      final validFeatures = [
        'contactlessEnabled',
        'onlinePaymentsEnabled',
        'internationalEnabled',
      ];

      if (!validFeatures.contains(feature)) {
        debugPrint('Invalid feature: $feature');
        return false;
      }

      await _cardsCollection(userId).doc(cardId).update({
        feature: enabled,
      });
      debugPrint('Card feature toggled: $feature = $enabled');
      return true;
    } catch (e) {
      debugPrint('Error toggling card feature: $e');
      return false;
    }
  }

  /// Delete card (mark as cancelled)
  Future<bool> deleteCard(String userId, String cardId) async {
    try {
      await _cardsCollection(userId).doc(cardId).update({
        'status': CardStatus.cancelled.name,
      });
      debugPrint('Card marked as cancelled');
      return true;
    } catch (e) {
      debugPrint('Error deleting card: $e');
      return false;
    }
  }

  /// Get cards by status
  Future<List<CardModel>> getCardsByStatus(
    String userId,
    CardStatus status,
  ) async {
    try {
      final snapshot = await _cardsCollection(userId)
          .where('status', isEqualTo: status.name)
          .get();
      return snapshot.docs
          .map((doc) => CardModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching cards by status: $e');
      return [];
    }
  }

  /// Get primary card (first active card)
  Future<CardModel?> getPrimaryCard(String userId) async {
    try {
      final snapshot = await _cardsCollection(userId)
          .where('status', isEqualTo: CardStatus.active.name)
          .orderBy('createdAt', descending: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return CardModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching primary card: $e');
      return null;
    }
  }

  /// Check if card exists for a given account
  Future<bool> cardExistsForAccount(
    String userId,
    String accountId,
  ) async {
    try {
      final snapshot = await _cardsCollection(userId)
          .where('accountId', isEqualTo: accountId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking card existence: $e');
      return false;
    }
  }
}
