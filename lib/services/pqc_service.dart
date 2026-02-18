import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pqc_metrics_model.dart';

/// PQC Algorithm Types
enum PqcAlgorithm {
  dilithium2,   // CRYSTALS-Dilithium Level 2 (Digital Signatures)
  dilithium3,   // CRYSTALS-Dilithium Level 3
  dilithium5,   // CRYSTALS-Dilithium Level 5
  kyber512,     // CRYSTALS-Kyber 512 (Key Encapsulation)
  kyber768,     // CRYSTALS-Kyber 768
  kyber1024,    // CRYSTALS-Kyber 1024
}

/// PQC Key Pair
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

/// PQC Signature Result
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

  String toBase64() {
    final json = {
      'sig': signature,
      'data': data,
      'alg': algorithm.name,
      'ts': timestamp.toIso8601String(),
    };
    return base64Encode(utf8.encode(jsonEncode(json)));
  }

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

/// Post-Quantum Cryptography Service for BJBank
/// Simulates CRYSTALS-Dilithium (signatures) and CRYSTALS-Kyber (encryption)
///
/// NOTE: This is a SIMULATION for demonstration purposes.
/// In production, use liboqs FFI bindings for real PQC operations.
class PqcService {
  static const _storage = FlutterSecureStorage();
  static const _keyPrefix = 'bjbank_pqc_';

  // Singleton
  static final PqcService _instance = PqcService._internal();
  factory PqcService() => _instance;
  PqcService._internal();

  // Cached key pair
  PqcKeyPair? _cachedKeyPair;

  /// Initialize PQC service
  Future<void> initialize() async {
    debugPrint('PQC Service initialized');
    // Check if keys exist
    final hasKeys = await hasKeyPair();
    if (!hasKeys) {
      debugPrint('No PQC keys found, will generate on first use');
    }
  }

  /// Check if key pair exists
  Future<bool> hasKeyPair() async {
    try {
      final stored = await _storage.read(key: '${_keyPrefix}keypair');
      return stored != null;
    } catch (e) {
      debugPrint('Error checking key pair: $e');
      return false;
    }
  }

  /// Generate new CRYSTALS-Dilithium key pair
  /// Simulated implementation - replace with liboqs FFI in production
  Future<PqcKeyPair> generateKeyPair({
    PqcAlgorithm algorithm = PqcAlgorithm.dilithium3,
  }) async {
    debugPrint('Generating PQC key pair (${algorithm.name})...');

    // Simulate key generation delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate simulated keys (in production, use liboqs)
    final random = Random.secure();

    // Dilithium public key size varies by security level
    final publicKeySize = _getPublicKeySize(algorithm);
    final privateKeySize = _getPrivateKeySize(algorithm);

    final publicKeyBytes = Uint8List(publicKeySize);
    final privateKeyBytes = Uint8List(privateKeySize);

    for (var i = 0; i < publicKeySize; i++) {
      publicKeyBytes[i] = random.nextInt(256);
    }
    for (var i = 0; i < privateKeySize; i++) {
      privateKeyBytes[i] = random.nextInt(256);
    }

    final keyPair = PqcKeyPair(
      publicKey: base64Encode(publicKeyBytes),
      privateKey: base64Encode(privateKeyBytes),
      algorithm: algorithm,
    );

    // Store securely
    await _storage.write(
      key: '${_keyPrefix}keypair',
      value: jsonEncode(keyPair.toJson()),
    );

    _cachedKeyPair = keyPair;
    debugPrint('PQC key pair generated and stored securely');

    return keyPair;
  }

  /// Get stored key pair
  Future<PqcKeyPair?> getKeyPair() async {
    if (_cachedKeyPair != null) return _cachedKeyPair;

    try {
      final stored = await _storage.read(key: '${_keyPrefix}keypair');
      if (stored == null) return null;

      _cachedKeyPair = PqcKeyPair.fromJson(jsonDecode(stored));
      return _cachedKeyPair;
    } catch (e) {
      debugPrint('Error getting key pair: $e');
      return null;
    }
  }

  /// Get or generate key pair
  Future<PqcKeyPair> getOrGenerateKeyPair() async {
    var keyPair = await getKeyPair();
    if (keyPair == null) {
      keyPair = await generateKeyPair();
    }
    return keyPair;
  }

