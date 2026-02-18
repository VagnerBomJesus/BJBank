import 'dart:convert';

/// Implementation mode for PQC operations
enum PqcImplementationMode {
  simulation,        // Random bytes with correct NIST sizes (current BJBank)
  hybridSimulation,  // Hybrid handshake with simulated timings
  production,        // Real liboqs FFI bindings (future)
}

/// Metrics for a single PQC operation measured on-device
class PqcOperationMetrics {
  final String algorithm;
  final String operation;
  final int iterations;
  final double avgWallTimeMs;
  final double minWallTimeMs;
  final double maxWallTimeMs;
  final double p95WallTimeMs;
  final int outputSizeBytes;
  final PqcImplementationMode implementationMode;
  final DateTime measuredAt;

  const PqcOperationMetrics({
    required this.algorithm,
    required this.operation,
    required this.iterations,
    required this.avgWallTimeMs,
    required this.minWallTimeMs,
    required this.maxWallTimeMs,
    required this.p95WallTimeMs,
    required this.outputSizeBytes,
    required this.implementationMode,
    required this.measuredAt,
  });

  Map<String, dynamic> toJson() => {
        'algorithm': algorithm,
        'operation': operation,
        'iterations': iterations,
        'avgWallTimeMs': avgWallTimeMs,
        'minWallTimeMs': minWallTimeMs,
        'maxWallTimeMs': maxWallTimeMs,
        'p95WallTimeMs': p95WallTimeMs,
        'outputSizeBytes': outputSizeBytes,
        'implementationMode': implementationMode.name,
        'measuredAt': measuredAt.toIso8601String(),
      };

  factory PqcOperationMetrics.fromJson(Map<String, dynamic> json) =>
      PqcOperationMetrics(
        algorithm: json['algorithm'] as String,
        operation: json['operation'] as String,
        iterations: json['iterations'] as int,
        avgWallTimeMs: (json['avgWallTimeMs'] as num).toDouble(),
        minWallTimeMs: (json['minWallTimeMs'] as num).toDouble(),
        maxWallTimeMs: (json['maxWallTimeMs'] as num).toDouble(),
        p95WallTimeMs: (json['p95WallTimeMs'] as num).toDouble(),
        outputSizeBytes: json['outputSizeBytes'] as int,
        implementationMode: PqcImplementationMode.values
            .byName(json['implementationMode'] as String),
        measuredAt: DateTime.parse(json['measuredAt'] as String),
      );
}

/// Reference data for classical cryptography algorithms (NIST/SUPERCOP values)
/// Source: SUPERCOP benchmarks, Intel Core i7-6500U @ 2.5GHz
class ClassicalComparisonData {
  final String algorithm;
  final String type; // 'signature' or 'kem'
  final int publicKeySizeBytes;
  final int privateKeySizeBytes;
  final int signatureSizeBytes; // or ciphertext for KEM
  final int keyGenCycles;
  final int signCycles; // or encaps for KEM
  final int verifyCycles; // or decaps for KEM
  final bool quantumResistant;
  final int nistSecurityLevel;
  final String referenceHardware;
  final String referenceSource;

  const ClassicalComparisonData({
    required this.algorithm,
    required this.type,
    required this.publicKeySizeBytes,
    required this.privateKeySizeBytes,
    required this.signatureSizeBytes,
    required this.keyGenCycles,
    required this.signCycles,
    required this.verifyCycles,
    required this.quantumResistant,
    required this.nistSecurityLevel,
    this.referenceHardware = 'Intel Core i7-6500U @ 2.5GHz',
    this.referenceSource = 'SUPERCOP',
  });

  /// Convert cycles to milliseconds at given clock speed
  double cycleToMs(int cycles, {double clockGhz = 2.5}) {
    return cycles / (clockGhz * 1e9 / 1e3);
  }

  double get keyGenMs => cycleToMs(keyGenCycles);
  double get signMs => cycleToMs(signCycles);
  double get verifyMs => cycleToMs(verifyCycles);

  Map<String, dynamic> toJson() => {
        'algorithm': algorithm,
        'type': type,
        'publicKeySizeBytes': publicKeySizeBytes,
        'privateKeySizeBytes': privateKeySizeBytes,
        'signatureSizeBytes': signatureSizeBytes,
        'keyGenCycles': keyGenCycles,
        'signCycles': signCycles,
        'verifyCycles': verifyCycles,
        'quantumResistant': quantumResistant,
        'nistSecurityLevel': nistSecurityLevel,
        'keyGenMs': keyGenMs,
        'signMs': signMs,
        'verifyMs': verifyMs,
        'referenceHardware': referenceHardware,
        'referenceSource': referenceSource,
      };
}

/// Result of a simulated hybrid handshake (TLS ECDHE + Kyber KEM)
class PqcHybridHandshakeResult {
  final String clientId;
  final String serverId;
  final String kemAlgorithm;
  final double classicalPhaseMs;
  final double kemPhaseMs;
  final double kdfPhaseMs;
  final double totalMs;
  final int kemPublicKeySizeBytes;
  final int kemCiphertextSizeBytes;
  final int combinedSecretSizeBytes;
  final PqcImplementationMode mode;
  final DateTime executedAt;

