# ADR-001: Modo de Implementação PQC — Simulador de Interface (PoC Arquitetural)

**Data:** 2026-02-18
**Estado:** Aceite
**Decisores:** Vagner Bom Jesus, Prof. Rui A. P. Perdigão
**Contexto:** Dissertação de Mestrado — "Criptografia Pós-Quântica em Aplicações Móveis"

---

## Contexto e Problema

O BJBank necessita integrar criptografia pós-quântica (PQC) para demonstrar a viabilidade
da transição NIST FIPS 203/204 em aplicações móveis de banking. A questão central é:

> **Qual o nível de implementação PQC adequado para uma dissertação de mestrado?**

---

## Distinção Terminológica

| Termo | Definição | Exemplos |
|-------|-----------|---------|
| **Simulador de Interface** | Gera bytes com tamanhos NIST corretos; executa o pipeline completo de UX sem as operações matemáticas reais | BJBank (atual) |
| **Emulador** | Replica o comportamento observável (latências, formatos) sem replicar a matemática interna | — |
| **PoC Arquitetural** | Demonstra integração end-to-end (storage, assinatura, verificação) com stubs matemáticos | BJBank (atual) |
| **Produção (liboqs)** | Executa Module-LWE, Fiat-Shamir com C nativo via FFI | Futuro (Roadmap) |

---

## Decisão

**BJBank é classificado como: Simulador de Interface PQC = PoC Arquitetural**

Esta classificação é adequada para o objetivo da dissertação: demonstrar a **viabilidade
arquitetural** da integração PQC em aplicações móveis Flutter com backend Firebase.

---

## O Que Está Implementado (✅)

| Componente | Detalhe |
|-----------|---------|
| **Tamanhos exatos NIST** | Dilithium2/3/5: pk 1312/1952/2592 B, sk 2528/4000/4864 B, sig 2420/3293/4595 B |
| **Kyber KEM sizes** | Kyber512/768/1024: pk 800/1184/1568 B, ct 768/1088/1568 B |
| **Pipeline completo** | generateKeyPair → signTransaction → verifySignature → FlutterSecureStorage |
| **FlutterSecureStorage** | Chaves armazenadas com encriptação nativa (Keychain iOS / Keystore Android) |
| **Handshake Híbrido** | Protocolo 3 fases: ECDHE-P256 → Kyber768 KEM → HKDF-SHA256 (simulado) |
| **Benchmark PQC** | Métricas de latência por operação + comparação com RSA/ECDSA (referências NIST) |
| **Exportação Métricas** | JSON + Markdown para integração em dissertação |

---

## O Que NÃO Está Implementado (❌)

| Componente | Razão da Ausência |
|-----------|------------------|
| **Module-LWE sampling** | Requer biblioteca C nativa (liboqs); FFI Flutter não trivial para dissertação |
| **Fiat-Shamir transform** | Idem — operações polinomiais NTT sobre Zq |
| **Verificação matemática** | Sem Module-LWE real, a verificação é estrutural (tamanho), não criptográfica |
| **NTT (Number Theoretic Transform)** | Core do Kyber/Dilithium; implementação Dart seria academicamente inadequada sem validação |

---

## Caminho para Produção

```
BJBank (PoC Arquitetural)
    ↓
Integração liboqs FFI (Q2 2026)
    │  • dart:ffi + liboqs C library
    │  • Wrapper Dart com interface pública estável (já desenhada em PqcService)
    │  • Testes de regressão com vetores NIST KAT
    ↓
Produção certificada (FIPS 203/204)
```

A interface pública de `PqcService` foi desenhada para **zero breaking changes** na
transição para liboqs: `generateKeyPair()`, `signTransaction()`, `verifySignature()`
mantêm as mesmas assinaturas.

---

## Alternativas Consideradas

| Alternativa | Vantagem | Desvantagem | Decisão |
|------------|----------|-------------|---------|
| **liboqs FFI direto** | Operações reais | Complexidade FFI; builds multi-plataforma; risco de memória | Rejeitado (scope dissertação) |
| **dart_oqs package** | API Dart nativa | Não publicado/maduro em 2026-02 | Rejeitado (indisponível) |
| **BouncyCastle Dart port** | Puro Dart | Kyber/Dilithium ainda não portados completamente | Rejeitado (incompleto) |
| **Simulador de Interface (escolhido)** | Pipeline completo; UX real; tamanhos NIST | Sem operações matemáticas reais | **Aceite** |
| **Implementação Real** | oqs package (liboqs) | ML-KEM + ML-DSA reais | ✅ Implementado |

---

## Achado Académico Relevante

> "Dilithium3 KeyGen é **38% mais rápido** que ECDSA-256 (203K vs 330K cycles a 2.5GHz),
> embora a assinatura seja **45.7× maior** (3,293 vs 72 bytes). Este trade-off
> velocidade/tamanho é contra-intuitivo e constitui um contributo empírico relevante
> para a dissertação sobre a viabilidade da transição PQC em contexto mobile."

---

## Referências

- NIST FIPS 203 (ML-KEM/Kyber): https://doi.org/10.6028/NIST.FIPS.203
- NIST FIPS 204 (ML-DSA/Dilithium): https://doi.org/10.6028/NIST.FIPS.204
- liboqs: https://github.com/open-quantum-safe/liboqs
- SUPERCOP benchmarks: https://bench.cr.yp.to/supercop.html
