# ADR-003: Estratégia de Benchmarking de Desempenho PQC

**Data:** 2026-02-18
**Estado:** Aceite
**Contexto:** Metodologia para medir e comparar desempenho PQC vs. criptografia clássica

---

## Contexto e Problema

Para validar quantitativamente a viabilidade da transição PQC em mobile banking, é
necessária uma metodologia de benchmarking rigorosa que:

1. Meça latências observáveis no dispositivo (Dart `Stopwatch`)
2. Compare com valores de referência NIST/SUPERCOP
3. Documente limitações da metodologia (simulação vs. operações reais)
4. Produza artefactos exportáveis para dissertação (JSON, Markdown)

---

## Decisão

**Implementar benchmarking em 3 camadas:**

### Camada 1: Latência de Parede (Wall-Clock Time)

```dart
final stopwatch = Stopwatch()..start();
await pqcOperation();
stopwatch.stop();
final wallTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
```

- Ferramenta: `dart:core Stopwatch` (resolução ~1µs no Android/iOS)
- N iterações: 10 (padrão) a 100 (modo rigoroso)
- Estatísticas: média, mín, máx, P95 (percentil 95)
- **Limitação**: Inclui overhead de serialização, I/O, GC Dart — não reflete custo
  criptográfico puro

### Camada 2: Tamanho de Dados (Bytes)

Comparação direta de tamanhos de chaves, assinaturas e ciphertexts conforme especificações
NIST, sem necessidade de medição em runtime.

### Camada 3: Energia (Modelo Estimado)

```dart
double energyScore = k * outputSizeBytes * avgWallTimeMs;
// k = constante de proporcionalidade (indicativa)
```

**Nota**: Modelo puramente indicativo. Medição real requereria Android Battery Historian
ou iOS Energy Log — fora do scope desta dissertação.

---

## Tabela de Referência NIST/SUPERCOP

*Hardware de referência: Intel Core i7-6500U @ 2.5GHz (SUPERCOP benchmark)*

### Algoritmos PQC (NIST FIPS 203/204)

| Algoritmo | Tipo | Pk (B) | Sk (B) | Sig/CT (B) | KeyGen (cycles) | Sign/Enc (cycles) | Verify/Dec (cycles) |
|-----------|------|--------|--------|-----------|----------------|------------------|-------------------|
| Dilithium2 | Assinatura | 1,312 | 2,528 | 2,420 | 125,436 | 141,040 | 109,580 |
| Dilithium3 | Assinatura | 1,952 | 4,000 | 3,293 | 203,472 | 231,888 | 171,872 |
| Dilithium5 | Assinatura | 2,592 | 4,864 | 4,595 | 287,396 | 327,436 | 242,732 |
| Kyber512 | KEM | 800 | 1,632 | 768 | 56,732 | 61,820 | 64,628 |
| Kyber768 | KEM | 1,184 | 2,400 | 1,088 | 94,136 | 104,388 | 109,148 |
| Kyber1024 | KEM | 1,568 | 3,168 | 1,568 | 137,948 | 151,212 | 154,704 |

### Algoritmos Clássicos (NIST SP 800-56 + SUPERCOP)

| Algoritmo | Tipo | Pk (B) | Sk (B) | Sig/CT (B) | KeyGen (cycles) | Sign/Enc (cycles) | Verify/Dec (cycles) |
|-----------|------|--------|--------|-----------|----------------|------------------|-------------------|
| RSA-2048 | Assinatura/KEM | 256 | 1,192 | 256 | 3,200,000 | 1,700,000 | 30,000 |
| RSA-4096 | Assinatura/KEM | 512 | 2,384 | 512 | 25,000,000 | 12,000,000 | 120,000 |
| ECDSA-256 | Assinatura | 64 | 32 | 72 | 150,000 | 250,000 | 650,000 |
| ECDSA-384 | Assinatura | 96 | 48 | 104 | 280,000 | 400,000 | 950,000 |
| ECDH-P256 | KEM | 64 | 32 | 65 | 150,000 | 200,000 | 200,000 |
| ECDH-P384 | KEM | 96 | 48 | 97 | 280,000 | 350,000 | 350,000 |

### Conversão Cycles → ms (@ 2.5GHz)

```
ms = cycles / (2,500,000,000 / 1,000) = cycles / 2,500,000
```

Exemplos:
- Dilithium3 KeyGen: 203,472 / 2,500,000 = **0.081ms** (vs ECDSA-256: 0.060ms)
- Dilithium3 Sign: 231,888 / 2,500,000 = **0.093ms** (vs ECDSA-256: 0.100ms)
- RSA-2048 KeyGen: 3,200,000 / 2,500,000 = **1.280ms** (25× mais lento que Dilithium3!)

---

## Limitações Documentadas

| Limitação | Impacto | Mitigação |
|-----------|---------|-----------|
| Latências simuladas ≠ custo criptográfico real | Alto — não reflete NTT, Module-LWE | Reportar valores NIST como referência |
| Overhead GC Dart | Médio — JIT/AOT afeta medições | N≥10 iterações, reportar mediana |
| Variação hardware mobile | Alto — ARM vs x86 vs Apple Silicon | Reportar hardware do dispositivo de teste |
| Thermal throttling | Médio — afeta benchmarks longos | Pausas entre operações; reportar temperatura |
| Single-threaded Dart isolate | Baixo — Dart VM tem 1 thread por defeito | Usar Future.microtask para isolamento |

---

## Formato de Exportação

### JSON
```json
{
  "executedAt": "2026-02-18T...",
  "deviceInfo": "Android 14 / ARM64",
  "iterationsPerOp": 10,
  "implementationMode": "simulation",
  "pqcOperations": [...],
  "classicalComparison": [...],
  "hybridHandshake": {...}
}
```

### Markdown Table (para dissertação)
```markdown
| Algoritmo | Operação | Tempo Médio (ms) | P95 (ms) | Tamanho (bytes) | Nível NIST |
|-----------|----------|-----------------|---------|----------------|-----------|
| Dilithium3 | KeyGen | 25.3 | 28.1 | pk:1952 | 3 |
```

---

## Referências

- NIST PQC Round 3 Finalists: https://csrc.nist.gov/projects/post-quantum-cryptography
- SUPERCOP: https://bench.cr.yp.to/supercop.html
- NIST SP 800-227 (Draft): Key-Encapsulation Mechanisms
- Bernstein et al., "Post-Quantum Cryptography" (2009) — Springer
- Avanzi et al., "CRYSTALS-Kyber Algorithm Specifications" v3.02 (2021)
- Ducas et al., "CRYSTALS-Dilithium Algorithm Specifications" v3.1 (2021)
