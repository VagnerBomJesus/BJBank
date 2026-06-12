// ============================================================================
// device_pqc_onboarding_service.dart
//
// Garante que o utilizador autenticado tem uma chave ML-DSA-65 gerada
// localmente (DevicePqcService) e registada server-side via
// RPC public.register_client_pubkey.
//
// Chamado em:
//   1. Pós-signup (auto-onboarding do utilizador novo).
//   2. Pós-login (migração de utilizadores legados: Vagner/Maude
//      que ainda têm chave server-managed em flutter_client_keys).
//
// Resolve Problema 1 de docs/PQC_REMAINING_CRITICAL_ISSUES.md.
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_pqc_service.dart';
import 'supabase_config.dart';

class DevicePqcOnboardingService {
  static final DevicePqcOnboardingService _instance =
      DevicePqcOnboardingService._internal();
  factory DevicePqcOnboardingService() => _instance;
  DevicePqcOnboardingService._internal();

  final DevicePqcService _pqc = DevicePqcService();
  SupabaseClient get _sb => SupabaseConfig.client;

  /// Garante que existe chave local + registada no servidor.
  /// Idempotente: pode ser chamado a cada login.
  Future<OnboardingResult> ensureKey() async {
    if (!await _pqc.isAvailable()) {
      return OnboardingResult.unavailable(
        'Plugin PQC nativo indisponível (iOS sem implementação Swift)',
      );
    }

    final user = _sb.auth.currentUser;
    if (user == null) {
      return OnboardingResult.error('Sem utilizador autenticado');
    }

    // Caso 1: já tem chave local. Verificar se está sincronizada com servidor.
    if (await _pqc.hasKey()) {
      final localPub = base64Encode(await _pqc.getPublicKey());
      final remotePub = await _fetchRegisteredPubkey();
      if (remotePub == localPub) {
        return OnboardingResult.alreadyOk();
      }
      // Local existe mas servidor não tem (raro) ou tem diferente
      // (utilizador reinstalou). Registar a local.
      await _registerOnServer(localPub);
      return OnboardingResult.resync();
    }

    // Caso 2: gerar nova chave local.
    final pubBytes = await _pqc.generateDsaAndGetPublic();
    final pubBase64 = base64Encode(pubBytes);
    await _registerOnServer(pubBase64);

    debugPrint(
      'PQC onboarding completo: par ML-DSA-65 gerado localmente '
      '(pub ${pubBytes.length}B) e registado server-side',
    );
    return OnboardingResult.created();
  }

  Future<String?> _fetchRegisteredPubkey() async {
    final user = _sb.auth.currentUser;
    if (user == null) return null;
    try {
      final rows = await _sb.rpc('pubkey_for_user', params: {
        'p_user_id': user.id,
      });
      if (rows is List && rows.isNotEmpty) {
        return rows.first['public_key_base64'] as String?;
      }
    } catch (e) {
      debugPrint('pubkey_for_user falhou: $e');
    }
    return null;
  }

  Future<void> _registerOnServer(String publicKeyBase64) async {
    await _sb.rpc('register_client_pubkey', params: {
      'p_public_key_base64': publicKeyBase64,
    });
  }

  /// Apaga a chave local (logout completo). NÃO revoga server-side
  /// — utilizador pode voltar a fazer login no mesmo dispositivo.
  Future<void> clearLocal() async {
    if (await _pqc.isAvailable()) {
      await _pqc.revokeKey();
    }
  }
}

class OnboardingResult {
  final OnboardingStatus status;
  final String? detail;
  const OnboardingResult._(this.status, [this.detail]);

  factory OnboardingResult.created() =>
      const OnboardingResult._(OnboardingStatus.created);
  factory OnboardingResult.alreadyOk() =>
      const OnboardingResult._(OnboardingStatus.alreadyOk);
  factory OnboardingResult.resync() =>
      const OnboardingResult._(OnboardingStatus.resync);
  factory OnboardingResult.unavailable(String detail) =>
      OnboardingResult._(OnboardingStatus.unavailable, detail);
  factory OnboardingResult.error(String detail) =>
      OnboardingResult._(OnboardingStatus.error, detail);

  bool get isOk => status == OnboardingStatus.created ||
      status == OnboardingStatus.alreadyOk ||
      status == OnboardingStatus.resync;
}

enum OnboardingStatus { created, alreadyOk, resync, unavailable, error }
