// ============================================================================
// classic_crypto_service.dart
//
// Pipeline criptográfico CLÁSSICO paralelo ao PQC, para benchmarks
// comparativos exigidos pela tese.
//
//   - ECDH-P256 (NIST P-256 / secp256r1) — substitui ML-KEM-768
//   - ECDSA-P256 (SHA-256)              — substitui ML-DSA-65
//
// Permite ao `SupabaseTransferService` operar em modo clássico OU PQC,
// produzindo medições directamente comparáveis face a:
//   - Tempo de keygen / sign / verify / agree
//   - Tamanho de pubkey / signature
//   - Overhead de banda no envelope
//
// Usado por:
//   - BenchmarkScreen (modo "PQC vs Classico")
//   - Modo configurável `SettingsProvider.useClassicPipeline`
//
// Implementação 100% Dart via PointyCastle (sem dependência nativa).
// ============================================================================

import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

class ClassicKeyPair {
  final Uint8List publicKey;     // SubjectPublicKeyInfo formato 65 B (uncompressed: 0x04 || X || Y)
  final Uint8List privateKey;    // raw 32 B scalar
  const ClassicKeyPair({required this.publicKey, required this.privateKey});
}

class ClassicCryptoService {
  ClassicCryptoService._();
  static final ClassicCryptoService instance = ClassicCryptoService._();

  static const _curveName = 'prime256v1'; // = secp256r1 = P-256

  Random get _rng => Random.secure();

