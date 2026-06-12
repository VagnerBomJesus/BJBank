# BJBank — Estado de prontidão para defesa de tese

**Documento:** Avaliação honesta do estado da implementação face aos requisitos da dissertação.
**Tese:** *Criptografia Pós-Quântica em Aplicações Móveis: Proposta de um Protocolo Resiliente para Ambientes Homebanking*
**Versão app:** 1.4.0+5 (codename `fair-runtime`, 2026-06-12)
**Plataforma alvo defendida:** Android (BC 1.80 nativo)
**Plataforma secundária:** iOS (server-managed, sem plugin Swift)

---

## TL;DR — Estado por capítulo típico

| Capítulo da tese | Estado | Evidência |
|---|---|---|
| 1. Introdução, motivação | ✅ Coberto | Threat model HNDL → ADR-001 |
| 2. Fundamentos teóricos (RSA/ECDSA/Shor/Grover/lattices/hash-based) | ✅ Texto | Material em ADR-001/003 |
| 3. Estado da arte (NIST FIPS 203/204/205, hybrid, RFC 9420) | ✅ Texto | ADR-001 §3, referências literatura |
| 4. Proposta de protocolo | ✅ Implementado | Wire protocol v2 + handshake KEM + audit chain |
| 5. Implementação | ✅ Funcional | Android BC 1.80 nativo + Supabase Edge |
| 6. Avaliação experimental | ⚠️ **Falta ARM real** | 3 datasets fair-runtime (emulador x86) |
| 7. Discussão | ✅ Material suficiente | Trade-offs documentados |
| 8. Conclusões + trabalhos futuros | ✅ Texto | Este doc + FUTURE_WORK.md |

**Nota crítica:** o único item bloqueante para defesa robusta é **correr os benchmarks em pelo menos UM device físico ARM** (Pixel, Samsung, qualquer). Sem isto, qualquer arguente pode dizer "os teus números são de emulador x86 — não representativo".

---

## 1. O que está IMPLEMENTADO (Android, v1.4.0)

### 1.1 Criptografia pós-quântica nativa on-device

| Componente | Onde | FIPS | Estado |
|---|---|---|---|
| **ML-DSA-65 keygen** | `PqcPlugin.kt::generateDsa` | 204 | ✅ |
| **ML-DSA-65 sign** | `PqcPlugin.kt::signDsa` | 204 | ✅ |
| **ML-DSA-65 verify** | `PqcPlugin.kt::verifyDsa` | 204 | ✅ (cliente local — não server) |
| **ML-KEM-768 encap** | `PqcPlugin.kt::kemEncapsulate` | 203 | ✅ |
| **SLH-DSA-SHAKE-128f sign** | `PqcPlugin.kt::slhDsaSign` | 205 | ✅ (segunda assinatura defesa em profundidade) |
| **X25519 agree** | `PqcPlugin.kt::x25519Agree` | RFC 7748 | ✅ (componente clássico do hybrid) |
| **HKDF combiner** | `PqcPlugin.kt::hybridDerive` | RFC 9420 | ✅ |
| **Chave privada em StrongBox/TEE** | `EncryptedSharedPreferences` + `MasterKey.AES256_GCM` | — | ✅ (AndroidKeyStore-backed) |
| **Exclusão de backup cloud / device transfer** | `data_extraction_rules.xml` | — | ✅ |

### 1.2 Protocolo wire v2 (BJBank-v2-aes256gcm-sha256)

| Item | Onde | Estado |
|---|---|---|
| Canonical payload (chaves ordenadas) | `_canonicalEncode` em `SupabaseTransferService` | ✅ |
| IV random 12 bytes (não estático) | wire v2 | ✅ |
| Serial monotónico persistido em SharedPreferences | `_proximoSerialAsync` | ✅ |
| Window timestamp ±30s | server-side validation | ✅ |
| UNIQUE `txId` constraint Postgres | migration | ✅ |
| UNIQUE pubkey por user-device | migration anti first-use injection | ✅ |
| TTL 5min em pending_kem_sessions | trigger TTL | ✅ |
| Cleanup serial app-restart-resilient | `purgeSerialAntigos` em `main()` | ✅ |

### 1.3 PFS pós-quântico real

| Item | Onde | Estado |
|---|---|---|
| Handshake KEM 2-phase | `pqc_handshake_flutter` v2 + `pqc_handshake_kem_complete` | ✅ |
| `kemEncapsulate` corre no cliente | `PqcPlugin.kt::kemEncapsulate` | ✅ |
| `sharedSecret` nunca atravessa rede | by design wire v2 | ✅ |
| Decapsulação no servidor com chave efémera | Edge Function | ✅ |
| Sessão expira (TTL) e regenera | `pending_kem_sessions` table | ✅ |

### 1.4 Defesa em profundidade