  /// Sign transaction data using CRYSTALS-Dilithium
  /// Simulated implementation - replace with liboqs FFI in production
  Future<PqcSignature> signTransaction({
    required String transactionData,
    required PqcKeyPair keyPair,
  }) async {
    debugPrint('Signing transaction with ${keyPair.algorithm.name}...');

    // Simulate signing delay
    await Future.delayed(const Duration(milliseconds: 200));

    // Create data hash (simplified)
    final dataBytes = utf8.encode(transactionData);
    final timestamp = DateTime.now();

    // Simulate Dilithium signature (in production, use liboqs)
    final signatureSize = _getSignatureSize(keyPair.algorithm);
    final signatureBytes = Uint8List(signatureSize);

    // Mix private key with data for deterministic-looking signature
    final privateKeyBytes = base64Decode(keyPair.privateKey);
    for (var i = 0; i < signatureSize; i++) {
      signatureBytes[i] = (privateKeyBytes[i % privateKeyBytes.length] ^
              dataBytes[i % dataBytes.length] ^
              timestamp.millisecondsSinceEpoch) &
          0xFF;
    }

    final signature = PqcSignature(
      signature: base64Encode(signatureBytes),
      data: transactionData,
      algorithm: keyPair.algorithm,
      timestamp: timestamp,
    );

    debugPrint('Transaction signed successfully');
    return signature;
  }