  pc.SecureRandom _secureRandom() {
    final rng = pc.FortunaRandom();
    final seed = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      seed[i] = _rng.nextInt(256);
    }
    rng.seed(pc.KeyParameter(seed));
    return rng;
  }

  pc.ECDomainParameters get _domain => pc.ECDomainParameters(_curveName);

  // ─── ECDSA-P256 ────────────────────────────────────────────────────

  /// Gera par ECDSA-P256. pub ~65 B (uncompressed), priv 32 B.
  ClassicKeyPair ecdsaKeygen() {
    final kpg = pc.ECKeyGenerator()
      ..init(pc.ParametersWithRandom(
        pc.ECKeyGeneratorParameters(_domain),
        _secureRandom(),
      ));
    final kp = kpg.generateKeyPair();
    final priv = (kp.privateKey as pc.ECPrivateKey).d!;
    final pub = (kp.publicKey as pc.ECPublicKey).Q!;

    return ClassicKeyPair(
      publicKey: _encodePublicKey(pub),
      privateKey: _bigIntTo32Bytes(priv),
    );
  }

  /// Assina message com ECDSA-P256 + SHA-256. Sig é DER, ~70-72 B.
  Uint8List ecdsaSign(Uint8List privateKey, Uint8List message) {
    final priv = pc.ECPrivateKey(_bytesToBigInt(privateKey), _domain);
    final signer = pc.Signer('SHA-256/ECDSA')
      ..init(true, pc.ParametersWithRandom(
        pc.PrivateKeyParameter<pc.ECPrivateKey>(priv),
        _secureRandom(),
      ));
    final sig = signer.generateSignature(message) as pc.ECSignature;
    return _encodeEcSignatureDer(sig);
  }

  bool ecdsaVerify({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  }) {
    final point = _decodePublicKey(publicKey);
    final pub = pc.ECPublicKey(point, _domain);
    final sig = _decodeEcSignatureDer(signature);
    final verifier = pc.Signer('SHA-256/ECDSA')
      ..init(false, pc.PublicKeyParameter<pc.ECPublicKey>(pub));
    return verifier.verifySignature(message, sig);
  }

  // ─── ECDH-P256 ─────────────────────────────────────────────────────

  /// Gera par ECDH-P256 (mesma curva, uso diferente).
  ClassicKeyPair ecdhKeygen() => ecdsaKeygen();

  /// Acordo ECDH: shared secret 32 B (X-coord do ponto de acordo).
  Uint8List ecdhAgree({
    required Uint8List privateKey,
    required Uint8List peerPublicKey,
  }) {
    final priv = pc.ECPrivateKey(_bytesToBigInt(privateKey), _domain);
    final peer = pc.ECPublicKey(_decodePublicKey(peerPublicKey), _domain);
    final agreement = pc.ECDHBasicAgreement()..init(priv);
    final ss = agreement.calculateAgreement(peer);
    return _bigIntTo32Bytes(ss);
  }

  // ─── Benchmark Dart-only ───────────────────────────────────────────

  /// Mede tempo em microsegundos de cada operação clássica.
  /// Para comparação directa com `DevicePqcService.runBenchmark`.
  Map<String, dynamic> benchmark({int iterations = 100}) {
    final n = iterations.clamp(10, 500);
    final results = <String, Map<String, Object>>{};

    // ECDSA keygen
    results['ecdsa_keygen_us'] = _measure(n, () => ecdsaKeygen());

    final kp = ecdsaKeygen();
    final msg = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      msg[i] = _rng.nextInt(256);
    }

    Uint8List lastSig = Uint8List(0);
    results['ecdsa_sign_us'] = _measure(n, () {
      lastSig = ecdsaSign(kp.privateKey, msg);
    });
    results['ecdsa_verify_us'] = _measure(n, () {
      ecdsaVerify(publicKey: kp.publicKey, message: msg, signature: lastSig);
    });

    results['ecdh_keygen_agree_us'] = _measure(n, () {
      final a = ecdhKeygen();
      final b = ecdhKeygen();
      ecdhAgree(privateKey: a.privateKey, peerPublicKey: b.publicKey);
    });

    return {
      'iterations': n,
      'results': results,
      'platform': 'dart-pointycastle',
      'pipeline': 'classic',
    };
  }

  Map<String, Object> _measure(int n, void Function() block) {
    // Warmup
    for (var i = 0; i < 3; i++) {
      block();
    }
    final samples = List<int>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final sw = Stopwatch()..start();
      block();
      sw.stop();
      samples[i] = sw.elapsedMicroseconds;
    }
    samples.sort();
    final mean = samples.reduce((a, b) => a + b) / n;
    final variance = samples
            .map((x) => (x - mean) * (x - mean))
            .reduce((a, b) => a + b) /
        n;
    final stdev = sqrt(variance);
    return {
      'n': n,
      'p50': samples[(n * 0.50).toInt().clamp(0, n - 1)],
      'p95': samples[(n * 0.95).toInt().clamp(0, n - 1)],
      'p99': samples[(n * 0.99).toInt().clamp(0, n - 1)],
      'min': samples.first,
      'max': samples.last,
      'mean_us': mean,
      'stdev_us': stdev,
    };
  }

  // ─── Helpers ASN.1/EC ──────────────────────────────────────────────

  Uint8List _bigIntTo32Bytes(BigInt n) {
    final bytes = n.toRadixString(16).padLeft(64, '0');
    final out = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      out[i] = int.parse(bytes.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    var n = BigInt.zero;
    for (final b in bytes) {
      n = (n << 8) | BigInt.from(b);
    }
    return n;
  }

  Uint8List _encodePublicKey(pc.ECPoint q) {
    // Uncompressed: 0x04 || X (32B) || Y (32B) → 65B
    final x = _bigIntTo32Bytes(q.x!.toBigInteger()!);
    final y = _bigIntTo32Bytes(q.y!.toBigInteger()!);
    final out = Uint8List(65);
    out[0] = 0x04;
    out.setRange(1, 33, x);
    out.setRange(33, 65, y);
    return out;
  }

  pc.ECPoint _decodePublicKey(Uint8List encoded) {
    if (encoded.length != 65 || encoded[0] != 0x04) {
      throw ArgumentError('Pubkey deve ser uncompressed 65B (0x04 || X || Y).');
    }
    return _domain.curve.decodePoint(encoded)!;
  }

  /// Serializa ECSignature como DER (RFC 3279): SEQUENCE { r, s }.
  Uint8List _encodeEcSignatureDer(pc.ECSignature sig) {
    final rBytes = _bigIntToMinimalBytes(sig.r);
    final sBytes = _bigIntToMinimalBytes(sig.s);
    final total = 2 + rBytes.length + 2 + sBytes.length;
    final out = <int>[
      0x30, total,
      0x02, rBytes.length, ...rBytes,
      0x02, sBytes.length, ...sBytes,
    ];
    return Uint8List.fromList(out);
  }

  pc.ECSignature _decodeEcSignatureDer(Uint8List der) {
    if (der[0] != 0x30) throw ArgumentError('DER inválido');
    var off = 2;
    if (der[off] != 0x02) throw ArgumentError('DER inválido (r)');
    final rLen = der[off + 1];
    final r = _bytesToBigInt(Uint8List.fromList(der.sublist(off + 2, off + 2 + rLen)));
    off += 2 + rLen;
    if (der[off] != 0x02) throw ArgumentError('DER inválido (s)');
    final sLen = der[off + 1];
    final s = _bytesToBigInt(Uint8List.fromList(der.sublist(off + 2, off + 2 + sLen)));
    return pc.ECSignature(r, s);
  }

  Uint8List _bigIntToMinimalBytes(BigInt n) {
    var bytes = n.toRadixString(16);
    if (bytes.length.isOdd) bytes = '0$bytes';
    final out = <int>[];
    for (var i = 0; i < bytes.length; i += 2) {
      out.add(int.parse(bytes.substring(i, i + 2), radix: 16));
    }
    // Prepend 0x00 se bit alto está ligado (para evitar negativo em ASN.1).
    if (out.first >= 0x80) out.insert(0, 0x00);
    return Uint8List.fromList(out);
  }
}
