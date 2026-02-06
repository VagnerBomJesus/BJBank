/// Nordigen/GoCardless API Configuration
///
/// Get your credentials from: https://bankaccountdata.gocardless.com/
/// Free tier: 50 connections (sufficient for research/demo)
///
/// NOTE: If credentials are not available, the app will use MockNordigenService
/// for demonstration purposes.
class NordigenConfig {
  NordigenConfig._();

  /// Enable demo/mock mode (uses simulated data)
  /// Set to false and provide real credentials for production
  static const bool useMockService = true;

  /// Nordigen API Base URL
  static const String baseUrl = 'https://bankaccountdata.gocardless.com/api/v2';

  /// Secret ID from GoCardless Bank Account Data
  /// In production, use environment variables or Firebase Remote Config
  static const String secretId = 'YOUR_SECRET_ID';

  /// Secret Key from GoCardless Bank Account Data
  /// In production, use environment variables or Firebase Remote Config
  static const String secretKey = 'YOUR_SECRET_KEY';

  /// Check if real credentials are configured
  static bool get hasRealCredentials =>
      secretId != 'YOUR_SECRET_ID' && secretKey != 'YOUR_SECRET_KEY';

  /// Redirect URI for OAuth callback (deep link)
  static const String redirectUri = 'bjbank://callback';

  /// Country code for Portuguese banks
  static const String countryCode = 'PT';

  /// Access token validity duration (24 hours)
  static const Duration tokenValidity = Duration(hours: 24);

  /// Bank consent validity (90 days as per PSD2)
  static const Duration consentValidity = Duration(days: 90);

  /// Maximum days of transaction history
  static const int maxTransactionDays = 90;

  /// Supported Portuguese Banks (examples)
  static const List<String> popularBanks = [
    'CAIXA_GERAL_DE_DEPOSITOS_CGDIPTPL',
    'MILLENNIUM_BCP_BCOMPTPL',
    'NOVO_BANCO_NOVBPTPL',
    'SANTANDER_TOTTA_TOTAPTPL',
    'BPI_BBPIPTPL',
    'BANKINTER_BKBKPTPL',
    'ACTIVOBANK_ACTBPTPL',
    'MONTEPIO_MPIOPTPL',
  ];
}
