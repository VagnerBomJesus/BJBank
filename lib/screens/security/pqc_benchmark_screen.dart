import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/pqc_metrics_model.dart';
import '../../services/pqc_benchmark_service.dart';
import '../../services/server_pqc_benchmark_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'device_benchmark_screen.dart';

/// PQC Benchmark Screen
///
/// Compara performance de ML-KEM-768 / ML-DSA-65 (FIPS 203/204) com
/// algoritmos classicos (RSA / ECDSA) usando medicoes locais + dados de
/// referencia NIST/SUPERCOP @ Intel i7-6500U.
///
/// Estado actual:
///  - Flutter: assinatura ML-DSA-65 delegada ao servidor (Edge Function
///    `flutter_sign_transfer` com @noble/post-quantum). O benchmark deste
///    ecra mede a parte cliente (serializacao + invocacao da function +
///    RTT). Para numeros puros de KEM/DSA, usar a app Kotlin (BouncyCastle
///    local) ou o benchmark do servidor.
///  - Kotlin: ML-KEM-768 + ML-DSA-65 reais via BouncyCastle 1.82
///    no proprio dispositivo.
class PqcBenchmarkScreen extends StatefulWidget {
  const PqcBenchmarkScreen({super.key});

  @override
  State<PqcBenchmarkScreen> createState() => _PqcBenchmarkScreenState();
}

class _PqcBenchmarkScreenState extends State<PqcBenchmarkScreen> {
  final _benchmarkService = PqcBenchmarkService();
  final _serverBenchmark = ServerPqcBenchmarkService();

  PqcBenchmarkReport? _report;
  bool _isRunning = false;
  double _progress = 0.0;
  String _currentOp = '';
  String? _error;

  // Server-side benchmark state
  ServerPqcBenchmarkReport? _serverReport;
  bool _isRunningServer = false;
  String? _serverError;
  int _serverIterations = 50;
  double _serverProgress = 0.0;
  String _serverProgressLabel = '';

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

  Future<void> _runServerBenchmark() async {
    setState(() {
      _isRunningServer = true;
      _serverError = null;
      _serverProgress = 0.0;
      _serverProgressLabel = 'A começar...';
    });
    try {
      final report = await _serverBenchmark.run(
        iterations: _serverIterations,
        onProgress: (p, nextAlg) {
          if (mounted) {
            setState(() {
              _serverProgress = p;
              _serverProgressLabel = nextAlg.isEmpty
                  ? 'A finalizar…'
                  : 'A medir $nextAlg…';
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _serverReport = report;
          _isRunningServer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverError = e.toString();
          _isRunningServer = false;
        });
      }
    }
  }

  Future<void> _exportServerJson() async {
    if (_serverReport == null) return;
    await Share.share(
      _serverReport!.toJson().toString(),
      subject:
          'BJBank Server PQC Benchmark — ${_serverReport!.executedAt.toIso8601String()}',
    );
  }

  Future<void> _copyServerMarkdown() async {
    if (_serverReport == null) return;
    await Clipboard.setData(
      ClipboardData(text: _serverReport!.toMarkdown()),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Markdown server-side copiado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        actions: [
          IconButton(
            tooltip: 'Benchmark On-Device (BC 1.80 + Clássico)',
            icon: const Icon(Icons.smartphone),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DeviceBenchmarkScreen(),
                ),
              );
            },
          ),
        ],
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
            _buildResultsTable(),
            const SizedBox(height: BJBankSpacing.md),
            _buildSizeOverheadCard(),
            const SizedBox(height: BJBankSpacing.md),
            _buildHybridHandshakeCard(),
            const SizedBox(height: BJBankSpacing.md),
            _buildExportButtons(),
            const SizedBox(height: BJBankSpacing.md),
            _buildMethodNote(),
          ],

