import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Cliente Dart para a Edge Function `bench_server_pqc`.
///
/// Mede as primitivas pos-quanticas REAIS (@noble/post-quantum) corridas no
/// servidor Deno do Supabase. Util para a tese — numeros das primitivas sem
/// overhead de Base64, JSON ou RTT.
class ServerPqcBenchmarkService {
  SupabaseClient get _sb => SupabaseConfig.client;

  /// Lista dos algoritmos que o backend conhece.
  static const allAlgorithms = <String>[
    'ML-KEM-512',
    'ML-KEM-768',
    'ML-KEM-1024',
    'ML-DSA-44',
    'ML-DSA-65',
    'ML-DSA-87',
  ];

  /// Executa o benchmark server-side.
  ///
  /// Para evitar o limite de CPU (~2s) das Edge Functions Supabase, fazemos
  /// UMA invocacao por algoritmo e agregamos no cliente. [onProgress] e
  /// chamado entre algoritmos com (concluidos/total, nome do proximo).
  ///
  /// [iterations] — numero de amostras por (algoritmo, operacao). Max 100.
  /// [algorithms] — subconjunto a correr. Por defeito, todos.
  /// [payloadBytes] — tamanho da mensagem assinada (so para DSA).
  Future<ServerPqcBenchmarkReport> run({
    int iterations = 50,
    List<String>? algorithms,
    int payloadBytes = 256,
    void Function(double progress, String nextAlg)? onProgress,
  }) async {
    final algs = algorithms ?? allAlgorithms;
    if (algs.isEmpty) {
      throw Exception('Nenhum algoritmo seleccionado.');
    }

    final allResults = <String, Map<String, OpStats>>{};
    final allSizes = <String, AlgSizes>{};
    Map<String, String> runtime = {};
    var totalMs = 0.0;
    var samplePayloadBytes = payloadBytes;
    var sampleIterations = iterations;
    DateTime? sampleExecutedAt;

    for (var i = 0; i < algs.length; i++) {
      final alg = algs[i];
      if (onProgress != null) onProgress(i / algs.length, alg);

      final response = await _sb.functions.invoke(
        'bench_server_pqc',
        body: {
          'iterations': iterations,
          'payloadBytes': payloadBytes,
          'only': alg,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Resposta invalida do servidor para $alg.');
      }
      if (data['error'] != null) {
        throw Exception('$alg: ${data['error']}');
      }

      final chunk = ServerPqcBenchmarkReport.fromJson(data);
      allResults.addAll(chunk.results);
      allSizes.addAll(chunk.sizes);
      runtime = chunk.runtime;
      totalMs += chunk.totalMs;
      samplePayloadBytes = chunk.payloadBytes;
      sampleIterations = chunk.iterations;
      sampleExecutedAt = chunk.executedAt;
    }

    if (onProgress != null) onProgress(1.0, '');

    return ServerPqcBenchmarkReport(
      executedAt: sampleExecutedAt ?? DateTime.now(),
      iterations: sampleIterations,
      payloadBytes: samplePayloadBytes,
      totalMs: totalMs,
      runtime: runtime,
      sizes: allSizes,
      results: allResults,
    );
  }
}

class ServerPqcBenchmarkReport {
  final DateTime executedAt;
  final int iterations;
  final int payloadBytes;
  final double totalMs;
  final Map<String, String> runtime;
  // alg -> { pk, sk, out, level }
  final Map<String, AlgSizes> sizes;
  // alg -> op -> stats
  final Map<String, Map<String, OpStats>> results;

  ServerPqcBenchmarkReport({
    required this.executedAt,
    required this.iterations,
    required this.payloadBytes,
    required this.totalMs,
    required this.runtime,
    required this.sizes,
    required this.results,
  });

