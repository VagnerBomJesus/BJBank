// ============================================================================
// device_pqc_service.dart — bridge para PqcPlugin.kt (Android).
//
// Plugin nativo Kotlin com BouncyCastle 1.78+ implementa ML-DSA-65
// (FIPS 204) e ML-KEM-768 (FIPS 203). Privada do utilizador vive em
// EncryptedSharedPreferences (backed pelo AndroidKeyStore — StrongBox/TEE
// quando disponível). NUNCA sai do dispositivo.
//
// iOS: ainda não implementado. `isAvailable` retorna false e o
// SupabaseTransferService faz fallback para o pipeline server-managed.
//
// Ver docs/PQC_REMAINING_CRITICAL_ISSUES.md.
// ============================================================================

import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceKemEncapsulation {
  final Uint8List ciphertext;    // ML-KEM-768 = 1088 bytes
  final Uint8List sharedSecret;  // 32 bytes
  const DeviceKemEncapsulation({
    required this.ciphertext,
    required this.sharedSecret,
  });
}

/// Acesso a primitivas PQC nativas. Singleton.
class DevicePqcService {
  static final DevicePqcService _instance = DevicePqcService._internal();
  factory DevicePqcService() => _instance;
  DevicePqcService._internal();

  static const MethodChannel _channel = MethodChannel('com.bjbank.ipg/pqc');

  bool? _available;

  /// True se o plugin nativo está registado e responde. Cached.
  /// Em iOS retorna false (TODO Swift plugin).
  Future<bool> isAvailable() async {
    if (_available != null) return _available!;
    if (!Platform.isAndroid) {
      _available = false;
      return false;
    }
    try {
      _available = await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (e) {
      debugPrint('DevicePqcService.isAvailable falhou: $e');
      _available = false;
    }
    return _available!;
  }

  /// True se já existe chave ML-DSA gerada para este dispositivo.
  Future<bool> hasKey() async {
    return await _channel.invokeMethod<bool>('hasKey') ?? false;
  }

  /// Gera novo par ML-DSA-65 no dispositivo. Privada guardada em
  /// EncryptedSharedPreferences (Keystore-backed). Devolve a pública
  /// (1952 bytes) que o cliente envia para o servidor via
  /// RPC register_client_pubkey.
  Future<Uint8List> generateDsaAndGetPublic() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('generateDsa');
    if (result == null) {
      throw StateError('generateDsa retornou null');
    }
    return result['publicKey'] as Uint8List;
  }

  /// Devolve a pubkey ML-DSA-65 ativa (1952 bytes). Falha se ainda não
  /// foi gerada — chamar generateDsaAndGetPublic primeiro.
  Future<Uint8List> getPublicKey() async {
    final pub = await _channel.invokeMethod<Uint8List>('getPublicKey');
    if (pub == null) throw StateError('Nenhuma pubkey disponível');
    return pub;
  }

  /// Assina [message] localmente com a privada do dispositivo.
  /// A privada NUNCA sai do plugin. Resultado: assinatura ML-DSA-65 (~3309 bytes).
  Future<Uint8List> signDsa(Uint8List message) async {
    final sig = await _channel.invokeMethod<Uint8List>('signDsa', {
      'message': message,
    });
    if (sig == null) throw StateError('signDsa retornou null');
    return sig;
  }

  /// Verifica localmente uma assinatura ML-DSA-65. Substitui a chamada
  /// `verify_dsa` ao servidor (trust circular).
  Future<bool> verifyDsa({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  }) async {
    final ok = await _channel.invokeMethod<bool>('verifyDsa', {
      'publicKey': publicKey,
      'message': message,
      'signature': signature,
    });
    return ok ?? false;
  }

