# ADR-002: Design do Handshake Híbrido TLS + Kyber KEM

**Data:** 2026-02-18
**Estado:** Aceite
**Contexto:** Protocolo de estabelecimento de sessão segura combinando criptografia clássica e pós-quântica

---

## Contexto e Problema

A transição para PQC não pode ser abrupta: sistemas legados e infraestrutura de rede
continuarão a usar ECDHE/RSA por anos. A solução é um **handshake híbrido** que:

1. Mantém compatibilidade com TLS 1.3 existente (ECDHE-P256)
2. Adiciona proteção pós-quântica via Kyber768 KEM
3. Combina os segredos com HKDF para que a sessão seja segura se **qualquer um** dos
   dois mecanismos se mantiver seguro

> Este design segue NIST SP 800-227 (Draft) e o princípio "harvest now, decrypt later":
> mesmo que um adversário capture o tráfego hoje, não conseguirá decifrar com um
> futuro computador quântico.

---

## Decisão

**Implementar `PqcHybridHandshake` com protocolo 3 fases:**

```
Cliente                                    Servidor
  │                                            │
  │─── Fase 1: TLS ECDHE-P256 ───────────────►│
  │   (ephemeral key exchange, ~15ms)          │
  │◄── shared_secret_classical (32 bytes) ────│
  │                                            │
  │─── Fase 2: Kyber768 KEM ─────────────────►│
  │   (encapsulation, pk=1184B, ct=1088B)      │
  │◄── shared_secret_kyber (32 bytes) ────────│
  │                                            │
  │─── Fase 3: HKDF-SHA256 ──────────────────►│
  │   combined_secret = HKDF(                  │
  │     classical || kyber,                    │
  │     salt="bjbank-hybrid-v1"               │
  │   )                                        │
  │◄── session_key (32 bytes) ────────────────│
```

---

## Design da Classe

```dart
class PqcHybridHandshake {
  Future<PqcHybridHandshakeResult> execute({
    required String clientId,
    required String serverId,
    PqcAlgorithm kemAlgorithm = PqcAlgorithm.kyber768,
  }) async {
    // Fase 1: ECDHE-P256 (~15ms simulado)
    // Fase 2: Kyber768 KEM (~25ms simulado)
    // Fase 3: HKDF-SHA256 (~3ms simulado)
    // Total: ~43ms, overhead: +2,272 bytes
  }
}
```

### `PqcHybridHandshakeResult`

```dart
class PqcHybridHandshakeResult {
  final String clientId;
  final String serverId;
  final PqcAlgorithm kemAlgorithm;     // kyber768
  final double classicalPhaseMs;       // ~15ms
  final double kemPhaseMs;             // ~25ms
  final double kdfPhaseMs;             // ~3ms
  final double totalMs;                // ~43ms
  final int kemPublicKeySizeBytes;     // 1184
  final int kemCiphertextSizeBytes;    // 1088
  final int combinedSecretSizeBytes;   // 32
  final PqcImplementationMode mode;    // simulation
  final DateTime executedAt;

  int get pqcOverheadBytes =>          // 2272
      kemPublicKeySizeBytes + kemCiphertextSizeBytes;
}
```

---

## Métricas Alvo por Fase

| Fase | Operação | Latência Alvo | Tamanho |
|------|----------|---------------|---------|
| 1 | ECDHE-P256 KeyExchange | < 20ms | 32 bytes (shared secret) |
| 2 | Kyber768 KeyGen + Encaps | < 30ms | 1,184 + 1,088 bytes |
| 3 | HKDF-SHA256 | < 5ms | 32 bytes (session key) |
| **Total** | **Handshake completo** | **< 55ms** | **+2,272 bytes overhead** |

*Nota: Latências são de serialização/I/O simuladas. Latências reais Kyber768:*
- *KeyGen: 94,136 cycles @ 2.5GHz ≈ 0.038ms*
- *Encaps: 104,388 cycles ≈ 0.042ms*
- *Decaps: 109,148 cycles ≈ 0.044ms*

---

## Justificação do Kyber768

| Algoritmo | Nível NIST | Pk (B) | Ct (B) | Overhead Total |
|-----------|-----------|--------|--------|----------------|
| Kyber512 | 1 (128-bit) | 800 | 768 | 1,568 B |
| **Kyber768** | **3 (192-bit)** | **1,184** | **1,088** | **2,272 B** |
| Kyber1024 | 5 (256-bit) | 1,568 | 1,568 | 3,136 B |

Kyber768 oferece o melhor equilíbrio entre segurança (192-bit pós-quântico ≈ AES-192)
e overhead de rede para aplicações móveis banking.

---

## Propriedades de Segurança

1. **Forward Secrecy**: Chaves ECDHE são efémeras (descartadas após handshake)
2. **Harvest-Now-Decrypt-Later Protection**: Kyber768 resiste a computadores quânticos
3. **Downgrade Resistance**: Combined secret requer que **ambos** os mecanismos sejam
   comprometidos; falha de apenas um não compromete a sessão
4. **IND-CCA2**: Kyber768 é IND-CCA2 seguro sob Module-LWE hardness assumption

---

## Referências

- NIST SP 800-227 (Draft): Recommendations for Key-Encapsulation Mechanisms
- RFC 9180: Hybrid Public Key Encryption (HPKE)
- ETSI TS 103 744: Quantum-Safe Hybrid Key Exchanges
- IETF draft-ietf-tls-hybrid-design: Hybrid key exchange in TLS 1.3
- Kyber specification: https://pq-crystals.org/kyber/