  factory ServerPqcBenchmarkReport.fromJson(Map<String, dynamic> json) {
    final sizesRaw = (json['sizes'] as Map<String, dynamic>?) ?? {};
    final sizes = <String, AlgSizes>{};
    sizesRaw.forEach((k, v) {
      sizes[k] = AlgSizes.fromJson(v as Map<String, dynamic>);
    });

    final resultsRaw = (json['results'] as Map<String, dynamic>?) ?? {};
    final results = <String, Map<String, OpStats>>{};
    resultsRaw.forEach((alg, ops) {
      final opMap = <String, OpStats>{};
      (ops as Map<String, dynamic>).forEach((op, s) {
        opMap[op] = OpStats.fromJson(s as Map<String, dynamic>);
      });
      results[alg] = opMap;
    });

    return ServerPqcBenchmarkReport(
      executedAt: DateTime.tryParse(json['executedAt'] as String? ?? '') ??
          DateTime.now(),
      iterations: (json['iterations'] as num?)?.toInt() ?? 0,
      payloadBytes: (json['payloadBytes'] as num?)?.toInt() ?? 0,
      totalMs: (json['totalMs'] as num?)?.toDouble() ?? 0.0,
      runtime: ((json['runtime'] as Map?)?.cast<String, dynamic>() ?? {})
          .map((k, v) => MapEntry(k, '$v')),
      sizes: sizes,
      results: results,
    );
  }

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('## BJBank Server-side PQC Benchmark');
    buf.writeln('**Data:** ${executedAt.toIso8601String()}');
    buf.writeln('**Iterações:** $iterations');
    buf.writeln('**Payload (DSA):** $payloadBytes bytes');
    buf.writeln('**Runtime:** Deno ${runtime['deno']} / V8 ${runtime['v8']}');
    buf.writeln('**Wall time total:** ${totalMs.toStringAsFixed(1)} ms');
    buf.writeln();
    buf.writeln(
      '| Algoritmo | Nível | Operação | Mean (ms) | Min | Max | P50 | P95 | StdDev | N |',
    );
    buf.writeln(
      '|-----------|-------|----------|-----------|-----|-----|-----|-----|--------|---|',
    );
    for (final alg in results.keys) {
      final level = sizes[alg]?.level ?? 0;
      for (final op in results[alg]!.keys) {
        final s = results[alg]![op]!;
        buf.writeln(
          '| $alg | $level | $op | ${s.mean.toStringAsFixed(3)} | ${s.min.toStringAsFixed(3)} | '
          '${s.max.toStringAsFixed(3)} | ${s.p50.toStringAsFixed(3)} | '
          '${s.p95.toStringAsFixed(3)} | ${s.stddev.toStringAsFixed(3)} | ${s.n} |',
        );
      }
    }
    buf.writeln();
    buf.writeln('### Tamanhos oficiais (FIPS 203/204)');
    buf.writeln('| Algoritmo | Nível | pk (B) | sk (B) | ct/sig (B) |');
    buf.writeln('|-----------|-------|--------|--------|------------|');
    for (final alg in sizes.keys) {
      final s = sizes[alg]!;
      buf.writeln('| $alg | ${s.level} | ${s.pk} | ${s.sk} | ${s.out} |');
    }
    return buf.toString();
  }

  /// JSON serializado da resposta completa.
  Map<String, dynamic> toJson() => {
        'executedAt': executedAt.toIso8601String(),
        'iterations': iterations,
        'payloadBytes': payloadBytes,
        'totalMs': totalMs,
        'runtime': runtime,
        'sizes': sizes.map((k, v) => MapEntry(k, v.toJson())),
        'results': results.map(
          (k, v) =>
              MapEntry(k, v.map((op, s) => MapEntry(op, s.toJson()))),
        ),
      };

  @override
  String toString() => 'ServerPqcBenchmarkReport(n=$iterations, '
      'algs=${results.keys.toList()}, total=${totalMs.toStringAsFixed(1)}ms)';
}

@immutable
class AlgSizes {
  final int pk;
  final int sk;
  final int out;
  final int level;

  const AlgSizes(
      {required this.pk,
      required this.sk,
      required this.out,
      required this.level});

  factory AlgSizes.fromJson(Map<String, dynamic> j) => AlgSizes(
        pk: (j['pk'] as num).toInt(),
        sk: (j['sk'] as num).toInt(),
        out: (j['out'] as num).toInt(),
        level: (j['level'] as num).toInt(),
      );

  Map<String, dynamic> toJson() =>
      {'pk': pk, 'sk': sk, 'out': out, 'level': level};
}

@immutable
class OpStats {
  final double mean;
  final double min;
  final double max;
  final double p50;
  final double p95;
  final double stddev;
  final int n;

  const OpStats({
    required this.mean,
    required this.min,
    required this.max,
    required this.p50,
    required this.p95,
    required this.stddev,
    required this.n,
  });

  factory OpStats.fromJson(Map<String, dynamic> j) => OpStats(
        mean: (j['mean'] as num).toDouble(),
        min: (j['min'] as num).toDouble(),
        max: (j['max'] as num).toDouble(),
        p50: (j['p50'] as num).toDouble(),
        p95: (j['p95'] as num).toDouble(),
        stddev: (j['stddev'] as num).toDouble(),
        n: (j['n'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'mean': mean,
        'min': min,
        'max': max,
        'p50': p50,
        'p95': p95,
        'stddev': stddev,
        'n': n,
      };
}