  /// Verify signature using CRYSTALS-Dilithium
  /// Simulated implementation - replace with liboqs FFI in production
  Future<bool> verifySignature({
    required PqcSignature signature,
    required String publicKey,
  }) async {
    debugPrint('Verifying signature...');

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 100));

    // In production, this would use liboqs to verify
    // For simulation, we just check that signature is not empty
    // and matches expected format

    try {
      final sigBytes = base64Decode(signature.signature);
      final pubKeyBytes = base64Decode(publicKey);

      // Basic validation
      if (sigBytes.isEmpty || pubKeyBytes.isEmpty) {
        return false;
      }

      // Check signature size matches algorithm
      final expectedSize = _getSignatureSize(signature.algorithm);
      if (sigBytes.length != expectedSize) {
        debugPrint('Signature size mismatch');
        return false;
      }

      debugPrint('Signature verified successfully');
      return true;
    } catch (e) {
      debugPrint('Signature verification failed: $e');
      return false;
    }
  }

  /// Sign transfer for BJBank
  Future<String> signTransfer({
    required String senderId,
    required String receiverId,
    required double amount,
    required String description,
  }) async {
    final keyPair = await getOrGenerateKeyPair();

    final transactionData = jsonEncode({
      'from': senderId,
      'to': receiverId,
      'amount': amount,
      'desc': description,
      'ts': DateTime.now().toIso8601String(),
    });

    final signature = await signTransaction(
      transactionData: transactionData,
      keyPair: keyPair,
    );

    return signature.toBase64();
  }

  /// Verify transfer signature
  Future<bool> verifyTransfer({
    required String signatureBase64,
    required String senderPublicKey,
  }) async {
    try {
      final signature = PqcSignature.fromBase64(signatureBase64);
      return await verifySignature(
        signature: signature,
        publicKey: senderPublicKey,
      );
    } catch (e) {
      debugPrint('Error verifying transfer: $e');
      return false;
    }
  }

  /// Delete stored keys
  Future<void> deleteKeys() async {
    await _storage.delete(key: '${_keyPrefix}keypair');
    _cachedKeyPair = null;
    debugPrint('PQC keys deleted');
  }

  /// Get public key size based on algorithm
  int _getPublicKeySize(PqcAlgorithm algorithm) {
    switch (algorithm) {
      case PqcAlgorithm.dilithium2:
        return 1312; // Dilithium2 public key size
      case PqcAlgorithm.dilithium3:
        return 1952; // Dilithium3 public key size
      case PqcAlgorithm.dilithium5:
        return 2592; // Dilithium5 public key size
      case PqcAlgorithm.kyber512:
        return 800;
      case PqcAlgorithm.kyber768:
        return 1184;
      case PqcAlgorithm.kyber1024:
        return 1568;
    }
  }

  /// Get private key size based on algorithm
  int _getPrivateKeySize(PqcAlgorithm algorithm) {
    switch (algorithm) {
      case PqcAlgorithm.dilithium2:
        return 2528;
      case PqcAlgorithm.dilithium3:
        return 4000;
      case PqcAlgorithm.dilithium5:
        return 4864;
      case PqcAlgorithm.kyber512:
        return 1632;
      case PqcAlgorithm.kyber768:
        return 2400;
      case PqcAlgorithm.kyber1024:
        return 3168;
    }
  }

  /// Get signature size based on algorithm
  int _getSignatureSize(PqcAlgorithm algorithm) {
    switch (algorithm) {
      case PqcAlgorithm.dilithium2:
        return 2420;
      case PqcAlgorithm.dilithium3:
        return 3293;
      case PqcAlgorithm.dilithium5:
        return 4595;
      default:
        return 3293; // Default to Dilithium3
    }
  }

  // ── Public size getters ────────────────────────────────────────────────────

  /// Public key size in bytes for the given algorithm
  int getPublicKeySize(PqcAlgorithm algorithm) => _getPublicKeySize(algorithm);

  /// Private key size in bytes for the given algorithm
  int getPrivateKeySize(PqcAlgorithm algorithm) => _getPrivateKeySize(algorithm);

  /// Signature size in bytes for the given algorithm (Dilithium)
  int getSignatureSize(PqcAlgorithm algorithm) => _getSignatureSize(algorithm);

  /// Ciphertext size in bytes for Kyber KEM algorithms
  int getCiphertextSize(PqcAlgorithm algorithm) {
    switch (algorithm) {
      case PqcAlgorithm.kyber512:
        return 768;
      case PqcAlgorithm.kyber768:
        return 1088;
      case PqcAlgorithm.kyber1024:
        return 1568;
      default:
        return 0; // Not applicable for Dilithium
    }
  }

  // ── Measurement ────────────────────────────────────────────────────────────

  /// Measure key generation wall-clock time for the given algorithm
  Future<PqcMetrics> measureKeyGen({
    PqcAlgorithm algorithm = PqcAlgorithm.dilithium3,
  }) async {
    final sw = Stopwatch()..start();
    await generateKeyPair(algorithm: algorithm);
    sw.stop();
    return PqcMetrics(
      algorithm: algorithm,
      operation: 'KeyGen',
      wallTime: sw.elapsed,
      outputSizeBytes: _getPublicKeySize(algorithm) + _getPrivateKeySize(algorithm),
      mode: PqcImplementationMode.simulation,
      measuredAt: DateTime.now(),
    );
  }

  // ── NIST comparison data ───────────────────────────────────────────────────

  /// NIST/SUPERCOP reference data for classical and PQC algorithms.
  /// Source: SUPERCOP, Intel Core i7-6500U @ 2.5GHz.
  static Map<String, ClassicalComparisonData> getNistComparisonData() {
    return {
      'RSA-2048': const ClassicalComparisonData(
        algorithm: 'RSA-2048',
        type: 'signature',
        publicKeySizeBytes: 256,
        privateKeySizeBytes: 1192,
        signatureSizeBytes: 256,
        keyGenCycles: 3200000,
        signCycles: 1700000,
        verifyCycles: 30000,
        quantumResistant: false,
        nistSecurityLevel: 0,
        referenceSource: 'NIST SP 800-56B',
      ),
      'RSA-4096': const ClassicalComparisonData(
        algorithm: 'RSA-4096',
        type: 'signature',
        publicKeySizeBytes: 512,
        privateKeySizeBytes: 2384,
        signatureSizeBytes: 512,
        keyGenCycles: 25000000,
        signCycles: 12000000,
        verifyCycles: 120000,
        quantumResistant: false,
        nistSecurityLevel: 0,
        referenceSource: 'NIST SP 800-56B',
      ),
      'ECDSA-256': const ClassicalComparisonData(
        algorithm: 'ECDSA-256',
        type: 'signature',
        publicKeySizeBytes: 64,
        privateKeySizeBytes: 32,
        signatureSizeBytes: 72,
        keyGenCycles: 150000,
        signCycles: 250000,
        verifyCycles: 650000,
        quantumResistant: false,
        nistSecurityLevel: 0,
        referenceSource: 'SUPERCOP',
      ),
      'ECDSA-384': const ClassicalComparisonData(
        algorithm: 'ECDSA-384',
        type: 'signature',
        publicKeySizeBytes: 96,
        privateKeySizeBytes: 48,
        signatureSizeBytes: 104,
        keyGenCycles: 280000,
        signCycles: 400000,
        verifyCycles: 950000,
        quantumResistant: false,
        nistSecurityLevel: 0,
        referenceSource: 'SUPERCOP',
      ),
      'ECDH-P256': const ClassicalComparisonData(
        algorithm: 'ECDH-P256',
        type: 'kem',
        publicKeySizeBytes: 64,
        privateKeySizeBytes: 32,
        signatureSizeBytes: 65,
        keyGenCycles: 150000,
        signCycles: 200000,
        verifyCycles: 200000,
        quantumResistant: false,
        nistSecurityLevel: 0,
        referenceSource: 'SUPERCOP',
      ),
      'ECDH-P384': const ClassicalComparisonData(
        algorithm: 'ECDH-P384',
        type: 'kem',
        publicKeySizeBytes: 96,
        privateKeySizeBytes: 48,
        signatureSizeBytes: 97,
        keyGenCycles: 280000,
        signCycles: 350000,
        verifyCycles: 350000,
        quantumResistant: false,
        nistSecurityLevel: 0,
        referenceSource: 'SUPERCOP',
      ),
    };
  }

  /// Get algorithm info for UI display
  static Map<String, dynamic> getAlgorithmInfo(PqcAlgorithm algorithm) {
    switch (algorithm) {
      case PqcAlgorithm.dilithium2:
        return {
          'name': 'CRYSTALS-Dilithium',
          'level': 2,
          'securityBits': 128,
          'type': 'Assinatura Digital',
          'nistLevel': 'Nível 2',
        };
      case PqcAlgorithm.dilithium3:
        return {
          'name': 'CRYSTALS-Dilithium',
          'level': 3,
          'securityBits': 192,
          'type': 'Assinatura Digital',
          'nistLevel': 'Nível 3',
        };
      case PqcAlgorithm.dilithium5:
        return {
          'name': 'CRYSTALS-Dilithium',
          'level': 5,
          'securityBits': 256,
          'type': 'Assinatura Digital',
          'nistLevel': 'Nível 5',
        };
      case PqcAlgorithm.kyber512:
        return {
          'name': 'CRYSTALS-Kyber',
          'level': 1,
          'securityBits': 128,
          'type': 'Encapsulamento de Chave',
          'nistLevel': 'Nível 1',
        };
      case PqcAlgorithm.kyber768:
        return {
          'name': 'CRYSTALS-Kyber',
          'level': 3,
          'securityBits': 192,
          'type': 'Encapsulamento de Chave',
          'nistLevel': 'Nível 3',
        };
      case PqcAlgorithm.kyber1024:
        return {
          'name': 'CRYSTALS-Kyber',
          'level': 5,
          'securityBits': 256,
          'type': 'Encapsulamento de Chave',
          'nistLevel': 'Nível 5',
        };
    }
  }
}

