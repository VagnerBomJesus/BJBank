// Nordigen API Models
// Models for GoCardless Bank Account Data API

/// Bank Institution from Nordigen
class NordigenInstitution {
  const NordigenInstitution({
    required this.id,
    required this.name,
    required this.bic,
    this.logo,
    this.countries = const [],
    this.transactionTotalDays = 90,
    this.maxHistoricalDays = 730,
  });

  /// Unique institution identifier (e.g., 'CAIXA_GERAL_DE_DEPOSITOS_CGDIPTPL')
  final String id;

  /// Display name (e.g., 'Caixa Geral de Depósitos')
  final String name;

  /// BIC/SWIFT code
  final String bic;

  /// Logo URL
  final String? logo;

  /// Supported countries
  final List<String> countries;

  /// Days of transaction history available
  final int transactionTotalDays;

  /// Maximum days of historical data
  final int maxHistoricalDays;

  factory NordigenInstitution.fromJson(Map<String, dynamic> json) {
    return NordigenInstitution(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bic: json['bic'] ?? '',
      logo: json['logo'],
      countries: (json['countries'] as List?)?.cast<String>() ?? [],
      transactionTotalDays: json['transaction_total_days'] ?? 90,
      maxHistoricalDays: json['max_historical_days'] ?? 730,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bic': bic,
        'logo': logo,
        'countries': countries,
        'transaction_total_days': transactionTotalDays,
        'max_historical_days': maxHistoricalDays,
      };
}

/// Requisition Status
enum RequisitionStatus {
  created,
  linked,
  expired,
  rejected,
  suspended,
  unknown,
}

/// Nordigen Requisition (Bank Connection Request)
class NordigenRequisition {
  const NordigenRequisition({
    required this.id,
    required this.status,
    this.link,
    this.accounts = const [],
    this.institutionId,
    this.reference,
    this.created,
    this.agreementId,
  });

  /// Unique requisition ID
  final String id;

  /// Current status
  final RequisitionStatus status;

  /// Authorization URL for user to grant access
  final String? link;

  /// List of account IDs after successful authorization
  final List<String> accounts;

  /// Institution ID this requisition is for
  final String? institutionId;

  /// Client-provided reference
  final String? reference;

  /// Creation timestamp
  final DateTime? created;

  /// Agreement ID
  final String? agreementId;

  factory NordigenRequisition.fromJson(Map<String, dynamic> json) {
    return NordigenRequisition(
      id: json['id'] ?? '',
      status: _parseStatus(json['status']),
      link: json['link'],
      accounts: (json['accounts'] as List?)?.cast<String>() ?? [],
      institutionId: json['institution_id'],
      reference: json['reference'],
      created: json['created'] != null
          ? DateTime.tryParse(json['created'])
          : null,
      agreementId: json['agreement'],
    );
  }

  static RequisitionStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'CR':
      case 'CREATED':
        return RequisitionStatus.created;
      case 'LN':
      case 'LINKED':
        return RequisitionStatus.linked;
      case 'EX':
      case 'EXPIRED':
        return RequisitionStatus.expired;
      case 'RJ':
      case 'REJECTED':
        return RequisitionStatus.rejected;
      case 'SU':
      case 'SUSPENDED':
        return RequisitionStatus.suspended;
      default:
        return RequisitionStatus.unknown;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        'link': link,
        'accounts': accounts,
        'institution_id': institutionId,
        'reference': reference,
        'created': created?.toIso8601String(),
        'agreement': agreementId,
      };

  bool get isLinked => status == RequisitionStatus.linked;
  bool get isPending => status == RequisitionStatus.created;
  bool get hasAccounts => accounts.isNotEmpty;
}

/// Nordigen Account Details
class NordigenAccount {
  const NordigenAccount({
    required this.id,
    this.iban,
    this.institutionId,
    this.ownerName,
    this.currency,
    this.name,
    this.product,
    this.resourceId,
    this.status,
  });

  /// Nordigen account ID
  final String id;

  /// IBAN
  final String? iban;

  /// Institution ID
  final String? institutionId;

  /// Account owner name
  final String? ownerName;

  /// Currency code (EUR)
  final String? currency;

  /// Account name/alias
  final String? name;

  /// Product name
  final String? product;

  /// Bank's internal resource ID
  final String? resourceId;

  /// Account status
  final String? status;

