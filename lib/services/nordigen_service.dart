import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/nordigen_config.dart';
import '../models/nordigen_models.dart';
import 'nordigen_service_interface.dart';

/// Nordigen/GoCardless Open Banking Service
///
/// Handles all communication with Nordigen Bank Account Data API
/// for PSD2-compliant bank connections in Portugal
class NordigenService implements INordigenService {
  NordigenService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: NordigenConfig.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ));

  final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'nordigen_access_token';
  static const String _tokenExpiryKey = 'nordigen_token_expiry';
  static const String _refreshTokenKey = 'nordigen_refresh_token';

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Initialize service and load cached token
  @override
  Future<void> initialize() async {
    try {
      _accessToken = await _secureStorage.read(key: _tokenKey);
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        _tokenExpiry = DateTime.tryParse(expiryStr);
      }
      debugPrint('NordigenService initialized');
    } catch (e) {
      debugPrint('Error initializing NordigenService: $e');
    }
  }

  /// Check if we have a valid token
  @override
  bool get hasValidToken {
    if (_accessToken == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Authenticate with Nordigen API
  /// POST /token/new/
  @override
  Future<void> authenticate() async {
    try {
      debugPrint('Authenticating with Nordigen API...');

      final response = await _dio.post(
        '/token/new/',
        data: {
          'secret_id': NordigenConfig.secretId,
          'secret_key': NordigenConfig.secretKey,
        },
      );

      if (response.statusCode == 200) {
        final token = NordigenToken.fromJson(response.data);
        _accessToken = token.accessToken;
        _tokenExpiry = token.accessExpiresAt;

        // Store tokens securely
        await _secureStorage.write(key: _tokenKey, value: _accessToken);
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: _tokenExpiry!.toIso8601String(),
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: token.refreshToken,
        );

        debugPrint('Nordigen authentication successful');
      } else {
        throw Exception('Authentication failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Nordigen authentication error: ${e.message}');
      rethrow;
    }
  }

  /// Refresh access token
  /// POST /token/refresh/
  Future<void> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        // No refresh token, need full authentication
        await authenticate();
        return;
      }

      final response = await _dio.post(
        '/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: response.data['access_expires'] ?? 86400),
        );

        await _secureStorage.write(key: _tokenKey, value: _accessToken);
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: _tokenExpiry!.toIso8601String(),
        );

        debugPrint('Nordigen token refreshed');
      } else {
        // Refresh failed, try full authentication
        await authenticate();
      }
    } catch (e) {
      debugPrint('Token refresh failed, re-authenticating: $e');
      await authenticate();
    }
  }

  /// Ensure we have a valid token before making API calls
  Future<void> _ensureAuthenticated() async {
    if (!hasValidToken) {
      if (_accessToken != null) {
        await refreshToken();
      } else {
        await authenticate();
      }
    }
  }

  /// Get authorization headers
  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ============== INSTITUTIONS ==============

  /// Get list of Portuguese banks
  /// GET /institutions/?country=pt
  @override
  Future<List<NordigenInstitution>> getPortugueseBanks() async {
    await _ensureAuthenticated();

    try {
      final response = await _dio.get(
        '/institutions/',
        queryParameters: {'country': NordigenConfig.countryCode},
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final banks = data
            .map((json) => NordigenInstitution.fromJson(json))
            .toList();

        // Sort by name
        banks.sort((a, b) => a.name.compareTo(b.name));

        debugPrint('Loaded ${banks.length} Portuguese banks');
        return banks;
      } else {
        throw Exception('Failed to load banks: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error loading banks: ${e.message}');
      rethrow;
    }
  }

  /// Get institution details by ID
  /// GET /institutions/{id}/
  @override
  Future<NordigenInstitution> getInstitution(String institutionId) async {
    await _ensureAuthenticated();

    try {
      final response = await _dio.get(
        '/institutions/$institutionId/',
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200) {
        return NordigenInstitution.fromJson(response.data);
      } else {
        throw Exception('Failed to load institution: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error loading institution: ${e.message}');
      rethrow;
    }
  }

  // ============== AGREEMENTS ==============

  /// Create end user agreement (required for PSD2 compliance)
  /// POST /agreements/enduser/
  @override
  Future<NordigenAgreement> createAgreement({
    required String institutionId,
    int maxHistoricalDays = 90,
    int accessValidForDays = 90,
    List<String> accessScope = const ['balances', 'details', 'transactions'],
  }) async {
    await _ensureAuthenticated();

    try {
      final response = await _dio.post(
        '/agreements/enduser/',
        data: {
          'institution_id': institutionId,
          'max_historical_days': maxHistoricalDays,
          'access_valid_for_days': accessValidForDays,
          'access_scope': accessScope,
        },
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return NordigenAgreement.fromJson(response.data);
      } else {
        throw Exception('Failed to create agreement: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error creating agreement: ${e.message}');
      rethrow;
    }
  }

  // ============== REQUISITIONS ==============

  /// Create requisition (bank connection request)
  /// POST /requisitions/
  @override
  Future<NordigenRequisition> createRequisition({
    required String institutionId,
    required String reference,
    String? agreementId,
    String? userLanguage,
  }) async {
    await _ensureAuthenticated();

    try {
      final data = {
        'institution_id': institutionId,
        'redirect': NordigenConfig.redirectUri,
        'reference': reference,
        'user_language': userLanguage ?? 'PT',
      };

      if (agreementId != null) {
        data['agreement'] = agreementId;
      }

      final response = await _dio.post(
        '/requisitions/',
        data: data,
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final requisition = NordigenRequisition.fromJson(response.data);
        debugPrint('Created requisition: ${requisition.id}');
        debugPrint('Authorization link: ${requisition.link}');
        return requisition;
      } else {
        throw Exception('Failed to create requisition: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error creating requisition: ${e.message}');
      rethrow;
    }
  }

  /// Get requisition status
  /// GET /requisitions/{id}/
  @override
  Future<NordigenRequisition> getRequisition(String requisitionId) async {
    await _ensureAuthenticated();

    try {
      final response = await _dio.get(
        '/requisitions/$requisitionId/',
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200) {
        return NordigenRequisition.fromJson(response.data);
      } else {
        throw Exception('Failed to get requisition: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error getting requisition: ${e.message}');
      rethrow;
    }
  }

  /// Delete requisition (disconnect bank)
  /// DELETE /requisitions/{id}/
  @override
  Future<void> deleteRequisition(String requisitionId) async {
    await _ensureAuthenticated();

    try {
      final response = await _dio.delete(
        '/requisitions/$requisitionId/',
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Requisition deleted: $requisitionId');
      } else {
        throw Exception('Failed to delete requisition: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error deleting requisition: ${e.message}');
      rethrow;
    }
  }

  // ============== ACCOUNTS ==============

  /// Get account details
  /// GET /accounts/{id}/details/
  @override
  Future<NordigenAccount> getAccountDetails(String accountId) async {
    await _ensureAuthenticated();

    try {
      final response = await _dio.get(
        '/accounts/$accountId/details/',
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200) {
        final account = NordigenAccount.fromJson({
          'id': accountId,
          ...response.data,
        });
        return account;
      } else {
        throw Exception('Failed to get account details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error getting account details: ${e.message}');
      rethrow;
    }
  }

  /// Get account metadata
  /// GET /accounts/{id}/
  Future<Map<String, dynamic>> getAccountMetadata(String accountId) async {
    await _ensureAuthenticated();

    try {
      final response = await _dio.get(
        '/accounts/$accountId/',
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get account metadata: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error getting account metadata: ${e.message}');
      rethrow;
    }
  }

  /// Get account balances
  /// GET /accounts/{id}/balances/
  @override
  Future<List<NordigenBalance>> getAccountBalances(String accountId) async {
    await _ensureAuthenticated();

    try {
      final response = await _dio.get(
        '/accounts/$accountId/balances/',
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200) {
        final balancesData = response.data['balances'] as List? ?? [];
        return balancesData
            .map((json) => NordigenBalance.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get balances: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error getting balances: ${e.message}');
      rethrow;
    }
  }

  /// Get primary balance (closingBooked or first available)
  @override
  Future<NordigenBalance?> getPrimaryBalance(String accountId) async {
    final balances = await getAccountBalances(accountId);
    if (balances.isEmpty) return null;

    // Prefer closingBooked balance
    final closingBooked = balances.firstWhere(
      (b) => b.balanceType == 'closingBooked',
      orElse: () => balances.first,
    );
    return closingBooked;
  }

  /// Get account transactions
  /// GET /accounts/{id}/transactions/
  @override
  Future<List<NordigenTransaction>> getAccountTransactions(
    String accountId, {
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    await _ensureAuthenticated();

    try {
      final queryParams = <String, dynamic>{};
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await _dio.get(
        '/accounts/$accountId/transactions/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200) {
        final transactions = <NordigenTransaction>[];

        // Parse booked transactions
        final bookedData =
            response.data['transactions']?['booked'] as List? ?? [];
        for (var json in bookedData) {
          transactions.add(NordigenTransaction.fromJson(json));
        }

        // Optionally parse pending transactions
        final pendingData =
            response.data['transactions']?['pending'] as List? ?? [];
        for (var json in pendingData) {
          transactions.add(NordigenTransaction.fromJson(json));
        }

        return transactions;
      } else {
        throw Exception('Failed to get transactions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error getting transactions: ${e.message}');
      rethrow;
    }
  }

  // ============== HELPERS ==============

  /// Generate unique reference for requisition
  @override
  String generateReference(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'bjbank_${userId}_$timestamp';
  }

  /// Clear stored tokens (for logout)
  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _tokenExpiry = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _tokenExpiryKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    debugPrint('Nordigen tokens cleared');
  }
}
