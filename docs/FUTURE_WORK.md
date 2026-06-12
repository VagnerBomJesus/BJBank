# BJBank — Trabalhos Futuros

**Documento:** Roadmap explícito post-tese.
**Última actualização:** 2026-06-12 (v1.4.0).
**Audiência:** capítulo §8 da dissertação + contribuidores futuros do projeto.

---

## 1. iOS — plugin Swift análogo ao Android

**Estado actual:** iOS roda em modo server-managed (chave PQC vive no servidor para devices iOS, igual ao protótipo v1.0). `DevicePqcService.isAvailable()` retorna `false` e o `SupabaseTransferService` faz fallback automático.

**Esforço estimado:** 5-10 dias.

### O que falta

| Item | Como |
|---|---|
| Plugin Swift `PqcPlugin.swift` análogo ao Kotlin | `FlutterPlugin` + `MethodChannel` `com.bjbank.ipg/pqc` |
| ML-DSA-65 + ML-KEM-768 nativo iOS | **Opção A** liboqs como `xcframework` via CocoaPods. **Opção B** swift-crypto extension (não tem PQC built-in ainda em 2026). **Opção C** pqcrystals-dilithium C reference compilada como library binária |
| Chave privada em Secure Enclave | `kSecAttrTokenIDSecureEnclave` + `SecKeyCreateRandomKey` para wrapping key; ML-DSA priv encriptada com wrapping key |
| Equivalente `EncryptedSharedPreferences` | Keychain com `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` + `kSecAttrSynchronizable=false` |
| Bloquear iCloud Keychain sync da privada PQC | atributo acima resolve |
| Testes paridade comportamental Android ↔ iOS | Suite de fixtures (mesmas chaves, mesmo wire) |

### Riscos
- liboqs build pipeline iOS é frágil — depende de Xcode version, target arch, etc.
- Secure Enclave tem limites de tamanho de chave; ML-DSA-65 priv = 4032B pode não caber directamente. Solução: wrap com chave SE-resident.
- Apple App Store review pode questionar uso de criptografia não-Apple — declarar via `ITSAppUsesNonExemptEncryption=NO` e adicionar nota de classificação.

---

## 2. Validação experimental em hardware real

**Estado actual:** todos os benchmarks medidos em emulador `sdk_gphone64_x86_64` (Android API 36, x86_64). Resultados publicados na dissertação referem-se a este ambiente.

**Esforço:** 1 dia (se já tens devices), 1 semana se precisas de adquirir.

### Devices recomendados (cobertura espectro mobile)

| Device | SoC | Porquê |
|---|---|---|
| Pixel 7/8 | Tensor G2/G3 (ARM Cortex-A78/A715) | Referência Android puro |
| Samsung Galaxy A54 mid-range | Exynos 1380 | Mass-market dominante PT |
| Qualquer dispositivo low-end Android 12+ | Snapdragon 4 series | Pior caso latência |
| iPhone 13+ (após plugin Swift) | A15+ | Comparação Apple Silicon |

### Métricas a recolher

- P50/P95/P99 em ns para cada operação PQC + clássico nativo BC + clássico Dart.
- Energy delta (mWh) via `BatteryManager` API entre teste e baseline idle — opcional mas forte para tese.
- Heap usage durante batch — verificar pressão GC durante ML-DSA verify (operações pesadas em ints).
- Thermal throttling — correr 5×500 iter sequenciais e verificar se P50 sobe (CPU clock desce).

### Comparação cross-device

Gráfico essencial para §6: 4 devices × 3 pipelines × 6 operações = matriz colorida. Mostra que **PQC overhead é consistente entre hardware**, não outlier do emulador.

---

## 3. Side-channel hardening

**Estado actual:** o código usa BC 1.80 que tem mitigações constant-time em algumas operações ML-KEM/ML-DSA (cite changelog BC), mas não há validação empírica neste projecto.

**Trabalho futuro:**
- Timing analysis via Mona Lisa / dudect em laboratório dedicado.
- Verificação que `MLDSAPrivateKeyParameters` não faz allocations dependentes da chave.
- Substituir comparação byte-a-byte de assinaturas por `MessageDigest.isEqual` (constant-time) onde aplicável.
- Citação obrigatória: **Banegas et al., "Concrete quantum-resistance" SoK CHES 2024** + **Howe et al., "TimeCryptAnalyse"**.

---

## 4. Protocol-level enhancements

### 4.1 Forward secrecy multi-session (KEM rotation)

Actualmente cada handshake KEM gera nova efémera, mas a chave **ML-DSA do utilizador** é long-term. Comprometida → revogação manual. Trabalho futuro:

- **Key transparency** estilo CONIKS — publicação verificável de pubkeys com Merkle tree assinada.
- **Key rotation automática client-side** — gerar nova ML-DSA a cada N transferências ou T tempo, sem perda de histórico.
- Compatibilidade com `revokeKey` actual.

### 4.2 Hybrid PFS triplo

Actualmente o handshake usa apenas ML-KEM-768. Para resistir a falhas catastróficas em lattices, adicionar como camada extra:

- **X25519 + ML-KEM-768 + Classic-McEliece-460896** — McEliece é code-based, assunção independente de lattice.
- Combiner HKDF expandido para 3 segredos.
- Custo: ~250KB pubkey McEliece — proibitivo para mobile na maioria dos casos, mas viável para handshake inicial (não por sessão).

### 4.3 Verifiable random function (VRF) para serial