  factory NordigenAccount.fromJson(Map<String, dynamic> json) {
    // Handle nested 'account' object from details endpoint
    final accountData = json['account'] ?? json;

    return NordigenAccount(
      id: json['id'] ?? accountData['id'] ?? '',
      iban: accountData['iban'],
      institutionId: json['institution_id'],
      ownerName: accountData['ownerName'] ?? accountData['owner_name'],
      currency: accountData['currency'],
      name: accountData['name'],
      product: accountData['product'],
      resourceId: accountData['resourceId'] ?? accountData['resource_id'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'iban': iban,
        'institution_id': institutionId,
        'ownerName': ownerName,
        'currency': currency,
        'name': name,
        'product': product,
        'resourceId': resourceId,
        'status': status,
      };

  /// Get masked IBAN for display
  String get maskedIban {
    if (iban == null || iban!.length < 8) return iban ?? '';
    return '${iban!.substring(0, 4)} **** **** ${iban!.substring(iban!.length - 4)}';
  }
}

/// Nordigen Balance
class NordigenBalance {
  const NordigenBalance({
    required this.amount,
    required this.currency,
    this.balanceType,
    this.referenceDate,
  });

  /// Balance amount
  final double amount;

  /// Currency code
  final String currency;

  /// Balance type (e.g., 'closingBooked', 'expected')
  final String? balanceType;

  /// Reference date
  final DateTime? referenceDate;

  factory NordigenBalance.fromJson(Map<String, dynamic> json) {
    final balanceAmount = json['balanceAmount'] ?? json;
    return NordigenBalance(
      amount: double.tryParse(balanceAmount['amount']?.toString() ?? '0') ?? 0,
      currency: balanceAmount['currency'] ?? 'EUR',
      balanceType: json['balanceType'],
      referenceDate: json['referenceDate'] != null
          ? DateTime.tryParse(json['referenceDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'balanceAmount': {
          'amount': amount.toString(),
          'currency': currency,
        },
        'balanceType': balanceType,
        'referenceDate': referenceDate?.toIso8601String(),
      };

  /// Format balance for display
  String get formattedAmount {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '€$intPart,${parts[1]}';
  }
}

/// Nordigen Transaction
class NordigenTransaction {
  const NordigenTransaction({
    required this.transactionId,
    required this.amount,
    required this.currency,
    this.bookingDate,
    this.valueDate,
    this.remittanceInformationUnstructured,
    this.creditorName,
    this.creditorAccount,
    this.debtorName,
    this.debtorAccount,
  });

  final String transactionId;
  final double amount;
  final String currency;
  final DateTime? bookingDate;
  final DateTime? valueDate;
  final String? remittanceInformationUnstructured;
  final String? creditorName;
  final String? creditorAccount;
  final String? debtorName;
  final String? debtorAccount;

  factory NordigenTransaction.fromJson(Map<String, dynamic> json) {
    final transactionAmount = json['transactionAmount'] ?? {};
    return NordigenTransaction(
      transactionId: json['transactionId'] ?? json['internalTransactionId'] ?? '',
      amount: double.tryParse(transactionAmount['amount']?.toString() ?? '0') ?? 0,
      currency: transactionAmount['currency'] ?? 'EUR',
      bookingDate: json['bookingDate'] != null
          ? DateTime.tryParse(json['bookingDate'])
          : null,
      valueDate: json['valueDate'] != null
          ? DateTime.tryParse(json['valueDate'])
          : null,
      remittanceInformationUnstructured: json['remittanceInformationUnstructured'],
      creditorName: json['creditorName'],
      creditorAccount: json['creditorAccount']?['iban'],
      debtorName: json['debtorName'],
      debtorAccount: json['debtorAccount']?['iban'],
    );
  }

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  String get description {
    return remittanceInformationUnstructured ??
           creditorName ??
           debtorName ??
           'Transação';
  }
}

/// Nordigen API Token Response
class NordigenToken {
  const NordigenToken({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpires,
    required this.refreshExpires,
  });

  final String accessToken;
  final String refreshToken;
  final int accessExpires;
  final int refreshExpires;

  factory NordigenToken.fromJson(Map<String, dynamic> json) {
    return NordigenToken(
      accessToken: json['access'] ?? '',
      refreshToken: json['refresh'] ?? '',
      accessExpires: json['access_expires'] ?? 86400,
      refreshExpires: json['refresh_expires'] ?? 2592000,
    );
  }

  DateTime get accessExpiresAt =>
      DateTime.now().add(Duration(seconds: accessExpires));

  DateTime get refreshExpiresAt =>
      DateTime.now().add(Duration(seconds: refreshExpires));
}

/// End User Agreement for PSD2 compliance
class NordigenAgreement {
  const NordigenAgreement({
    required this.id,
    required this.institutionId,
    this.maxHistoricalDays = 90,
    this.accessValidForDays = 90,
    this.accessScope = const ['balances', 'details', 'transactions'],
    this.accepted,
    this.created,
  });

  final String id;
  final String institutionId;
  final int maxHistoricalDays;
  final int accessValidForDays;
  final List<String> accessScope;
  final DateTime? accepted;
  final DateTime? created;

  factory NordigenAgreement.fromJson(Map<String, dynamic> json) {
    return NordigenAgreement(
      id: json['id'] ?? '',
      institutionId: json['institution_id'] ?? '',
      maxHistoricalDays: json['max_historical_days'] ?? 90,
      accessValidForDays: json['access_valid_for_days'] ?? 90,
      accessScope: (json['access_scope'] as List?)?.cast<String>() ??
                   ['balances', 'details', 'transactions'],
      accepted: json['accepted'] != null
          ? DateTime.tryParse(json['accepted'])
          : null,
      created: json['created'] != null
          ? DateTime.tryParse(json['created'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'institution_id': institutionId,
        'max_historical_days': maxHistoricalDays,
        'access_valid_for_days': accessValidForDays,
        'access_scope': accessScope,
      };
}
