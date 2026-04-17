import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/pqc_metrics_model.dart';
import '../../services/pqc_benchmark_service.dart';
import '../../services/pqc_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// PQC Benchmark Screen
///
/// Compares Post-Quantum Cryptography (Dilithium/Kyber) performance against
/// classical algorithms (RSA/ECDSA) using on-device measurements and NIST
/// reference data.
///
/// See ADR-001 (implementation mode), ADR-002 (hybrid handshake),
/// ADR-003 (benchmarking methodology) for context.
class PqcBenchmarkScreen extends StatefulWidget {
  const PqcBenchmarkScreen({super.key});

  @override
  State<PqcBenchmarkScreen> createState() => _PqcBenchmarkScreenState();
}

class _PqcBenchmarkScreenState extends State<PqcBenchmarkScreen> {
  final _benchmarkService = PqcBenchmarkService();

  PqcBenchmarkReport? _report;
  bool _isRunning = false;
  double _progress = 0.0;
  String _currentOp = '';
  String? _error;

  Future<void> _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _progress = 0.0;
      _currentOp = 'A iniciar…';
      _error = null;
    });

    try {
      final report = await _benchmarkService.runFullBenchmark(
        iterationsPerOp: 10,
        onProgress: (progress, currentOp) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _currentOp = currentOp;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _report = report;
          _isRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _exportJson() async {
    if (_report == null) return;
    final json = _report!.toJsonString();
    await Share.share(
      json,
      subject: 'BJBank PQC Benchmark — ${_report!.executedAt.toIso8601String()}',
    );
  }

  Future<void> _copyMarkdown() async {
    if (_report == null) return;
    final md = _report!.toMarkdownTable();
    await Clipboard.setData(ClipboardData(text: md));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tabela Markdown copiada para a área de transferência'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark PQC'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          // 1. Introduction card
          _buildIntroCard(),

          const SizedBox(height: BJBankSpacing.md),

          // 2. Run button + progress
          _buildRunSection(),

          if (_error != null) ...[
            const SizedBox(height: BJBankSpacing.md),
            _buildErrorCard(),
          ],

          if (_report != null) ...[
            const SizedBox(height: BJBankSpacing.lg),

            // 3. Results table
            _buildResultsTable(),

            const SizedBox(height: BJBankSpacing.md),

            // 4. Size overhead bars
            _buildSizeOverheadCard(),

            const SizedBox(height: BJBankSpacing.md),

            // 5. Hybrid handshake card
            _buildHybridHandshakeCard(),

            const SizedBox(height: BJBankSpacing.md),

            // 6. Export buttons
            _buildExportButtons(),

            const SizedBox(height: BJBankSpacing.md),

            // 7. Methodological note
            _buildMethodNote(),
          ],

          const SizedBox(height: BJBankSpacing.xl),
        ],
      ),
    );
  }

  // ── Section builders ────────────────────────────────────────────────────────

  Widget _buildIntroCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: BJBankColors.primary),
                const SizedBox(width: BJBankSpacing.sm),
                Expanded(
                  child: Text(
                    'Benchmark PQC vs. Clássico',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.sm),
            Builder(builder: (context) {
              final mode = PqcService.currentMode;
              final badgeText = mode == PqcImplementationMode.production
                  ? 'Modo: Produção (liboqs real)'
                  : 'Modo: Simulação (PoC Arquitetural) — ver ADR-001';
              final badgeColor = mode == PqcImplementationMode.production
                  ? BJBankColors.success
                  : BJBankColors.warning;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BJBankSpacing.sm,
                  vertical: BJBankSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    color: badgeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
            const SizedBox(height: BJBankSpacing.sm),
            const Text(
              'Mede latências de serialização para Dilithium2/3/5 e Kyber512/768/1024 '
              'e compara com valores de referência NIST/SUPERCOP para RSA e ECDSA.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _isRunning ? null : _runBenchmark,
              icon: _isRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'A executar…' : 'Executar Benchmark'),
            ),
            if (_isRunning) ...[
              const SizedBox(height: BJBankSpacing.sm),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: BJBankSpacing.xs),
              Text(
                _currentOp,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Text(
          'Erro: $_error',
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }

  Widget _buildResultsTable() {
    final report = _report!;

    // Build combined rows: PQC operations + classical reference
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.sm),

            // PQC operations
            Text(
              'PQC (Medido no dispositivo)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BJBankColors.primary,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.xs),
            ...report.pqcOperations.map((op) => _buildPqcRow(op)),

            const SizedBox(height: BJBankSpacing.md),
            const Divider(),
            const SizedBox(height: BJBankSpacing.xs),

            // Classical reference
            Text(
              'Clássico (Referência NIST/SUPERCOP @ 2.5GHz)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: BJBankSpacing.xs),
            ...report.classicalComparison.map((c) => _buildClassicalRow(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildPqcRow(PqcOperationMetrics op) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${op.algorithm} ${op.operation}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${op.avgWallTimeMs.toStringAsFixed(1)} ms',
              style: TextStyle(
                fontSize: 12,
                color: BJBankColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${op.outputSizeBytes} B',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicalRow(ClassicalComparisonData c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(
                  c.algorithm,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(width: 4),
                const Text(
                  '❌Q',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${c.keyGenMs.toStringAsFixed(3)} ms',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${c.publicKeySizeBytes} B',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeOverheadCard() {
    // Compare signature sizes: Dilithium3 vs ECDSA-256
    // Compare ciphertext sizes: Kyber768 vs ECDH-P256
    const dilithium3Sig = 3293;
    const ecdsa256Sig = 72;
    const kyber768Ct = 1088;
    const ecdhP256Ct = 65;
    final maxVal = dilithium3Sig.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overhead de Tamanho',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.sm),
            const Text(
              'Assinatura Digital',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: BJBankSpacing.xs),
            _buildSizeBar(
              label: 'Dilithium3',
              bytes: dilithium3Sig,
              maxBytes: maxVal,
              color: BJBankColors.primary,
            ),
            _buildSizeBar(
              label: 'ECDSA-256',
              bytes: ecdsa256Sig,
              maxBytes: maxVal,
              color: Colors.grey,
            ),
            const SizedBox(height: BJBankSpacing.sm),
            const Text(
              'Encapsulamento de Chave (KEM)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: BJBankSpacing.xs),
            _buildSizeBar(
              label: 'Kyber768 ct',
              bytes: kyber768Ct,
              maxBytes: maxVal,
              color: Colors.teal,
            ),
            _buildSizeBar(
              label: 'ECDH-P256',
              bytes: ecdhP256Ct,
              maxBytes: maxVal,
              color: Colors.grey,
            ),
            const SizedBox(height: BJBankSpacing.xs),
            Text(
              'Dilithium3 assina ${(dilithium3Sig / ecdsa256Sig).toStringAsFixed(1)}× '
              'maior que ECDSA-256, mas KeyGen é ~38% mais rápido (203K vs 330K cycles).',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeBar({
    required String label,
    required int bytes,
    required double maxBytes,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: bytes / maxBytes,
              color: color,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Text(
            '$bytes B',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHybridHandshakeCard() {
    final h = _report!.hybridHandshake;
    if (h == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Handshake Híbrido',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.xs),
            Text(
              'TLS ECDHE-P256 + ${h.kemAlgorithm} KEM + HKDF-SHA256',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: BJBankSpacing.md),

            // Phase diagram
            IntrinsicHeight(
              child: Row(
                children: [
                  _buildPhaseBox(
                    'ECDHE\n${h.classicalPhaseMs.toStringAsFixed(0)} ms',
                    Colors.blue.shade100,
                    Colors.blue.shade700,
                  ),
                  _buildArrow(),
                  _buildPhaseBox(
                    '${h.kemAlgorithm}\n${h.kemPhaseMs.toStringAsFixed(0)} ms',
                    BJBankColors.primary.withValues(alpha: 0.15),
                    BJBankColors.primary,
                  ),
                  _buildArrow(),
                  _buildPhaseBox(
                    'HKDF\n${h.kdfPhaseMs.toStringAsFixed(0)} ms',
                    Colors.green.shade100,
                    Colors.green.shade700,
                  ),
                ],
              ),
            ),

            const SizedBox(height: BJBankSpacing.md),
            const Divider(),
            const SizedBox(height: BJBankSpacing.xs),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHandshakeMetric(
                  'Total',
                  '${h.totalMs.toStringAsFixed(1)} ms',
                ),
                _buildHandshakeMetric(
                  'Overhead PQC',
                  '+${h.pqcOverheadBytes} bytes',
                ),
                _buildHandshakeMetric(
                  'Session Key',
                  '${h.combinedSecretSizeBytes * 8}-bit',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseBox(String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.xs,
          vertical: BJBankSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
    );
  }

  Widget _buildHandshakeMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: BJBankColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exportJson,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Exportar JSON'),
          ),
        ),
        const SizedBox(width: BJBankSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyMarkdown,
            icon: const Icon(Icons.content_copy, size: 18),
            label: const Text('Copiar Markdown'),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodNote() {
    return Card(
      color: Colors.amber.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                const SizedBox(width: BJBankSpacing.xs),
                Text(
                  'Nota Metodológica',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.amber.shade800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.xs),
            const Text(
              'As latências medidas refletem overhead de serialização e I/O do PoC '
              'Arquitetural, NÃO o custo criptográfico real das operações Module-LWE '
              'ou Fiat-Shamir. Consulte os valores NIST/SUPERCOP (ADR-003) para '
              'comparação com hardware de referência (Intel i7-6500U @ 2.5GHz).\n\n'
              'Exemplo: Kyber768 KeyGen real ≈ 0.038ms (94K cycles). '
              'A latência medida aqui (~18ms) inclui geração de bytes aleatórios, '
              'codificação Base64, e overhead do Dart VM.',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
