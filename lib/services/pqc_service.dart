// ============================================================================
// pqc_service.dart — STUB POS-MIGRACAO
// ============================================================================
//
// O ficheiro original dependia de `package:oqs` (liboqs FFI) que nao carrega
// no Android. Apos migracao para Supabase, a cripto pos-quantica REAL e
// executada no servidor (Edge Functions `pqc_bootstrap`, `pqc_handshake`,
// `pqc_handshake_flutter`, `flutter_sign_transfer`, `verify_dsa`,
// `executar_transferencia`) — ver `supabase_pqc_handshake_service.dart` e
// `supabase_transfer_service.dart`.
//
// Este ficheiro fica como STUB para nao quebrar imports/screens que ainda
// referenciam PqcService, PqcAlgorithm, PqcKeyPair, PqcSignature. As suas
// operacoes devolvem placeholders deterministicos suficientes para o ecra
// de benchmark e tooltips/labels — NAO usar em transferencias reais (essas
// usam o pipeline Supabase com cripto verdadeira).
// ============================================================================

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/pqc_metrics_model.dart';

/// Algoritmos PQC suportados (nominais).
enum PqcAlgorithm {
  dilithium2,
  dilithium3,
  dilithium5,
  kyber512,
  kyber768,
  kyber1024,
}

/// Par de chaves PQC.
class PqcKeyPair {
  final String publicKey;
  final String privateKey;
  final PqcAlgorithm algorithm;
  final DateTime createdAt;

