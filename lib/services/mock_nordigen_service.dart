import 'package:flutter/foundation.dart';
import '../models/nordigen_models.dart';
import 'nordigen_service_interface.dart';

/// Mock Nordigen Service for Demo/Research
///
/// Simulates the Nordigen/GoCardless API for testing purposes
/// when real API credentials are not available.
class MockNordigenService implements INordigenService {
  MockNordigenService();

  // Simulated delay for realistic behavior
  static const Duration _networkDelay = Duration(milliseconds: 800);

  /// Simulated Portuguese banks
  static final List<NordigenInstitution> _mockBanks = [
    const NordigenInstitution(
      id: 'CAIXA_GERAL_DE_DEPOSITOS_CGDIPTPL',
      name: 'Caixa Geral de Depósitos',
      bic: 'CGDIPTPL',
      logo: 'https://cdn.nordigen.com/ais/CAIXA_GERAL_DE_DEPOSITOS_CGDIPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'MILLENNIUM_BCP_BCOMPTPL',
      name: 'Millennium BCP',
      bic: 'BCOMPTPL',
      logo: 'https://cdn.nordigen.com/ais/MILLENNIUM_BCP_BCOMPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'NOVO_BANCO_NOVBPTPL',
      name: 'Novo Banco',
      bic: 'NOVBPTPL',
      logo: 'https://cdn.nordigen.com/ais/NOVO_BANCO_NOVBPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'SANTANDER_TOTTA_TOTAPTPL',
      name: 'Santander Portugal',
      bic: 'TOTAPTPL',
      logo: 'https://cdn.nordigen.com/ais/SANTANDER_TOTTA_TOTAPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'BPI_BBPIPTPL',
      name: 'Banco BPI',
      bic: 'BBPIPTPL',
      logo: 'https://cdn.nordigen.com/ais/BPI_BBPIPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'BANKINTER_BKBKPTPL',
      name: 'Bankinter Portugal',
      bic: 'BKBKPTPL',
      logo: 'https://cdn.nordigen.com/ais/BANKINTER_BKBKPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'ACTIVOBANK_ACTBPTPL',
      name: 'ActivoBank',
      bic: 'ACTBPTPL',
      logo: 'https://cdn.nordigen.com/ais/ACTIVOBANK_ACTBPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'MONTEPIO_MPIOPTPL',
      name: 'Banco Montepio',
      bic: 'MPIOPTPL',
      logo: 'https://cdn.nordigen.com/ais/MONTEPIO_MPIOPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'CREDITO_AGRICOLA_CCCMPTPL',
      name: 'Crédito Agrícola',
      bic: 'CCCMPTPL',
      logo: 'https://cdn.nordigen.com/ais/CREDITO_AGRICOLA_CCCMPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'EUROBIC_BPNPPTPL',
      name: 'EuroBic',
      bic: 'BPNPPTPL',
      logo: 'https://cdn.nordigen.com/ais/EUROBIC_BPNPPTPL.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'ABANCA_CAABORR',
      name: 'ABANCA Portugal',
      bic: 'CAABORR',
      logo: 'https://cdn.nordigen.com/ais/ABANCA_CAABORR.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
    const NordigenInstitution(
      id: 'REVOLUT_REVOLT21',
      name: 'Revolut',
      bic: 'REVOLT21',
      logo: 'https://cdn.nordigen.com/ais/REVOLUT_REVOLT21.png',
      countries: ['PT'],
      transactionTotalDays: 90,
    ),
  ];

  // Store for mock requisitions
  final Map<String, _MockRequisition> _requisitions = {};
  int _requisitionCounter = 0;

  /// Initialize (no-op for mock)
  @override
  Future<void> initialize() async {
    debugPrint('MockNordigenService initialized (Demo Mode)');
  }

  /// Always "authenticated" in mock mode
  @override
  bool get hasValidToken => true;

  /// No-op authentication
  @override
  Future<void> authenticate() async {
    await Future.delayed(_networkDelay);
    debugPrint('Mock: Authentication simulated');
  }

  /// Get list of Portuguese banks
  @override
  Future<List<NordigenInstitution>> getPortugueseBanks() async {
    await Future.delayed(_networkDelay);
    debugPrint('Mock: Returning ${_mockBanks.length} Portuguese banks');
    return List.from(_mockBanks);
  }

  /// Get institution by ID
  @override
  Future<NordigenInstitution> getInstitution(String institutionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockBanks.firstWhere(
      (bank) => bank.id == institutionId,
      orElse: () => _mockBanks.first,
    );
  }

  /// Create mock agreement
  @override
  Future<NordigenAgreement> createAgreement({
    required String institutionId,
    int maxHistoricalDays = 90,
    int accessValidForDays = 90,
    List<String> accessScope = const ['balances', 'details', 'transactions'],
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return NordigenAgreement(
      id: 'mock_agreement_${DateTime.now().millisecondsSinceEpoch}',
      institutionId: institutionId,
      maxHistoricalDays: maxHistoricalDays,
      accessValidForDays: accessValidForDays,
      accessScope: accessScope,
      created: DateTime.now(),
    );
  }

  /// Create mock requisition
  @override
  Future<NordigenRequisition> createRequisition({
    required String institutionId,
    required String reference,
    String? agreementId,
    String? userLanguage,
  }) async {
    await Future.delayed(_networkDelay);

    _requisitionCounter++;
    final requisitionId = 'mock_req_$_requisitionCounter';

    // Generate mock account IDs
    final accountId1 = 'mock_acc_${DateTime.now().millisecondsSinceEpoch}';
    final accountId2 = 'mock_acc_${DateTime.now().millisecondsSinceEpoch + 1}';

    // Store the mock requisition
    _requisitions[requisitionId] = _MockRequisition(
      institutionId: institutionId,
      accountIds: [accountId1, accountId2],
      status: RequisitionStatus.created,
    );

    debugPrint('Mock: Created requisition $requisitionId for $institutionId');

    return NordigenRequisition(
      id: requisitionId,
      status: RequisitionStatus.created,
      link: 'bjbank://mock-auth/$requisitionId',
      accounts: [],
      institutionId: institutionId,
      reference: reference,
      created: DateTime.now(),
      agreementId: agreementId,
    );
  }

  /// Get requisition status (simulates successful authorization)
  @override
  Future<NordigenRequisition> getRequisition(String requisitionId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final mockReq = _requisitions[requisitionId];
    if (mockReq == null) {
      throw Exception('Requisition not found');
    }

    // Simulate that authorization was successful
    mockReq.status = RequisitionStatus.linked;

    return NordigenRequisition(
      id: requisitionId,
      status: RequisitionStatus.linked,
      link: null,
      accounts: mockReq.accountIds,
      institutionId: mockReq.institutionId,
      reference: 'mock_reference',
      created: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  }

  /// Delete requisition
  @override
  Future<void> deleteRequisition(String requisitionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _requisitions.remove(requisitionId);
    debugPrint('Mock: Deleted requisition $requisitionId');
  }

  /// Get mock account details
  @override
  Future<NordigenAccount> getAccountDetails(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Find which institution this account belongs to
    String? institutionId;
    for (var req in _requisitions.values) {
      if (req.accountIds.contains(accountId)) {
        institutionId = req.institutionId;
        break;
      }
    }

    // Generate a realistic Portuguese IBAN
    final iban = _generateMockIban();

    return NordigenAccount(
      id: accountId,
      iban: iban,
      institutionId: institutionId,
      ownerName: 'Demo User',
      currency: 'EUR',
      name: 'Conta à Ordem',
      product: 'Current Account',
      status: 'READY',
    );
  }

  /// Get mock account balances
  @override
  Future<List<NordigenBalance>> getAccountBalances(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Generate realistic random balance
    final balance = 1500.0 + (DateTime.now().millisecond % 5000);

    return [
      NordigenBalance(
        amount: balance,
        currency: 'EUR',
        balanceType: 'closingBooked',
        referenceDate: DateTime.now(),
      ),
      NordigenBalance(
        amount: balance + 50,
        currency: 'EUR',
        balanceType: 'expected',
        referenceDate: DateTime.now(),
      ),
    ];
  }

  /// Get primary balance
  @override
  Future<NordigenBalance?> getPrimaryBalance(String accountId) async {
    final balances = await getAccountBalances(accountId);
    if (balances.isEmpty) return null;
    return balances.firstWhere(
      (b) => b.balanceType == 'closingBooked',
      orElse: () => balances.first,
    );
  }

  /// Get mock transactions
  @override
  Future<List<NordigenTransaction>> getAccountTransactions(
    String accountId, {
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    await Future.delayed(_networkDelay);

    final now = DateTime.now();
    return [
      NordigenTransaction(
        transactionId: 'mock_tx_1',
        amount: -45.50,
        currency: 'EUR',
        bookingDate: now.subtract(const Duration(days: 1)),
        remittanceInformationUnstructured: 'Supermercado Continente',
        creditorName: 'Continente',
      ),
      NordigenTransaction(
        transactionId: 'mock_tx_2',
        amount: 1200.00,
        currency: 'EUR',
        bookingDate: now.subtract(const Duration(days: 3)),
        remittanceInformationUnstructured: 'Salário',
        debtorName: 'Empresa XYZ',
      ),
      NordigenTransaction(
        transactionId: 'mock_tx_3',
        amount: -85.00,
        currency: 'EUR',
        bookingDate: now.subtract(const Duration(days: 5)),
        remittanceInformationUnstructured: 'EDP - Fatura Eletricidade',
        creditorName: 'EDP',
      ),
      NordigenTransaction(
        transactionId: 'mock_tx_4',
        amount: -12.99,
        currency: 'EUR',
        bookingDate: now.subtract(const Duration(days: 7)),
        remittanceInformationUnstructured: 'Netflix',
        creditorName: 'Netflix',
      ),
    ];
  }

  /// Generate unique reference
  @override
  String generateReference(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'bjbank_demo_${userId}_$timestamp';
  }

  /// Generate mock Portuguese IBAN
  String _generateMockIban() {
    final now = DateTime.now();
    final accountNumber = (now.millisecondsSinceEpoch % 100000000000)
        .toString()
        .padLeft(11, '0');

    // Use a random bank code from Portuguese banks
    final bankCodes = ['0035', '0033', '0007', '0018', '0010', '0036'];
    final bankCode = bankCodes[now.second % bankCodes.length];

    // Simple check digit calculation (not real IBAN validation)
    final checkDigits = (98 - (now.millisecond % 97)).toString().padLeft(2, '0');

    return 'PT$checkDigits${bankCode}0001$accountNumber';
  }

  /// Clear tokens (no-op for mock)
  @override
  Future<void> clearTokens() async {
    debugPrint('Mock: Tokens cleared (no-op)');
  }
}

/// Internal class to track mock requisitions
class _MockRequisition {
  final String institutionId;
  final List<String> accountIds;
  RequisitionStatus status;

  _MockRequisition({
    required this.institutionId,
    required this.accountIds,
    required this.status,
  });
}