Actualmente o serial é monotónico determinístico. Para resistência contra um atacante que vê o stream:

- Implementar VRF baseado em ML-DSA assinatura sobre `(sessionId, counter)`.
- Serial deixa de ser previsível mas continua a evitar replay.
- Custo: +1 ML-DSA sign por transferência (~5ms).

---

## 5. Operação e observabilidade

| Item | Porque importa |
|---|---|
| **Telemetria opt-in de benchmarks** | Recolher estatísticas reais de produção PQC across user base — material para paper follow-up |
| **Dashboard Grafana com métricas Edge Functions** | Latência p95/p99 por operação, taxa de erro `kemCipherInvalid`, rotações de chave |
| **Alertas Sentry para `_kemCompletePending` timeout** | Detectar quebra de handshake |
| **Logging estruturado JSON** | Substituir `debugPrint` por `logger` package com níveis |
| **APM end-to-end tracing** | OpenTelemetry trace de request → Edge → Postgres |

---

## 6. Funcionalidades banking não-PQC pendentes

Estas são features de produto, não de tese, mas fazem parte do roadmap se o projecto continuar:

| Feature | Estado | Esforço |
|---|---|---|
| QR Code transferência (parse + assinar) | Placeholder "Em breve" | 1-2 dias |
| Push notifications FCM | Schema OK, falta backend trigger | 2-3 dias |
| Cards CRUD virtual real | Mock, falta schema + RPCs + UI | 5-7 dias |
| Open Banking PSD2 | Não existe | 3-4 semanas (regulatório) |
| Splash screen branded | Default Flutter | 30 min `flutter_native_splash` |
| Tratamento offline + retry exponential backoff | Inexistente | 1-2 dias |
| Onboarding tour first-time-user | Não existe | 1 dia |

---

## 7. Compliance e regulação (banca real)

Se a app vier a ser produto:

- **PSD2 SCA** — Strong Customer Authentication two-factor (já temos OTP email, falta biometric attestation + dynamic linking)
- **GDPR DPIA** — Data Protection Impact Assessment formal
- **eIDAS** — assinaturas qualificadas se houver assinatura de contratos
- **DORA** — Digital Operational Resilience Act (2025+ obrigatório para banca EU)
- **Cyber Resilience Act** — para produtos software com componente cripto
- **NIS2** — segurança de redes para entidades críticas
- **Penetration testing certificado** por entidade externa
- **Bug bounty programme**

---

## 8. Investigação futura específica para academia

### 8.1 Paper follow-up — "PQC verify is faster than ECDSA in mobile hot paths"

Observação inesperada e contra-intuitiva nos benchmarks v1.4.0: em BC 1.80 nativo num emulador x86_64, **ML-DSA-65 verify é 3× mais rápido que ECDSA-P256 verify** (1.36ms vs 3.97ms P50). Hipótese: NTT vectoriza melhor que big-int em JIT JVM. Trabalho futuro:

- Validar em ARM64 real (pode inverter se ARMv8 PMULL acelera big-int).
- Profile com `perf` para confirmar hot loop (cache miss, branch mispredict).
- Submeter como short paper IACR ePrint.

### 8.2 Estudo de aceitação de utilizadores PQC mobile

Survey:
- Utilizadores percebem PQC quando explicado? (UX challenge)
- Aceitam latência ~5-10ms a mais nas transferências?
- Trust transfer: "se o banco diz pós-quântico, é mais seguro?"
- Comparação com etiqueta TLS "cadeado verde" — quantum lock seria equivalente?

### 8.3 Migração protocol-aware

Se PQC tiver de mudar de parameter set (e.g. ataque a ML-DSA-65 → migrar para ML-DSA-87):

- Versionar wire protocol com negotiation downgrade-resistant
- Estratégia de rollover (período coexistência v2 + v3)
- Backward compatibility window

---

## 9. Limitações honestas que a tese deve admitir

Para manter rigor académico — declarar explicitamente:

1. **Plataforma única validada experimentalmente:** Android emulador x86_64. ARM real e iOS são extensões assumidas, não medidas.
2. **Ausência de side-channel testing:** assume-se que BC 1.80 é constant-time onde necessário; não validado por meios próprios.
3. **Sem teste de carga em escala produção:** medições single-device, não concorrentes.
4. **Sem auditoria formal de segurança:** wire protocol v2 não foi revisto por entidade independente.
5. **Comparativo classical vs PQC limita-se a ECDSA-P256/ECDH-P256:** não cobre RSA-2048/3072 nem Ed25519 (este último usado por X25519 mas não ECDSA-equivalent).
6. **PFS é por-sessão, não por-mensagem:** atacante com sessão capturada pode decifrar todas as mensagens dela. Mitigação parcial via session TTL 5min.
7. **Quantum threat model assumido:** segue NIST estimativas; um quantum computer prático ainda não existe. A análise é pre-quantum mitigation, não post-attack response.

---

## 10. Resumo executivo do roadmap

| Horizonte | Itens |
|---|---|
| **Pré-defesa (esta semana)** | B1+B2 (ARM real + PFS validation) + gráficos finais |
| **3 meses post-defesa** | iOS Swift plugin + side-channel hardening + paper follow-up |
| **6-12 meses** | KEM rotation + Hybrid triplo (McEliece) + telemetria opt-in |
| **Roadmap produto** | QR + push + cards + Open Banking + compliance |
| **Investigação contínua** | Estudo aceitação + protocol migration awareness |