          // Server-side benchmark (sempre disponivel — independente do local)
          const SizedBox(height: BJBankSpacing.lg),
          _buildServerBenchmarkSection(),

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
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _modeBadge(
                  'Flutter · ML-DSA server-side',
                  BJBankColors.primary,
                ),
                _modeBadge(
                  'Kotlin · BouncyCastle local',
                  BJBankColors.success,
                ),
                _modeBadge(
                  'Backend · @noble/post-quantum',
                  BJBankColors.quantum,
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.sm),
            const Text(
              'Compara latência e tamanho de ML-KEM-512/768/1024 e ML-DSA-44/65/87 '
              '(FIPS 203/204) com RSA-2048/3072 e ECDSA-P256 usando dados '
              'NIST/SUPERCOP. As medições locais incluem serialização e RTT até '
              'à Edge Function do Supabase.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
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

  // ── Server-side benchmark UI ──────────────────────────────────────────────

  Widget _buildServerBenchmarkSection() {
    return Card(
      color: BJBankColors.quantumLight,
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync_outlined, color: BJBankColors.quantum),
                const SizedBox(width: BJBankSpacing.sm),
                Expanded(
                  child: Text(
                    'Benchmark Server-side (primitivas reais)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BJBankColors.quantum,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.xs),
            const Text(
              'Executa ML-KEM-512/768/1024 e ML-DSA-44/65/87 na Edge Function '
              'Supabase (Deno + @noble/post-quantum). Mede só as primitivas, '
              'sem JSON/Base64/RTT. Estes são os números defensáveis para a tese.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: BJBankSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Iterações: $_serverIterations',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Slider(
                    value: _serverIterations.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 9,
                    label: '$_serverIterations',
                    onChanged: _isRunningServer
                        ? null
                        : (v) =>
                            setState(() => _serverIterations = v.toInt()),
                  ),
                ),
              ],
            ),
            Text(
              'Máx. 100 (limite CPU 2s das Edge Functions). 6 algoritmos × '
              '$_serverIterations iterações em chamadas sequenciais.',
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
            const SizedBox(height: BJBankSpacing.sm),
            FilledButton.icon(
              onPressed: _isRunningServer ? null : _runServerBenchmark,
              icon: _isRunningServer
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isRunningServer
                    ? 'A executar no servidor…'
                    : 'Executar no servidor',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: BJBankColors.quantum,
              ),
            ),
            if (_isRunningServer) ...[
              const SizedBox(height: BJBankSpacing.sm),
              LinearProgressIndicator(
                value: _serverProgress,
                color: BJBankColors.quantum,
              ),
              const SizedBox(height: 4),
              Text(
                _serverProgressLabel,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
            if (_serverError != null) ...[
              const SizedBox(height: BJBankSpacing.sm),
              Container(
                padding: const EdgeInsets.all(BJBankSpacing.sm),
                decoration: BoxDecoration(
                  color: BJBankColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _serverError!,
                  style: TextStyle(
                    fontSize: 11,
                    color: BJBankColors.error,
                  ),
                ),
              ),
            ],
            if (_serverReport != null) ...[
              const SizedBox(height: BJBankSpacing.md),
              _buildServerResultsTable(),
              const SizedBox(height: BJBankSpacing.sm),
              _buildServerExportButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServerResultsTable() {
    final r = _serverReport!;
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resultados (N=${r.iterations})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Total: ${r.totalMs.toStringAsFixed(0)} ms',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: BJBankSpacing.xs),
          Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Algoritmo · Op',
                  style:
                      TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  'Média',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  'P95',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  'Min',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  'Lv',
                  textAlign: TextAlign.right,
                  style:
                      TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Divider(height: 8),
          ...r.results.entries.expand((algEntry) {
            final alg = algEntry.key;
            final level = r.sizes[alg]?.level ?? 0;
            return algEntry.value.entries.map((opEntry) {
              final op = opEntry.key;
              final s = opEntry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '$alg · $op',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.mean.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: BJBankColors.quantum,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.p95.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.min.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$level',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            });
          }),
          const SizedBox(height: BJBankSpacing.xs),
          Text(
            'Runtime: Deno ${r.runtime['deno']} · V8 ${r.runtime['v8']}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildServerExportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exportServerJson,
            icon: const Icon(Icons.share, size: 16),
            label: const Text('JSON', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: BJBankSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyServerMarkdown,
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('Markdown', style: TextStyle(fontSize: 12)),
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
              'Onde acontece a cripto:\n'
              '  • Flutter: ML-DSA-65 corre na Edge Function Supabase '
              '(@noble/post-quantum, Deno). As latências locais incluem '
              'serialização, JWT, TLS e RTT.\n'
              '  • Kotlin: ML-KEM-768 + ML-DSA-65 reais via BouncyCastle 1.82 '
              'no proprio dispositivo (numeros mais limpos para a tese).\n\n'
              'Para custos puros das primitivas, comparar com NIST/SUPERCOP '
              '@ Intel i7-6500U: ML-KEM-768 KeyGen ≈ 0.038 ms (94K cycles), '
              'ML-DSA-65 Sign ≈ 0.18 ms (455K cycles), ML-DSA-65 Verify ≈ 0.06 ms.\n\n'
              'Tamanhos fixos por norma (FIPS 203/204):\n'
              '  • ML-KEM-768: pk 1184 B · sk 2400 B · ct 1088 B\n'
              '  • ML-DSA-65:  pk 1952 B · sk 4032 B · sig 3309 B',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