  /// Encapsula ML-KEM-768 contra a pubkey do servidor (1184 bytes).
  /// shared_secret fica só no dispositivo; só o ciphertext (1088 bytes)
  /// é enviado ao servidor, que decapsula com a sua privada para
  /// recuperar o mesmo shared_secret. Garante PFS pós-quântico real.
  Future<DeviceKemEncapsulation> kemEncapsulate(
    Uint8List serverKemPublicKey,
  ) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'kemEncapsulate',
      {'serverPubKey': serverKemPublicKey},
    );
    if (result == null) throw StateError('kemEncapsulate retornou null');
    return DeviceKemEncapsulation(
      ciphertext: result['ciphertext'] as Uint8List,
      sharedSecret: result['sharedSecret'] as Uint8List,
    );
  }

  /// Revoga a chave atual (apaga do storage). Usado em logout completo.
  Future<void> revokeKey() async {
    await _channel.invokeMethod<bool>('revokeKey');
    _available = null;
  }

  // ─── SLH-DSA (FIPS 205) ────────────────────────────────────────────
  // Segunda assinatura para defesa em profundidade. Hash-based — não
  // depende de assunções lattice.

  /// Gera par SLH-DSA-SHAKE-128f. Pub ~32B, Priv ~64B, Sig ~17KB.
  Future<Map<String, Uint8List>> slhDsaKeygen() async {
    final r = await _channel.invokeMapMethod<String, dynamic>('slhDsaKeygen');
    if (r == null) throw StateError('slhDsaKeygen retornou null');
    return {
      'publicKey': r['publicKey'] as Uint8List,
      'privateKey': r['privateKey'] as Uint8List,
    };
  }

  Future<Uint8List> slhDsaSign(Uint8List privateKey, Uint8List message) async {
    final sig = await _channel.invokeMethod<Uint8List>('slhDsaSign', {
      'privateKey': privateKey,
      'message': message,
    });
    if (sig == null) throw StateError('slhDsaSign retornou null');
    return sig;
  }

  Future<bool> slhDsaVerify({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  }) async {
    return await _channel.invokeMethod<bool>('slhDsaVerify', {
      'publicKey': publicKey,
      'message': message,
      'signature': signature,
    }) ?? false;
  }

  // ─── X25519 + Hybrid ───────────────────────────────────────────────

  /// Gera par X25519 (32B pub, 32B priv) para Hybrid KEM.
  Future<Map<String, Uint8List>> x25519Generate() async {
    final r = await _channel.invokeMapMethod<String, dynamic>('x25519Generate');
    if (r == null) throw StateError('x25519Generate retornou null');
    return {
      'publicKey': r['publicKey'] as Uint8List,
      'privateKey': r['privateKey'] as Uint8List,
    };
  }

  /// Faz Diffie-Hellman X25519 — devolve shared secret 32B.
  Future<Uint8List> x25519Agree({
    required Uint8List privateKey,
    required Uint8List peerPublicKey,
  }) async {
    final ss = await _channel.invokeMethod<Uint8List>('x25519Agree', {
      'privateKey': privateKey,
      'peerPublicKey': peerPublicKey,
    });
    if (ss == null) throw StateError('x25519Agree retornou null');
    return ss;
  }

  /// Hybrid X25519 + ML-KEM-768. Deriva chave final via HKDF combinando
  /// ambos os shared secrets. Segurança = max(clássico, PQC).
  /// NIST RFC 9420 recomendação de transição.
  Future<Uint8List> hybridDerive({
    required Uint8List ssX25519,
    required Uint8List ssKyber,
    required Uint8List info,
    int length = 32,
  }) async {
    final out = await _channel.invokeMethod<Uint8List>('hybridDerive', {
      'ssX25519': ssX25519,
      'ssKyber': ssKyber,
      'info': info,
      'length': length,
    });
    if (out == null) throw StateError('hybridDerive retornou null');
    return out;
  }

  // ─── Benchmark on-device ───────────────────────────────────────────

  /// Mede P50/P95/P99 em nanosegundos para ML-DSA-65 (keygen/sign/verify),
  /// ML-KEM-768 (encap), SLH-DSA (sign) e X25519 (agree).
  /// Material empírico para tese.
  Future<Map<String, dynamic>> runBenchmark({int iterations = 100}) async {
    final r = await _channel.invokeMapMethod<String, dynamic>('benchmark', {
      'iterations': iterations,
    });
    if (r == null) throw StateError('benchmark retornou null');
    return Map<String, dynamic>.from(r);
  }

  /// Mede ECDSA-P256 (keygen/sign/verify) e ECDH-P256 (keygen+agree)
  /// usando BouncyCastle 1.80 NATIVO — mesma runtime do benchmark PQC.
  /// Permite comparação fair vs `runBenchmark` (mesmo JIT/JVM, mesma
  /// implementação BC). Material crítico para o capítulo experimental
  /// da tese — sem isto, ML-DSA vs ECDSA mistura algoritmo+runtime.
  Future<Map<String, dynamic>> runClassicBenchmark({int iterations = 100}) async {
    final r = await _channel.invokeMapMethod<String, dynamic>(
      'classicBenchmark',
      {'iterations': iterations},
    );
    if (r == null) throw StateError('classicBenchmark retornou null');
    return Map<String, dynamic>.from(r);
  }

  @visibleForTesting
  static MethodChannel get channel => _channel;
}
