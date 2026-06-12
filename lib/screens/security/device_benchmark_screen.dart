import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/classic_crypto_service.dart';
import '../../services/device_pqc_service.dart';
import '../../theme/colors.dart';

/// Benchmark on-device — corre cripto NATIVA no dispositivo.
///
/// Mede:
///   - PQC Android (BouncyCastle 1.80): ML-DSA-65 keygen/sign/verify,
///     ML-KEM-768 encap, SLH-DSA sign, X25519 agree.
///   - Clássico Dart (PointyCastle): ECDH-P256, ECDSA-P256.
///
/// Apresenta P50/P95/P99 lado a lado para comparação PQC vs Clássico.
/// Material directo para a tese.
class DeviceBenchmarkScreen extends StatefulWidget {
  const DeviceBenchmarkScreen({super.key});

  @override
  State<DeviceBenchmarkScreen> createState() => _DeviceBenchmarkScreenState();
}

class _DeviceBenchmarkScreenState extends State<DeviceBenchmarkScreen> {
  int _iterations = 100;
  bool _running = false;
  String _phase = '';
  Map<String, dynamic>? _pqcReport;
  Map<String, dynamic>? _classicNativeReport; // BC 1.80 — fair runtime
  Map<String, dynamic>? _classicDartReport;   // PointyCastle — reference
  String? _error;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
      _pqcReport = null;
      _classicNativeReport = null;
      _classicDartReport = null;
    });

    try {
      final pqcAvailable = await DevicePqcService().isAvailable();

      // 1. PQC Android nativo (BC 1.80)
      if (pqcAvailable) {
        setState(() => _phase = 'BC 1.80 — PQC nativo (ML-DSA/KEM/SLH/X25519)…');
        _pqcReport = await DevicePqcService().runBenchmark(
          iterations: _iterations,
        );
      } else {
        setState(() => _phase = 'PQC nativo indisponível (iOS ou erro plugin)');
      }

      // 2. Clássico nativo BC (mesma runtime do PQC — comparação fair)
      if (pqcAvailable) {
        setState(() => _phase = 'BC 1.80 — Clássico nativo (ECDSA/ECDH P-256)…');
        _classicNativeReport = await DevicePqcService().runClassicBenchmark(
          iterations: _iterations,
        );
      }

      // 3. Clássico Dart puro (referência — runtime interpretado)
      setState(() => _phase = 'PointyCastle Dart — Clássico referência…');
      await Future.delayed(const Duration(milliseconds: 100));
      _classicDartReport = ClassicCryptoService.instance.benchmark(
        iterations: _iterations,
      );

      setState(() {
        _phase = 'Concluído';
        _running = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _running = false;
        _phase = 'Erro';
      });
    }
  }

  Future<void> _exportar() async {
    final blob = jsonEncode({
      'iterations': _iterations,
      'pqc_android_bc180': _pqcReport,
      'classic_native_bc180': _classicNativeReport,
      'classic_dart_pointycastle': _classicDartReport,
      'note':
          'pqc_android_bc180 e classic_native_bc180 partilham runtime (BC 1.80 '
          'JVM nativa) — comparação fair entre algoritmos. '
          'classic_dart_pointycastle é runtime Dart interpretado — referência '
          'do custo de portar para puro Dart.',
      'generated_at': DateTime.now().toIso8601String(),
    });
    await Share.share(
      blob,
      subject: 'BJBank — Benchmark On-Device',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark On-Device'),
        backgroundColor: BJBankColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildIntro(),
            const SizedBox(height: 24),
            _buildIterationsPicker(),
            const SizedBox(height: 16),
            _buildRunButton(),
            const SizedBox(height: 24),
            if (_running) _buildProgress(),
            if (_error != null) _buildError(),
            if (_pqcReport != null ||
                _classicNativeReport != null ||
                _classicDartReport != null)
              _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparação PQC vs Clássico',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mede operações criptográficas NATIVAS no dispositivo em 3 pipelines:\n\n'
              '① PQC nativo (BC 1.80): ML-DSA-65, ML-KEM-768, SLH-DSA, X25519.\n'
              '② Clássico nativo (BC 1.80): ECDSA-P256, ECDH-P256.\n'
              '③ Clássico Dart (PointyCastle): ECDSA-P256, ECDH-P256.\n\n'
              '①↔② comparação fair (mesmo runtime JVM). ③ mostra o custo do '
              'runtime Dart interpretado.\n\n'
              'Métricas: P50/P95/P99/mean/stdev. ns para BC nativo, µs para Dart.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIterationsPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Iterações por operação'),
                Text(
                  '$_iterations',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: BJBankColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _iterations.toDouble(),
              min: 10,
              max: 500,
              divisions: 49,
              activeColor: BJBankColors.primary,
              label: '$_iterations',
              onChanged: _running
                  ? null
                  : (v) => setState(() => _iterations = v.toInt()),
            ),
            Text(
              _iterations < 50
                  ? 'Rápido — útil para smoke test'
                  : _iterations < 200
                      ? 'Recomendado para gráficos da tese'
                      : 'Lento — ideal para P99 estatisticamente significativo',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunButton() {
    return ElevatedButton.icon(
      onPressed: _running ? null : _run,
      icon: const Icon(Icons.play_arrow),
      label: Text(_running ? 'A correr…' : 'Correr benchmark'),
      style: ElevatedButton.styleFrom(
        backgroundColor: BJBankColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        const LinearProgressIndicator(color: BJBankColors.primary),
        const SizedBox(height: 8),
        Text(_phase, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildError() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_pqcReport != null) _buildPqcReport(_pqcReport!),
        const SizedBox(height: 16),
        if (_classicNativeReport != null)
          _buildClassicNativeReport(_classicNativeReport!),
        const SizedBox(height: 16),
        if (_classicDartReport != null)
          _buildClassicReport(_classicDartReport!),
        const SizedBox(height: 16),
        if (_pqcReport != null && _classicNativeReport != null)
          _buildFairComparison(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _exportar,
          icon: const Icon(Icons.share),
          label: const Text('Exportar JSON (partilhar)'),
        ),
      ],
    );
  }

  /// Card "comparação fair" — só mostrado quando PQC + Clássico nativo BC
  /// estão ambos disponíveis. Calcula ratios algoritmo-vs-algoritmo na
  /// mesma runtime. Material directo para a tese.
  Widget _buildFairComparison() {
    final pqc = (_pqcReport!['results'] as Map?) ?? {};
    final cls = (_classicNativeReport!['results'] as Map?) ?? {};

    String ratio(String pqcKey, String classicKey) {
      final p = (pqc[pqcKey] as Map?)?['p50'];
      final c = (cls[classicKey] as Map?)?['p50'];
      if (p == null || c == null) return '?';
      final pn = (p as num).toDouble();
      final cn = (c as num).toDouble();
      if (cn == 0) return '∞';
      final r = pn / cn;
      return r >= 1
          ? '${r.toStringAsFixed(1)}× mais lento que clássico'
          : '${(1 / r).toStringAsFixed(1)}× mais rápido que clássico';
    }

    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.balance, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Comparação fair-runtime PQC vs Clássico',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ambos medidos em BC 1.80 nativo. Ratio = PQC P50 / Clássico P50.',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
            const Divider(),
            _ratioRow('ML-DSA-65 vs ECDSA-P256 keygen',
                ratio('mldsa_keygen_ns', 'ecdsa_p256_keygen_ns')),
            _ratioRow('ML-DSA-65 vs ECDSA-P256 sign',
                ratio('mldsa_sign_ns', 'ecdsa_p256_sign_ns')),
            _ratioRow('ML-DSA-65 vs ECDSA-P256 verify',
                ratio('mldsa_verify_ns', 'ecdsa_p256_verify_ns')),
            _ratioRow('ML-KEM-768 vs ECDH-P256 handshake',
                ratio('mlkem_encap_ns', 'ecdh_p256_agree_ns')),
          ],
        ),
      ),
    );
  }

  Widget _ratioRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicNativeReport(Map<String, dynamic> r) {
    final results = r['results'] as Map?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.shield_outlined, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Clássico — BC 1.80 nativo (fair runtime)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r['device'] ?? 'unknown'} · API ${r['androidVersion'] ?? '?'} · ${r['abi'] ?? '?'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Divider(),
            if (results != null)
              ...results.entries.map((e) => _benchmarkRow(
                    label: _prettyOpName(e.key),
                    data: e.value as Map,
                    unit: 'ns',
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildPqcReport(Map<String, dynamic> r) {
    final results = r['results'] as Map?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'PQC — BouncyCastle 1.80',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r['device'] ?? 'unknown'} · API ${r['androidVersion'] ?? '?'} · ${r['abi'] ?? '?'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Divider(),
            if (results != null)
              ...results.entries.map((e) => _benchmarkRow(
                    label: _prettyOpName(e.key),
                    data: e.value as Map,
                    unit: 'ns',
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicReport(Map<String, dynamic> r) {
    final results = r['results'] as Map?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_clock, color: Colors.blueGrey),
                const SizedBox(width: 8),
                const Text(
                  'Clássico — PointyCastle (Dart)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            if (results != null)
              ...results.entries.map((e) => _benchmarkRow(
                    label: _prettyOpName(e.key),
                    data: e.value as Map,
                    unit: 'µs',
                  )),
          ],
        ),
      ),
    );
  }

  String _prettyOpName(String key) {
    return key
        .replaceAll('_ns', '')
        .replaceAll('_us', '')
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  Widget _benchmarkRow({
    required String label,
    required Map data,
    required String unit,
  }) {
    final p50 = data['p50'];
    final p95 = data['p95'];
    final mean = data['mean_ns'] ?? data['mean_us'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'P50: ${_fmt(p50)} $unit · P95: ${_fmt(p95)} $unit · μ: ${_fmt(mean)} $unit',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic n) {
    if (n == null) return '?';
    if (n is int) return n.toString();
    if (n is double) return n.toStringAsFixed(1);
    return n.toString();
  }
}
