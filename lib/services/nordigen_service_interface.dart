import '../models/nordigen_models.dart';

/// Abstract interface for Nordigen service
/// Allows switching between real and mock implementations
abstract class INordigenService {
  Future<void> initialize();
  bool get hasValidToken;
  Future<void> authenticate();
  Future<List<NordigenInstitution>> getPortugueseBanks();
  Future<NordigenInstitution> getInstitution(String institutionId);
  Future<NordigenAgreement> createAgreement({
    required String institutionId,
    int maxHistoricalDays = 90,
    int accessValidForDays = 90,
    List<String> accessScope = const ['balances', 'details', 'transactions'],
  });
  Future<NordigenRequisition> createRequisition({
    required String institutionId,
    required String reference,
    String? agreementId,
    String? userLanguage,
  });
  Future<NordigenRequisition> getRequisition(String requisitionId);
  Future<void> deleteRequisition(String requisitionId);
  Future<NordigenAccount> getAccountDetails(String accountId);
  Future<List<NordigenBalance>> getAccountBalances(String accountId);
  Future<NordigenBalance?> getPrimaryBalance(String accountId);
  Future<List<NordigenTransaction>> getAccountTransactions(
    String accountId, {
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  String generateReference(String userId);
  Future<void> clearTokens();
}
