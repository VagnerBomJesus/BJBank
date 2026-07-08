import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/pqc_metrics_model.dart';
import 'pqc_service.dart';

/// Benchmarking service for PQC vs. classical cryptography performance comparison.
///
/// Measures wall-clock time for simulated PQC operations (N iterations),
/// computes statistical summaries (avg, min, max, P95), and produces a full
/// [PqcBenchmarkReport] ready for export (JSON/Markdown) into the dissertation.
///
/// See ADR-003 for methodology and limitations.
class PqcBenchmarkService {
  // Singleton
  static final PqcBenchmarkService _instance = PqcBenchmarkService._internal();
  factory PqcBenchmarkService() => _instance;
  PqcBenchmarkService._internal();

  PqcBenchmarkReport? _lastReport;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  PqcBenchmarkReport? get lastReport => _lastReport;

  /// Run a full benchmark suite across all supported algorithms.
  ///
  /// [iterationsPerOp] controls statistical reliability (10 = fast, 50 = rigorous).
  /// [onProgress] callback receives (0.0–1.0, currentOperationLabel).
  Future<PqcBenchmarkReport> runFullBenchmark({
    int iterationsPerOp = 10,
    void Function(double progress, String currentOp)? onProgress,
  }) async {
    if (_isRunning) {
      throw StateError('Benchmark already running');
    }
    _isRunning = true;

    final overallStart = Stopwatch()..start();
    final pqcOps = <PqcOperationMetrics>[];

    // Operations to benchmark: (algorithm, operation, outputSizeFn, delayMs)
    // Delays simulate serialization/storage overhead in the PoC implementation.
    final operations = _buildOperationList();
    final total = operations.length + 1; // +1 for hybrid handshake
    var completed = 0;

    try {
      for (final op in operations) {
        onProgress?.call(completed / total, op.label);
        final metrics = await _runOperation(op, iterationsPerOp);
        pqcOps.add(metrics);
        completed++;
      }

      // Hybrid handshake benchmark
      onProgress?.call(completed / total, 'Handshake Híbrido (Kyber768)');
      final handshake = await PqcHybridHandshake().execute();
      completed++;

      overallStart.stop();

      final report = PqcBenchmarkReport(
        executedAt: DateTime.now(),
        deviceInfo: _getDeviceInfo(),
        dartVersion: '3.8.1',
        pqcOperations: pqcOps,
        classicalComparison: PqcService.getNistComparisonData().values.toList(),
        hybridHandshake: handshake,
        totalDurationMs: overallStart.elapsedMicroseconds / 1000.0,
        iterationsPerOp: iterationsPerOp,
        implementationMode: PqcImplementationMode.simulation,
      );

      _lastReport = report;
      onProgress?.call(1.0, 'Concluído');
      return report;
    } finally {
      _isRunning = false;
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  List<_OpSpec> _buildOperationList() {
    final pqcSvc = PqcService();
    return [
      // Dilithium signatures
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium2,
        label: 'Dilithium2 KeyGen',
        operation: 'KeyGen',
        outputSizeBytes:
            pqcSvc.getPublicKeySize(PqcAlgorithm.dilithium2) +
            pqcSvc.getPrivateKeySize(PqcAlgorithm.dilithium2),
        baseDelayMs: 20,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium2,
        label: 'Dilithium2 Sign',
        operation: 'Sign',
        outputSizeBytes: pqcSvc.getSignatureSize(PqcAlgorithm.dilithium2),
        baseDelayMs: 18,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium2,
        label: 'Dilithium2 Verify',
        operation: 'Verify',
        outputSizeBytes: 1,
        baseDelayMs: 14,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium3,
        label: 'Dilithium3 KeyGen',
        operation: 'KeyGen',
        outputSizeBytes:
            pqcSvc.getPublicKeySize(PqcAlgorithm.dilithium3) +
            pqcSvc.getPrivateKeySize(PqcAlgorithm.dilithium3),
        baseDelayMs: 25,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium3,
        label: 'Dilithium3 Sign',
        operation: 'Sign',
        outputSizeBytes: pqcSvc.getSignatureSize(PqcAlgorithm.dilithium3),
        baseDelayMs: 22,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium3,
        label: 'Dilithium3 Verify',
        operation: 'Verify',
        outputSizeBytes: 1,
        baseDelayMs: 17,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium5,
        label: 'Dilithium5 KeyGen',
        operation: 'KeyGen',
        outputSizeBytes:
            pqcSvc.getPublicKeySize(PqcAlgorithm.dilithium5) +
            pqcSvc.getPrivateKeySize(PqcAlgorithm.dilithium5),
        baseDelayMs: 32,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium5,
        label: 'Dilithium5 Sign',
        operation: 'Sign',
        outputSizeBytes: pqcSvc.getSignatureSize(PqcAlgorithm.dilithium5),
        baseDelayMs: 28,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.dilithium5,
        label: 'Dilithium5 Verify',
        operation: 'Verify',
        outputSizeBytes: 1,
        baseDelayMs: 21,
      ),
      // Kyber KEM
      _OpSpec(
        algorithm: PqcAlgorithm.kyber512,
        label: 'Kyber512 KeyGen',
        operation: 'KeyGen',
        outputSizeBytes:
            pqcSvc.getPublicKeySize(PqcAlgorithm.kyber512) +
            pqcSvc.getPrivateKeySize(PqcAlgorithm.kyber512),
        baseDelayMs: 12,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.kyber512,
        label: 'Kyber512 Encaps',
        operation: 'Encaps',
        outputSizeBytes: pqcSvc.getCiphertextSize(PqcAlgorithm.kyber512),
        baseDelayMs: 13,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.kyber512,
        label: 'Kyber512 Decaps',
        operation: 'Decaps',
        outputSizeBytes: 32,
        baseDelayMs: 13,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.kyber768,
        label: 'Kyber768 KeyGen',
        operation: 'KeyGen',
        outputSizeBytes:
            pqcSvc.getPublicKeySize(PqcAlgorithm.kyber768) +
            pqcSvc.getPrivateKeySize(PqcAlgorithm.kyber768),
        baseDelayMs: 18,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.kyber768,
        label: 'Kyber768 Encaps',
        operation: 'Encaps',
        outputSizeBytes: pqcSvc.getCiphertextSize(PqcAlgorithm.kyber768),
        baseDelayMs: 20,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.kyber768,
        label: 'Kyber768 Decaps',
        operation: 'Decaps',
        outputSizeBytes: 32,
        baseDelayMs: 20,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.kyber1024,
        label: 'Kyber1024 KeyGen',
        operation: 'KeyGen',
        outputSizeBytes:
            pqcSvc.getPublicKeySize(PqcAlgorithm.kyber1024) +
            pqcSvc.getPrivateKeySize(PqcAlgorithm.kyber1024),
        baseDelayMs: 25,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.kyber1024,
        label: 'Kyber1024 Encaps',
        operation: 'Encaps',
        outputSizeBytes: pqcSvc.getCiphertextSize(PqcAlgorithm.kyber1024),
        baseDelayMs: 27,
      ),
      _OpSpec(
        algorithm: PqcAlgorithm.kyber1024,
        label: 'Kyber1024 Decaps',
        operation: 'Decaps',
        outputSizeBytes: 32,
        baseDelayMs: 27,
      ),
    ];
  }

  Future<PqcOperationMetrics> _runOperation(
    _OpSpec op,
    int iterations,
  ) async {
    final timingsMs = <double>[];
    final rng = Random.secure();

    for (var i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();

      // Simulate serialization + random byte generation overhead
      final size = op.outputSizeBytes.clamp(1, op.outputSizeBytes);
      final buf = Uint8List(size);
      for (var j = 0; j < size; j++) {
        buf[j] = rng.nextInt(256);
      }

      // Add a base delay proportional to algorithm complexity
      final jitter = rng.nextInt(5); // 0–4ms jitter
      await Future.delayed(Duration(milliseconds: op.baseDelayMs + jitter));

      sw.stop();
      timingsMs.add(sw.elapsedMicroseconds / 1000.0);
    }

    return _computeMetrics(
      op.algorithm.name,
      op.operation,
      timingsMs,
      op.outputSizeBytes,
    );
  }

  PqcOperationMetrics _computeMetrics(
    String algorithm,
    String operation,
    List<double> timingsMs,
    int outputSizeBytes,
  ) {
    final sorted = List<double>.from(timingsMs)..sort();
    final avg = sorted.reduce((a, b) => a + b) / sorted.length;
    final min = sorted.first;
    final max = sorted.last;
    final p95Index = ((sorted.length * 0.95) - 1).clamp(0, sorted.length - 1).toInt();
    final p95 = sorted[p95Index];

    return PqcOperationMetrics(
      algorithm: algorithm,
      operation: operation,
      iterations: timingsMs.length,
      avgWallTimeMs: avg,
      minWallTimeMs: min,
      maxWallTimeMs: max,
      p95WallTimeMs: p95,
      outputSizeBytes: outputSizeBytes,
      implementationMode: PqcImplementationMode.simulation,
      measuredAt: DateTime.now(),
    );
  }

  /// Indicative energy score: higher = more energy (not physically calibrated)
  double estimateEnergyScore(PqcOperationMetrics metrics) {
    const k = 0.001; // proportionality constant (arbitrary units)
    return k * metrics.outputSizeBytes * metrics.avgWallTimeMs;
  }

  String _getDeviceInfo() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android / ARM64';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS / Apple Silicon';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'Windows / x86_64';
    }
    return 'Unknown';
  }
}

/// Internal spec for a benchmark operation
class _OpSpec {
  final PqcAlgorithm algorithm;
  final String label;
  final String operation;
  final int outputSizeBytes;
  final int baseDelayMs;

  const _OpSpec({
    required this.algorithm,
    required this.label,
    required this.operation,
    required this.outputSizeBytes,
    required this.baseDelayMs,
  });
}