  PqcKeyPair({
    required this.publicKey,
    required this.privateKey,
    required this.algorithm,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'privateKey': privateKey,
        'algorithm': algorithm.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PqcKeyPair.fromJson(Map<String, dynamic> json) => PqcKeyPair(
        publicKey: json['publicKey'],
        privateKey: json['privateKey'],
        algorithm: PqcAlgorithm.values.byName(json['algorithm']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// Resultado de assinatura PQC.
class PqcSignature {
  final String signature;
  final String data;
  final PqcAlgorithm algorithm;
  final DateTime timestamp;

  PqcSignature({
    required this.signature,
    required this.data,
    required this.algorithm,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String toBase64() => base64Encode(utf8.encode(jsonEncode({
        'sig': signature,
        'data': data,
        'alg': algorithm.name,
        'ts': timestamp.toIso8601String(),
      })));

  factory PqcSignature.fromBase64(String encoded) {
    final json = jsonDecode(utf8.decode(base64Decode(encoded)));
    return PqcSignature(
      signature: json['sig'],
      data: json['data'],
      algorithm: PqcAlgorithm.values.byName(json['alg']),
      timestamp: DateTime.parse(json['ts']),
    );
  }
}

/// Servico PQC stub.
///
/// Para operacoes reais ver:
///   - `SupabasePqcHandshakeService` (handshake ML-KEM + ML-DSA via servidor)
///   - `SupabaseTransferService` (assinatura ML-DSA real + AES-GCM)
class PqcService {
  static final PqcService _instance = PqcService._internal();
  factory PqcService() => _instance;
  PqcService._internal();

  /// Mantido para compatibilidade com main.dart antigo; sempre `false`.
  static bool isLiboqsAvailable = false;

  static PqcImplementationMode get currentMode =>
      PqcImplementationMode.simulation;

  Future<void> initialize() async {
    debugPrint('PqcService stub initialized (cripto real no servidor)');
  }

  PqcKeyPair? _cachedKeyPair;

  /// Gera par "PQC" — bytes aleatorios com tamanhos NIST.
  Future<PqcKeyPair> generateKeyPair([PqcAlgorithm alg = PqcAlgorithm.dilithium3]) async {
    final r = Random.secure();
    final sizes = _sizes(alg);
    final kp = PqcKeyPair(
      publicKey: base64Encode(List.generate(sizes.$1, (_) => r.nextInt(256))),
      privateKey: base64Encode(List.generate(sizes.$2, (_) => r.nextInt(256))),
      algorithm: alg,
    );
    _cachedKeyPair = kp;
    return kp;
  }

  /// Devolve o par cacheado (gera se ainda nao houver).
  Future<PqcKeyPair> getKeyPair([PqcAlgorithm alg = PqcAlgorithm.dilithium3]) async {
    return _cachedKeyPair ??= await generateKeyPair(alg);
  }

  /// Assina uma transferencia (stub).
  /// Para assinatura REAL, ver SupabaseTransferService.executar().
  Future<PqcSignature> signTransfer({
    required String senderId,
    required String receiverId,
    required double amount,
    required String description,
    PqcAlgorithm alg = PqcAlgorithm.dilithium3,
  }) async {
    final kp = await getKeyPair(alg);
    final json = jsonEncode({
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    });
    return sign(json, kp, algorithm: alg);
  }

  /// Tamanho da chave publica para um algoritmo.
  int getPublicKeySize(PqcAlgorithm alg) => _sizes(alg).$1;

  /// Tamanho da chave privada para um algoritmo.
  int getPrivateKeySize(PqcAlgorithm alg) => _sizes(alg).$2;

  /// Tamanho da assinatura (so para algoritmos de assinatura).
  int getSignatureSize(PqcAlgorithm alg) => _sigSize(alg);

  /// Tamanho do ciphertext (KEM).
  int getCiphertextSize(PqcAlgorithm alg) {
    switch (alg) {
      case PqcAlgorithm.kyber512:
        return 768;
      case PqcAlgorithm.kyber768:
        return 1088; // ML-KEM-768
      case PqcAlgorithm.kyber1024:
        return 1568;
      default:
        return 0;
    }
  }

  /// Dados comparativos com cripto classica para o ecra de benchmark.
  /// Devolve um mapa para preservar o uso `.values.toList()` no benchmark.
  static Map<String, ClassicalComparisonData> getNistComparisonData() {
    return {
      'RSA-2048': const ClassicalComparisonData(
        algorithm: 'RSA-2048',
        type: 'signature',
        publicKeySizeBytes: 256,
        privateKeySizeBytes: 1216,
        signatureSizeBytes: 256,
        keyGenCycles: 100000000,
        signCycles: 5000000,
        verifyCycles: 150000,
        quantumResistant: false,
        nistSecurityLevel: 1,
      ),
      'ECDSA-P256': const ClassicalComparisonData(
        algorithm: 'ECDSA-P256',
        type: 'signature',
        publicKeySizeBytes: 64,
        privateKeySizeBytes: 32,
        signatureSizeBytes: 64,
        keyGenCycles: 1000000,
        signCycles: 600000,
        verifyCycles: 2000000,
        quantumResistant: false,
        nistSecurityLevel: 1,
      ),
      'Ed25519': const ClassicalComparisonData(
        algorithm: 'Ed25519',
        type: 'signature',
        publicKeySizeBytes: 32,
        privateKeySizeBytes: 32,
        signatureSizeBytes: 64,
        keyGenCycles: 100000,
        signCycles: 100000,
        verifyCycles: 300000,
        quantumResistant: false,
        nistSecurityLevel: 1,
      ),
      'X25519-ECDH': const ClassicalComparisonData(
        algorithm: 'X25519-ECDH',
        type: 'kem',
        publicKeySizeBytes: 32,
        privateKeySizeBytes: 32,
        signatureSizeBytes: 32,
        keyGenCycles: 100000,
        signCycles: 150000,
        verifyCycles: 150000,
        quantumResistant: false,
        nistSecurityLevel: 1,
      ),
    };
  }

  /// Assina (stub) — usa em ecras de benchmark/teste.
  /// Para assinatura real em transferencias, ver `SupabaseTransferService`.
  Future<PqcSignature> sign(
    String data,
    PqcKeyPair keyPair, {
    PqcAlgorithm? algorithm,
  }) async {
    final alg = algorithm ?? keyPair.algorithm;
    final r = Random.secure();
    final sigLen = _sigSize(alg);
    return PqcSignature(
      signature: base64Encode(List.generate(sigLen, (_) => r.nextInt(256))),
      data: data,
      algorithm: alg,
    );
  }

  /// Verifica (stub) — sempre true se o algoritmo da assinatura bate.
  Future<bool> verify(
    PqcSignature signature,
    String publicKey, {
    PqcAlgorithm? algorithm,
  }) async {
    return signature.algorithm == (algorithm ?? signature.algorithm);
  }

  // Tamanhos nominais NIST FIPS 203/204
  (int, int) _sizes(PqcAlgorithm alg) {
    switch (alg) {
      case PqcAlgorithm.dilithium2:
        return (1312, 2528);
      case PqcAlgorithm.dilithium3:
        return (1952, 4000); // ML-DSA-65
      case PqcAlgorithm.dilithium5:
        return (2592, 4864);
      case PqcAlgorithm.kyber512:
        return (800, 1632);
      case PqcAlgorithm.kyber768:
        return (1184, 2400); // ML-KEM-768
      case PqcAlgorithm.kyber1024:
        return (1568, 3168);
    }
  }

  int _sigSize(PqcAlgorithm alg) {
    switch (alg) {
      case PqcAlgorithm.dilithium2:
        return 2420;
      case PqcAlgorithm.dilithium3:
        return 3293; // ML-DSA-65
      case PqcAlgorithm.dilithium5:
        return 4595;
      default:
        return 0; // KEM nao assina
    }
  }
}

/// Handshake hibrido — STUB. Real em `SupabasePqcHandshakeService`.
class PqcHybridHandshake {
  Future<PqcHybridHandshakeResult> execute({
    PqcAlgorithm kemAlgorithm = PqcAlgorithm.kyber768,
    PqcAlgorithm sigAlgorithm = PqcAlgorithm.dilithium3,
  }) async {
    final sw = Stopwatch()..start();
    // Simula latencia tipica do handshake hibrido para o ecra de benchmark.
    await Future<void>.delayed(const Duration(milliseconds: 12));
    sw.stop();
    final pqc = PqcService();
    return PqcHybridHandshakeResult(
      clientId: 'flutter-client',
      serverId: 'bjbank-server',
      kemAlgorithm: kemAlgorithm.name,
      classicalPhaseMs: 2.5,
      kemPhaseMs: 7.0,
      kdfPhaseMs: 2.5,
      totalMs: sw.elapsedMilliseconds.toDouble(),
      kemPublicKeySizeBytes: pqc.getPublicKeySize(kemAlgorithm),
      kemCiphertextSizeBytes: pqc.getCiphertextSize(kemAlgorithm),
      combinedSecretSizeBytes: 64,
      mode: PqcImplementationMode.simulation,
      executedAt: DateTime.now(),
    );
  }
}