| Item | Estado |
|---|---|
| Audit log com SHA-256 hash chaining (tamper evident) | ✅ Postgres trigger |
| Server key rotation (`server_key_history`) | ✅ Schema + UI Edge |
| Local ML-DSA verify (sem trust circular `verify_dsa`) | ✅ |
| TOFU pinning pubkey | ✅ |
| ProGuard rules para BC + Supabase release | ✅ |
| NetworkSecurityConfig (cleartext bloqueado em release) | ✅ |
| Anti-replay multi-camada | ✅ |

### 1.5 Material académico

| Item | Onde | Estado |
|---|---|---|
| Benchmark on-device PQC nativo (ns) | `DevicePqcService.runBenchmark` | ✅ |
| Benchmark fair-runtime ECDSA/ECDH BC nativo | `runClassicBenchmark` | ✅ |
| Benchmark Clássico Dart referência | `ClassicCryptoService.benchmark` | ✅ |
| Benchmark server Edge Functions (@noble) | endpoint deploys | ✅ |
| Export JSON dos 3 pipelines + nota metodológica | `DeviceBenchmarkScreen._exportar` | ✅ |
| Ratios automáticos PQC vs Clássico na UI | card amarelo | ✅ |

### 1.6 Documentação técnica

| Doc | Conteúdo | Estado |
|---|---|---|
| README.md | Sumário executivo + index | ✅ v1.4.0 |
| CHANGELOG.md | v1.0 → v1.4.0 | ✅ |
| docs/ARCHITECTURE.md | Stack, fluxos, deployment | ✅ |
| docs/REQUIREMENTS.md | RF/RNF | ✅ |
| docs/UML_DIAGRAMS.md | 14 Mermaid (sequence, component, state, ER) | ✅ |
| docs/diagrams/BJBank_Architecture.drawio | 9 páginas editáveis | ✅ |
| docs/adr/ADR-001-PQC-IMPLEMENTATION.md | Decisão arquitectural PQC | ✅ |
| docs/adr/ADR-002-MULTI-TENANCY.md | RLS Postgres | ✅ |
| docs/adr/ADR-003-SECURITY-STRATEGY.md | Modelo de ameaça wire v2 | ✅ |
| docs/PQC_REMAINING_CRITICAL_ISSUES.md | 3 problemas críticos + resolução | ✅ |
| docs/THESIS_READINESS.md | ESTE documento | ✅ |
| docs/FUTURE_WORK.md | Trabalhos futuros | ✅ |

---

## 2. O que FALTA para a tese estar 100% defensável

### 2.1 BLOQUEANTE para defesa robusta

| # | Item | Esforço | Porque é crítico |
|---|---|---|---|
| **B1** | Correr benchmarks em UM device físico ARM (Pixel / Samsung) e exportar JSON | 30 min se tens device | Júri vai perguntar "isto é em emulador?" — sem ARM real, qualquer afirmação sobre performance mobile é vulnerável |
| **B2** | Validar end-to-end o fluxo PFS com modo KEM em real device com logcat capturado | 1h | Provar que `pqc_handshake_kem_complete` funciona, não só compila |

### 2.2 ALTAMENTE RECOMENDADO

| # | Item | Esforço | Porque importa |
|---|---|---|---|
| **R1** | Capítulo experimental com 3 datasets cruzados: Android-emul-x86 / Android-device-ARM / Server-V8-noble | 2-3h escrita | Permite afirmar "em X plataforma com Y runtime, PQC custa Z" — argumento defensável e específico |
| **R2** | Gráficos de barras P50 com error bars P95 para cada operação × pipeline | 1h matplotlib | Visual obrigatório de tese empírica |
| **R3** | Tabela de tamanhos (FIPS oficiais) pk/sk/sig/ct lado a lado com clássicos | 30 min | Mais persuasivo que latência — utilizador não nota 5ms mas armazena bytes para sempre |
| **R4** | Discussão honesta dos resultados inesperados (ML-DSA verify 3× MAIS RÁPIDO que ECDSA em BC nativo) | 1h escrita | Mostra rigor académico — não escondes contra-intuitivos |

### 2.3 OPCIONAL (fortalece a tese mas não é crítico)

| # | Item | Esforço | Porque ajuda |
|---|---|---|---|
| **O1** | Plugin Swift iOS análogo (CryptoKit + liboqs-objc ou pqcrystals-pure) | 5-10 dias | Cobertura cross-platform real, não server-fallback |
| **O2** | Side-channel analysis nota (timing/cache) — citação Banegas et al. | 2h | Defesa contra arguente sobre attacks práticos |
| **O3** | Demo vídeo (2-3 min) — onboarding + transferência + benchmark | 1h | Sempre pedido na defesa |
| **O4** | Repositório público GitHub com release tag v1.4.0 | 30 min | Reproducibility |

---

## 3. Funcionalidades não-PQC implementadas (contexto banking)

A app é um **mobile banking funcional**, não apenas demo PQC. Para enquadrar o trabalho:

