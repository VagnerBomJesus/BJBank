import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/investment_model.dart';

/// Investment Service for managing investments in Firestore
class InvestmentService {
  static final InvestmentService _instance = InvestmentService._internal();
  static final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  InvestmentService._internal();

  factory InvestmentService() {
    return _instance;
  }

  /// Collection reference for investments
  CollectionReference<Map<String, dynamic>> _investmentsCollection(
    String userId,
  ) {
    return _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('investments');
  }

  /// Create a new investment
  Future<InvestmentModel?> createInvestment({
    required String userId,
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
    try {
      final investment = InvestmentModel(
        id: '',
        userId: userId,
        symbol: symbol,
        name: name,
        type: type,
        quantity: quantity,
        purchasePrice: purchasePrice,
        currentPrice: currentPrice,
        investmentDate: investmentDate,
        status: InvestmentStatus.active,
        description: description,
        currency: currency,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final docRef = await _investmentsCollection(userId).add(investment.toFirestore());

      debugPrint('Investment created: ${docRef.id}');

      return investment.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating investment: $e');
      return null;
    }
  }

  /// Get all investments for a user
  Future<List<InvestmentModel>> getInvestmentsForUser(String userId) async {
    try {
      final snapshot = await _investmentsCollection(userId)
          .where('status', isNotEqualTo: InvestmentStatus.closed.name)
          .orderBy('status')
          .orderBy('investmentDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching investments: $e');
      return [];
    }
  }

  /// Stream of investments for a user
  Stream<List<InvestmentModel>> streamInvestmentsForUser(String userId) {
    try {
      return _investmentsCollection(userId)
          .where('status', isNotEqualTo: InvestmentStatus.closed.name)
          .orderBy('status')
          .orderBy('investmentDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => InvestmentModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming investments: $e');
      return Stream.value([]);
    }
  }

  /// Get a single investment
  Future<InvestmentModel?> getInvestment(String userId, String investmentId) async {
    try {
      final doc = await _investmentsCollection(userId).doc(investmentId).get();
      if (doc.exists) {
        return InvestmentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching investment: $e');
      return null;
    }
  }

  /// Update investment current price
  Future<bool> updateInvestmentPrice(
    String userId,
    String investmentId,
    double currentPrice,
  ) async {
    try {
      await _investmentsCollection(userId).doc(investmentId).update({
        'currentPrice': currentPrice,
      });
      debugPrint('Investment price updated');
      return true;
    } catch (e) {
      debugPrint('Error updating investment price: $e');
      return false;
    }
  }

  /// Update investment status
  Future<bool> updateInvestmentStatus(
    String userId,
    String investmentId,
    InvestmentStatus status,
  ) async {
    try {
      await _investmentsCollection(userId).doc(investmentId).update({
        'status': status.name,
      });
      debugPrint('Investment status updated: $status');
      return true;
    } catch (e) {
      debugPrint('Error updating investment status: $e');
      return false;
    }
  }

  /// Delete investment (mark as closed)
  Future<bool> deleteInvestment(String userId, String investmentId) async {
    try {
      await _investmentsCollection(userId).doc(investmentId).update({
        'status': InvestmentStatus.closed.name,
      });
      debugPrint('Investment marked as closed');
      return true;
    } catch (e) {
      debugPrint('Error deleting investment: $e');
      return false;
    }
  }

  /// Get investments by type
  Future<List<InvestmentModel>> getInvestmentsByType(
    String userId,
    InvestmentType type,
  ) async {
    try {
      final snapshot = await _investmentsCollection(userId)
          .where('type', isEqualTo: type.name)
          .orderBy('investmentDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching investments by type: $e');
      return [];
    }
  }

  /// Get portfolio statistics
  Future<Map<String, dynamic>> getPortfolioStatistics(String userId) async {
    try {
      final investments = await getInvestmentsForUser(userId);

      double totalInvested = 0;
      double totalValue = 0;
      double totalGainLoss = 0;

      for (final inv in investments) {
        totalInvested += inv.totalInvested;
        totalValue += inv.currentValue;
        totalGainLoss += inv.gainLoss;
      }

      final totalGainLossPercentage = totalInvested > 0
          ? (totalGainLoss / totalInvested) * 100
          : 0.0;

      // Count by type
      final typeBreakdown = <String, int>{};
      for (final inv in investments) {
        typeBreakdown[inv.type.name] =
            (typeBreakdown[inv.type.name] ?? 0) + 1;
      }

      return {
        'totalInvested': totalInvested,
        'totalValue': totalValue,
        'totalGainLoss': totalGainLoss,
        'totalGainLossPercentage': totalGainLossPercentage,
        'investmentCount': investments.length,
        'typeBreakdown': typeBreakdown,
      };
    } catch (e) {
      debugPrint('Error fetching portfolio statistics: $e');
      return {};
    }
  }

  /// Get top gaining investments
  Future<List<InvestmentModel>> getTopGainers(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final investments = await getInvestmentsForUser(userId);
      investments.sort((a, b) => b.gainLossPercentage.compareTo(a.gainLossPercentage));
      return investments.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching top gainers: $e');
      return [];
    }
  }

  /// Get top losing investments
  Future<List<InvestmentModel>> getTopLosers(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final investments = await getInvestmentsForUser(userId);
      investments.sort((a, b) => a.gainLossPercentage.compareTo(b.gainLossPercentage));
      return investments.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching top losers: $e');
      return [];
    }
  }
}