  const PqcHybridHandshakeResult({
    required this.clientId,
    required this.serverId,
    required this.kemAlgorithm,
    required this.classicalPhaseMs,
    required this.kemPhaseMs,
    required this.kdfPhaseMs,
    required this.totalMs,
    required this.kemPublicKeySizeBytes,
    required this.kemCiphertextSizeBytes,
    required this.combinedSecretSizeBytes,
    required this.mode,
    required this.executedAt,
  });

  /// Total overhead in bytes added by the PQC KEM phase
  int get pqcOverheadBytes => kemPublicKeySizeBytes + kemCiphertextSizeBytes;

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'serverId': serverId,
        'kemAlgorithm': kemAlgorithm,
        'classicalPhaseMs': classicalPhaseMs,
        'kemPhaseMs': kemPhaseMs,
        'kdfPhaseMs': kdfPhaseMs,
        'totalMs': totalMs,
        'kemPublicKeySizeBytes': kemPublicKeySizeBytes,
        'kemCiphertextSizeBytes': kemCiphertextSizeBytes,
        'pqcOverheadBytes': pqcOverheadBytes,
        'combinedSecretSizeBytes': combinedSecretSizeBytes,
        'mode': mode.name,
        'executedAt': executedAt.toIso8601String(),
      };
}

/// Full benchmark report for a benchmarking session
class PqcBenchmarkReport {
  final DateTime executedAt;
  final String deviceInfo;
  final String dartVersion;
  final List<PqcOperationMetrics> pqcOperations;
  final List<ClassicalComparisonData> classicalComparison;
  final PqcHybridHandshakeResult? hybridHandshake;
  final double totalDurationMs;
  final int iterationsPerOp;
  final PqcImplementationMode implementationMode;

  const PqcBenchmarkReport({
    required this.executedAt,
    required this.deviceInfo,
    required this.dartVersion,
    required this.pqcOperations,
    required this.classicalComparison,
    this.hybridHandshake,
    required this.totalDurationMs,
    required this.iterationsPerOp,
    required this.implementationMode,
  });

  /// Export as Markdown table for dissertation integration
  String toMarkdownTable() {
    final buf = StringBuffer();
    buf.writeln('## BJBank PQC Benchmark Report');
    buf.writeln('**Data:** ${executedAt.toIso8601String()}');
    buf.writeln('**Dispositivo:** $deviceInfo');
    buf.writeln('**Iterações por operação:** $iterationsPerOp');
    buf.writeln('**Modo:** ${implementationMode.name}');
    buf.writeln();
    buf.writeln(
        '| Algoritmo | Operação | Tempo Médio (ms) | P95 (ms) | Tamanho (bytes) | Nível NIST |');
    buf.writeln(
        '|-----------|----------|-----------------|---------|----------------|-----------|');
    for (final op in pqcOperations) {
      buf.writeln(
          '| ${op.algorithm} | ${op.operation} | ${op.avgWallTimeMs.toStringAsFixed(2)} | ${op.p95WallTimeMs.toStringAsFixed(2)} | ${op.outputSizeBytes} | — |');
    }
    buf.writeln();
    buf.writeln('### Comparação com Algoritmos Clássicos (Referência NIST/SUPERCOP)');
    buf.writeln(
        '| Algoritmo | KeyGen (ms) | Sign/Enc (ms) | Verify/Dec (ms) | Pk (bytes) | Sig/CT (bytes) | Resist. Quântica |');
    buf.writeln(
        '|-----------|------------|--------------|----------------|-----------|---------------|-----------------|');
    for (final c in classicalComparison) {
      buf.writeln(
          '| ${c.algorithm} | ${c.keyGenMs.toStringAsFixed(3)} | ${c.signMs.toStringAsFixed(3)} | ${c.verifyMs.toStringAsFixed(3)} | ${c.publicKeySizeBytes} | ${c.signatureSizeBytes} | ${c.quantumResistant ? "✅" : "❌"} |');
    }
    if (hybridHandshake != null) {
      final h = hybridHandshake!;
      buf.writeln();
      buf.writeln('### Handshake Híbrido (TLS ECDHE + ${h.kemAlgorithm})');
      buf.writeln(
          '| Fase | Latência (ms) | Overhead (bytes) |');
      buf.writeln('|------|--------------|-----------------|');
      buf.writeln(
          '| ECDHE-P256 (clássico) | ${h.classicalPhaseMs.toStringAsFixed(1)} | 32 (shared secret) |');
      buf.writeln(
          '| ${h.kemAlgorithm} KEM | ${h.kemPhaseMs.toStringAsFixed(1)} | ${h.pqcOverheadBytes} (pk + ct) |');
      buf.writeln(
          '| HKDF-SHA256 | ${h.kdfPhaseMs.toStringAsFixed(1)} | 32 (session key) |');
      buf.writeln(
          '| **Total** | **${h.totalMs.toStringAsFixed(1)}** | **+${h.pqcOverheadBytes} bytes** |');
    }
    return buf.toString();
  }

  /// Export as JSON string
  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert({
      'executedAt': executedAt.toIso8601String(),
      'deviceInfo': deviceInfo,
      'dartVersion': dartVersion,
      'totalDurationMs': totalDurationMs,
      'iterationsPerOp': iterationsPerOp,
      'implementationMode': implementationMode.name,
      'pqcOperations': pqcOperations.map((o) => o.toJson()).toList(),
      'classicalComparison': classicalComparison.map((c) => c.toJson()).toList(),
      'hybridHandshake': hybridHandshake?.toJson(),
    });
  }
}