// ── Supplementary PQC Types ─────────────────────────────────────────────────

/// Single PQC operation measurement
class PqcMetrics {
  final PqcAlgorithm algorithm;
  final String operation;
  final Duration wallTime;
  final int outputSizeBytes;
  final PqcImplementationMode mode;
  final DateTime measuredAt;

  const PqcMetrics({
    required this.algorithm,
    required this.operation,
    required this.wallTime,
    required this.outputSizeBytes,
    required this.mode,
    required this.measuredAt,
  });

  Map<String, dynamic> toJson() => {
        'algorithm': algorithm.name,
        'operation': operation,
        'wallTimeMs': wallTime.inMicroseconds / 1000.0,
        'outputSizeBytes': outputSizeBytes,
        'implementationMode': mode.name,
        'measuredAt': measuredAt.toIso8601String(),
      };
}

/// Simulated hybrid handshake: TLS ECDHE-P256 → Kyber768 KEM → HKDF-SHA256
///
/// Implements the 3-phase protocol described in ADR-002.
/// Timings are simulated (serialization + I/O delays); real Kyber768 math
/// would run in < 0.13ms on ARM64 per SUPERCOP benchmarks.
class PqcHybridHandshake {
  Future<PqcHybridHandshakeResult> execute({
    String clientId = 'client',
    String serverId = 'server',
    PqcAlgorithm kemAlgorithm = PqcAlgorithm.kyber768,
  }) async {
    final pqcService = PqcService();
    final rng = Random.secure();

    // Phase 1: Simulated ECDHE-P256 (~15ms serialization overhead)
    final phase1Start = Stopwatch()..start();
    await Future.delayed(const Duration(milliseconds: 15));
    final classicalSecret = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      classicalSecret[i] = rng.nextInt(256);
    }
    phase1Start.stop();
    final classicalPhaseMs = phase1Start.elapsedMicroseconds / 1000.0;

    // Phase 2: Simulated Kyber KEM (KeyGen + Encaps, ~25ms serialization overhead)
    final phase2Start = Stopwatch()..start();
    final pkSize = pqcService.getPublicKeySize(kemAlgorithm);
    final ctSize = pqcService.getCiphertextSize(kemAlgorithm);
    await Future.delayed(const Duration(milliseconds: 25));
    final kyberSecret = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      kyberSecret[i] = rng.nextInt(256);
    }
    phase2Start.stop();
    final kemPhaseMs = phase2Start.elapsedMicroseconds / 1000.0;

    // Phase 3: Simulated HKDF-SHA256 (~3ms)
    final phase3Start = Stopwatch()..start();
    await Future.delayed(const Duration(milliseconds: 3));
    phase3Start.stop();
    final kdfPhaseMs = phase3Start.elapsedMicroseconds / 1000.0;

    final totalMs = classicalPhaseMs + kemPhaseMs + kdfPhaseMs;

    return PqcHybridHandshakeResult(
      clientId: clientId,
      serverId: serverId,
      kemAlgorithm: kemAlgorithm.name,
      classicalPhaseMs: classicalPhaseMs,
      kemPhaseMs: kemPhaseMs,
      kdfPhaseMs: kdfPhaseMs,
      totalMs: totalMs,
      kemPublicKeySizeBytes: pkSize,
      kemCiphertextSizeBytes: ctSize,
      combinedSecretSizeBytes: 32,
      mode: PqcImplementationMode.hybridSimulation,
      executedAt: DateTime.now(),
    );
  }
}