| Feature | Estado | Comentário |
|---|---|---|
| Autenticação Supabase (email+OTP) | ✅ | GoTrue |
| Criação de conta + IBAN PT50 (check NIB calculado) | ✅ | Migration corrigida v1.3.0 |
| Saldo + extracto em tempo real | ✅ | Realtime Supabase |
| Transferência IBAN com assinatura PQC | ✅ | Core da tese |
| MB WAY (transferência por telemóvel/contacto) | ✅ | UI + backend |
| QR Code transferência | ⚠️ Parcial | "Em breve" placeholder |
| Push notifications | ⚠️ Schema OK | FCM setup pendente |
| Cards CRUD virtual | ⚠️ Mock | Sem schema real |
| Open Banking PSD2 | ❌ | Trabalho futuro |
| Investimentos / Loans / Budgets | ❌ Removidos v1.3.1 | Eram demo legacy — fora de scope da tese |

---

## 4. Plataforma iOS — estado honesto

| Item | Estado |
|---|---|
| App compila e roda em iOS | ✅ |
| UI completa em iOS | ✅ |
| Autenticação / Supabase / transferências (server-managed) | ✅ |
| PQC on-device | ❌ Não existe plugin Swift |
| `DevicePqcService.isAvailable()` em iOS | retorna `false` |
| Pipeline fallback iOS | Server-managed (chave PQC no servidor, igual a v1.0) |

**Para a tese:** declarar explicitamente como **limitação assumida** e remeter para FUTURE_WORK §iOS. NÃO é honesto vender "iOS-ready" quando não é.

---

## 5. Reprodutibilidade científica

Para o júri poder replicar:

| Item | Estado |
|---|---|
| Código fonte público GitHub | ✅ (privado actualmente) |
| Build instructions (`flutter pub get && flutter run`) | ✅ |
| Schema SQL completo (migrations) | ✅ em `supabase/migrations/` |
| Edge Functions source | ✅ em `supabase/functions/` |
| Parameter sets PQC documentados | ✅ ADR-001 |
| Wire protocol versionado | ✅ ADR-003 |
| Benchmark export JSON | ✅ via UI |
| Tag de release v1.4.0 no git | ❌ Falta `git tag -a v1.4.0` |

---

## 6. Riscos para a defesa — antecipação de perguntas hostis

| Pergunta provável do júri | Resposta defensável | Onde está documentado |
|---|---|---|
| "Como sei que o BouncyCastle 1.80 implementa correctamente FIPS 204?" | BC tem CAVP test vectors NIST passing; referenciar suite | ADR-001 |
| "Porque PQC e clássico não foram medidos em ARM real?" | (precisa correr) | ⚠️ B1 acima |
| "O `sharedSecret` PQC poderia ser exfiltrado por side-channel timing?" | BC tem mitigações constant-time em ML-KEM (cite); side-channel analysis está em FUTURE_WORK | O2 |
| "iOS é metade do mercado mobile — porque não suporta?" | Limitação assumida; PQC server-managed em iOS é fallback funcional; plugin Swift é trabalho futuro definido | FUTURE_WORK §iOS |
| "Qual o overhead bytes por transferência?" | +1088B (ML-KEM ct) + 3309B (ML-DSA sig) = ~4.4KB extra vs ECDSA 64B + ECDH 32B = ~96B → **46× overhead bytes** | Capítulo experimental |
| "Como protege contra HNDL retroactivo?" | PFS pós-quântico via ML-KEM ephemeral; chave privada nunca em wire; mesmo capture-now-decrypt-later não desbloqueia sessão antiga | ADR-003 |
| "Quem audita o audit_log?" | Hash chaining SHA-256; cliente verifica chain em download; Postgres trigger impede insert sem hash anterior | v1.3.0 changelog |
| "Custo de bateria PQC em mobile?" | Não medido — limitação. Approx CPU time × power profile típico Android (qcom snapdragon ~1W active CPU): 5ms sign ≈ 5mJ por transferência → negligible vs UI rendering | Mencionar em §6 discussão |

---

## 7. Checklist de entrega (1-2 dias antes da defesa)

- [ ] Correr benchmark em device físico ARM (B1)
- [ ] Validar fluxo end-to-end PFS em device físico (B2)
- [ ] Gerar gráficos finais matplotlib (R2)
- [ ] Tabela tamanhos FIPS (R3)
- [ ] Escrever §discussion sobre ML-DSA verify mais rápido (R4)
- [ ] Demo vídeo (O3)
- [ ] Git tag v1.4.0 + release notes (O4)
- [ ] Imprimir cheat-sheet com os 3 datasets resumidos para defesa oral
- [ ] Revisar slides para coerência com a versão da app (1.4.0)
- [ ] Backup do APK release + DB dump para mostrar funcional offline
- [ ] Re-ler ADR-001/003 para responder perguntas de detalhe técnico
