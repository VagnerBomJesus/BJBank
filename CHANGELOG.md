# BJBank — Changelog

History of significant changes. Format based on [Keep a Changelog](https://keepachangelog.com).

> Entries prior to v1.4.0 are kept in Portuguese as historical artefacts.
> All new entries (≥ v1.4.0) are written in English to align with the
> dissertation and SEO coverage for the international audience.

---

## [1.4.0] — 2026-06-12 — codename `fair-runtime`

Experimental fair-runtime comparison PQC vs Classical — primary material
for the evaluation chapter of the dissertation. Allows rigorous assertions
such as "ML-DSA-65 is Nx slower than ECDSA-P256" without the bias introduced
by different runtimes (BouncyCastle native JVM vs interpreted Dart).

### PqcPlugin.kt (Android)
- **NEW** `classicBenchmark(iterations)` measures ECDSA-P256 (keygen/sign/verify
  via `ECDSASigner` + RFC 6979 `HMacDSAKCalculator`) and ECDH-P256
  (keygen+agree via `ECDHBasicAgreement`) on the SAME native BC 1.80 runtime.
- Curve `NISTNamedCurves.P-256` (`ECDomainParameters`).
- Same measure/warmup pattern as the PQC benchmark: 3-iteration warmup,
  P50/P95/P99 + mean + stdev over sorted samples.

### Dart bridge
- `DevicePqcService.runClassicBenchmark({iterations})` calls the new
  channel method `classicBenchmark`.

### UI
- `DeviceBenchmarkScreen` now runs 3 pipelines:
  - ① PQC native BC 1.80 (green).
  - ② Classical native BC 1.80 (indigo, **NEW**) — fair runtime.
  - ③ Classical Dart PointyCastle (grey) — interpreted-runtime reference.
- Yellow card **"Fair-runtime PQC vs Classical comparison"** with automatic
  ratios: ML-DSA-65 vs ECDSA-P256 (keygen/sign/verify) + ML-KEM-768 vs
  ECDH-P256 handshake. Calculation: `pqc.p50 / classical.p50`, formatted as
  "Nx slower/faster than classical".
- JSON export includes all 3 datasets with a methodological note explaining
  why ①↔② is a fair comparison and ③ is a runtime reference.

### Versioning
- **NEW** `lib/app_version.dart` — single source of truth with `semver`,
  `build`, `codename`, `releaseDate`, and BC/noble/PointyCastle versions +
  active PQC parameter sets.
- `settings_screen.dart` no longer shows **hardcoded "1.0.0"** (a visual
  bug since the prototype) — now reads from `AppVersion.displayString`
  with subtitle `codename · releaseDate`.
- `about_screen.dart` no longer shows **"Version 1.1.0 — May 2026"** and
  **"BouncyCastle 1.82"** (wrong). All from `AppVersion`.
- `pubspec.yaml` 1.3.1+4 → 1.4.0+5.

### Expected output (x86_64 emulator, 100 iter)

| Algorithm (BC 1.80 native) | Expected P50 |
|---|---|
| ECDSA-P256 keygen | 0.3–0.8 ms |
| ECDSA-P256 sign | 0.2–0.5 ms |
| ECDSA-P256 verify | 0.4–1.0 ms |
| ECDH-P256 keygen+agree | 0.6–1.5 ms |
| ML-DSA-65 sign | ~2.7 ms (measured) |
| ML-KEM-768 encap | ~3.4 ms (measured) |

Expected fair-runtime ratios: ML-DSA sign ~5–10× ECDSA sign, ML-KEM encap
~3–5× ECDH handshake. Consistent with NIST literature. Defensible
argument: PQC has cost, but it is acceptable (<10×) for mobile banking.

### Documentation
- **NEW** [`docs/THESIS_READINESS.md`](docs/THESIS_READINESS.md) — defence
  checklist, blocking gaps, jury question anticipation.
- **NEW** [`docs/FUTURE_WORK.md`](docs/FUTURE_WORK.md) — post-thesis roadmap
  (iOS Swift plugin, real ARM benchmarks, side-channel, follow-up paper).
- README.md fully rewritten in English with PQC SEO keywords and the 9
  drawio pages embedded as inline Mermaid diagrams.
- CHANGELOG header migrated to English.
- `docs/REQUIREMENTS.md` updated with RF-50…RF-54.
- `docs/PQC_REMAINING_CRITICAL_ISSUES.md` updated.

---

## [1.3.1] — 2026-06-11

Material académico completo — benchmarks, defesa em profundidade, auditabilidade.

### PqcPlugin.kt (Android)

- **`benchmark(N)`** — mede ML-DSA-65 keygen/sign/verify, ML-KEM-768 encap, SLH-DSA sign, X25519 agree em nanosegundos com P50/P95/P99 + mean + stdev + warmup. Devolve também platform/abi/device/androidVersion/bcVersion para reprodutibilidade.
- **SLH-DSA (FIPS 205, SHAKE-128f)** — `slhDsaKeygen / slhDsaSign / slhDsaVerify` via BouncyCastle `SLHDSASigner`. Hash-based, sem assunções lattice. Segunda assinatura para transferências de alto valor.
- **X25519 + Hybrid KEM** — `x25519Generate / x25519Agree` + `hybridDerive(ss_x25519, ss_kyber, info, length)` que faz HKDF-SHA-256 sobre `ss_x25519 ‖ ss_kyber`. Segurança = max(clássico, PQC). NIST RFC 9420 recomendação de transição.

### Cliente Dart

- **`ClassicCryptoService`** novo (`lib/services/classic_crypto_service.dart`) — pipeline criptográfico **clássico paralelo** em Dart puro via PointyCastle: ECDH-P256 + ECDSA-P256 (SHA-256). Inclui próprio `benchmark()` para comparação directa face ao PQC. Material empírico para a tese (PQC vs Clássico).
- **`DevicePqcService`** estendido com `slhDsa{Keygen,Sign,Verify}`, `x25519{Generate,Agree}`, `hybridDerive`, `runBenchmark(iterations)`.

### Server-side

- **Audit log com hash chaining** — tabela `public.audit_log` com `prev_hash` + `row_hash` (SHA-256 da `(prev_hash, actor, action, entity, entity_id, payload, ts)`). Trigger automático em `transactions` regista cada INSERT. Função `audit_verify_chain()` recalcula a cadeia e devolve linhas adulteradas. **Tamper-evident sem assinatura adicional.**
- **Rotação de chaves servidor** — tabela `server_key_history` + RPC `rotate_server_ml_dsa(p_new_pub, p_new_secret, p_overlap_hours)` + RPC pública `acceptable_server_keys(purpose)` que devolve a chave actual + chaves retiradas ainda dentro da janela de overlap (24h default). Cliente pode aceitar várias durante transição.

### Schema

- `public.audit_log(id, actor_id, action, entity, entity_id, payload, prev_hash, row_hash, created_at)`.
- `public.server_key_history(id, key_purpose, public_key_base64, secret_key_base64, created_at, retired_at, valid_until)`.

### Documentação

- `docs/REQUIREMENTS.md` actualizado: novos RF-49, RF-59, RF-60, RF-61, RF-62, RF-63; estado dos RNF-17, 18, 19, 31, 45 actualizado.
- Lista "Adicionado v1.3.1" na secção §3 Estado consolidado.

### Trabalho residual (próxima sprint)

- Edge Function `rotate_server_keys` chamada por cron diário que invoca `rotate_server_ml_dsa()` com par recém-gerado por `@noble/post-quantum`.
- UI `BenchmarkScreen` que apresenta resultados de `DevicePqcService.runBenchmark` + `ClassicCryptoService.benchmark` lado a lado.
- Plugin Swift iOS análogo ao Kotlin.

---

## [1.3.0] — 2026-06-11

PFS pós-quântico real no Android — protocolo completo cliente↔servidor.

### Segurança

**Perfect Forward Secrecy pós-quântico (Android)**

- `pqc_handshake_flutter` v2 aceita `clientKemCapability` no body:
  - `true`: servidor gera par ML-KEM-768 efémero (`ml_kem768.keygen`), persiste a privada em nova tabela `pending_kem_sessions` com TTL 5 min, devolve `serverKemPublicBase64` + assinatura ML-DSA-65 sobre transcript v2.
  - `false`/omisso: comportamento original (modo `legacy`) — `sharedSecret` entregue via TLS.
- Nova Edge Function `pqc_handshake_kem_complete` — recebe `ciphertext` cliente, decapsula com `ml_kem768.decapsulate`, cria `sessions` final, **APAGA `pending_kem_sessions`** (privada destruída após uso único).
- Cliente Dart `SupabasePqcHandshakeService._processarRespostaKem`:
  1. Recebe `serverKemPub` + assinatura.
  2. Verifica assinatura localmente (`DevicePqcService.verifyDsa`).
  3. `DevicePqcService.kemEncapsulate(serverKemPub)` no plugin Kotlin (BouncyCastle 1.80 `MLKEMGenerator`).
  4. Envia só `ciphertext` ao servidor.
  5. **`sharedSecret` calculado no dispositivo, nunca atravessa a rede em claro.**
- Transcript canónico generalizado (`material` = `serverKemPub` em modo KEM, `sharedSecret` em legacy).

### Schema

- `public.pending_kem_sessions(id, user_id, kem_secret_base64, client_nonce_base64, server_kem_pub_base64, created_at)` com RLS sem políticas (apenas `service_role`).
- `public.cleanup_pending_kem_sessions()` — DELETE oportunista de entradas > 5 min.

### Impacto no modelo de ameaça

| Ataque | Antes (v1.2.0) | Agora (v1.3.0 Android) |
|---|---|---|
| HNDL (grava TLS hoje, quebra X25519 amanhã) | ❌ Recupera `sharedSecret` em claro do JSON | ✅ Só vê `serverKemPub` e `ciphertext`; precisa quebrar ML-KEM-768 |
| Servidor comprometido > 5 min após handshake | n/a | ✅ `kemSecret` apagada; sessões antigas seguras |
| Servidor comprometido durante a janela 5 min | ⚠️ | ⚠️ Janela curta; aceitável |

**Problema 2 ("Sem PFS no handshake") em [`docs/PQC_REMAINING_CRITICAL_ISSUES.md`](docs/PQC_REMAINING_CRITICAL_ISSUES.md) — resolvido para Android.** iOS continua em modo legacy enquanto não houver plugin Swift.

---

## [1.2.0] — 2026-06-11

Endurecimento criptográfico e migração ML-DSA para o dispositivo (Android).

### Segurança

**Cripto pós-quântica on-device (Android)**

- Plugin nativo Kotlin `PqcPlugin.kt` com BouncyCastle 1.80 — `MLDSAKeyPairGenerator`, `MLDSASigner`, `MLKEMGenerator` low-level.
- Chave privada ML-DSA-65 do utilizador gerada **no dispositivo** e guardada em `EncryptedSharedPreferences` (AES-GCM-256 com `MasterKey` backed pelo `AndroidKeyStore` — StrongBox/TEE quando disponível). **Nunca sai do dispositivo.**
- `SupabaseTransferService._assinarPayload` prefere assinatura local via `DevicePqcService`; fallback para Edge Function `flutter_sign_transfer` em iOS ou se o plugin estiver indisponível.
- `SupabasePqcHandshakeService._verificarAssinatura` valida assinatura ML-DSA do servidor localmente (resolve trust circular do `verify_dsa`).
- `DevicePqcOnboardingService.ensureKey()` — idempotente, gera par + regista pubkey via RPC `register_client_pubkey` no primeiro login/signup. Hook em `AuthProvider.login` e `register`.
- Migração transparente para utilizadores existentes (Vagner, Maude): no primeiro login pós-update, par novo é gerado e a chave server-managed antiga é revogada via `flutter_client_keys.revoked_at`.

**Endurecimento de protocolo (servidor + cliente)**

- `Random.secure()` (CSPRNG do SO) substitui Fortuna mal semeado (`microsecondsSinceEpoch | identityHashCode`) em `supabase_transfer_service.dart` e `supabase_pqc_handshake_service.dart`.
- IV do AES-GCM agora é 12 bytes random puros por mensagem; eliminada a derivação `nonceBase XOR txId` que reutilizava IV+chave em retries.
- Janela temporal de replay de ±30 s aplicada server-side na RPC `executar_transferencia_atomica` (rejeita com `P0001` se timestamp fora da janela).
- Anti-replay por sessão: `sessions.last_serial` + protocolo wire v2 com serial monotónico no canonical assinado. Cliente Dart envia `protocolVersion: 2` + `serial`; Edge Function valida `serial > last_serial` e actualiza.
- First-use pubkey injection bloqueada: Edge Function `executar_transferencia` exige que a pubkey já esteja registada via `register_client_pubkey` ou `users.pqc_public_key_base64`. Recusa com `412` se ausente.
- TTL local de 50 min na sessão singleton de `SupabasePqcHandshakeService` — evita `410 Sessao expirada` em transferências.
- Normalização de IBAN (`replaceAll(\s+, '').toUpperCase()`) e descrição (trim + colapso de whitespace) no payload canónico — alinha bytes com cliente Kotlin.

### Corrigido

**IBAN**

- `bjbank_calcular_check_nib(p_19_digits)` — implementa algoritmo do Banco de Portugal (pesos `73,17,89,38,62,45,53,15,50,5,49,34,81,76,27,90,9,30,3`, MOD 97, `98-resto`).
- `bjbank_gerar_iban_pt()` agora usa check NIB **calculado** em vez de random. IBANs gerados começam todos com `PT50` (matemática do MOD-97 garante isso para NIBs válidos).
- IBANs das 2 contas existentes regenerados com check NIB correto. Transactions atualizadas em batch para apontar para os novos IBANs.

**Outros**

- `setState() called during build` em `HomeScreen.initState` — `_loadAccountData` agora chamado em `WidgetsBinding.instance.addPostFrameCallback`.
- Saldo inicial de novas contas mudado de €1.000 demo para €0 (banco real) em `tg_handle_new_user()`.

### Schema

- `flutter_client_keys`: novas colunas `managed_by ('server'|'device')`, `revoked_at`, `migrated_at`; `secret_key_base64` agora nullable.
- Índice parcial `flutter_client_keys_active_per_user` (uma chave activa por utilizador).
- RPC `register_client_pubkey(text)` — cliente regista pubkey nova; revoga implicitamente a antiga numa transação.
- RPC `pubkey_for_user(uuid)` — fonte da verdade para Edge Functions verificarem pubkey.
- `sessions.last_serial integer NOT NULL DEFAULT 0`.

### Play Console

- Rejeição "Metadata policy violation" em en-US resolvida: language default mudado para pt-PT, descrições completas em português, 6 phone screenshots reais gerados (1080×2400), 4 tablet 7-inch (1200×1920), 4 tablet 10-inch (1600×2560), feature graphic 1024×500.
- Submetido para review com 17 alterações coordenadas (Production, Open testing, Closed testing, Store listings, App content, Store settings).

### Documentação

- `docs/PQC_ON_DEVICE_MIGRATION.md` — plano de migração em 5 fases.
- `docs/PQC_REMAINING_CRITICAL_ISSUES.md` — análise dos 3 problemas críticos remanescentes e como resolvê-los.
- `docs/PLAY_CONSOLE_FIX_PLAN.md` — plano de correção da rejeição.

---

## [1.1.0] — 2026-05-19

Versão de referência da dissertação. Implementa o pipeline PQC end-to-end completo em Flutter sobre Supabase.

### Adicionado

**Backend Supabase**

- Projecto Supabase deployado em `jdybjrpmybkmmfdlwrzp.supabase.co`
- 15 tabelas Postgres com Row Level Security
- 7 Edge Functions em Deno + `@noble/post-quantum 0.4`:
  - `pqc_bootstrap` — entrega a chave pública ML-DSA-65 do servidor
  - `pqc_handshake_flutter` — handshake com `shared_secret` e assinatura do transcript
  - `flutter_sign_transfer` — assina payload ML-DSA-65 server-side
  - `verify_dsa` — verifica assinatura ML-DSA-65 arbitrária
  - `executar_transferencia` — decifra envelope, verifica, chama RPC atómica
  - `bench_server_pqc` — benchmark de primitivas reais
  - `send_otp_email` — OTP por email via Resend
- RPCs `SECURITY DEFINER` para lookup público: `lookup_account_by_iban`, `lookup_account_by_phone`, `lookup_user_public`
- Trigger SQL `handle_new_user` que cria perfil + conta + IBAN + auto-link MBWay no signup
- Função `bjbank_gerar_iban_pt()` para IBANs PT50 únicos

**Pipeline PQC end-to-end**

- `SupabaseTransferService.executar(...)` — orquestra handshake + assinatura + cifragem
- `SupabasePqcHandshakeService` — handshake com nonce, shared_secret, HKDF-SHA-256 e verificação ML-DSA do servidor
- `TrustedServerKeyService` — TOFU pinning persistente via SharedPreferences
- Envelope AES-256-GCM com IV derivado (`nonceBase ⊕ txId`) e AAD canónico
- Transcript canónico de payload com bytes determinísticos
- Linha por conta inserida na `transactions` (negativa origem, positiva destino) numa RPC atómica `executar_transferencia_atomica` com `SELECT FOR UPDATE`

**MBWay**

- Activar com número (validação local +351 obrigatório, sem OTP)
- Constraint UNIQUE em `mbway_phones(account_id)` — 1 número por conta
- Lookup público via RPC `lookup_account_by_phone`
- Auto-link no signup se telefone fornecido
- Logo oficial MB WAY em 5 sítios da app (`assets/mbway.png`)

**Benchmarks PQC**

- Tela `pqc_benchmark_screen` com duas modalidades:
  - **Local** (PoC) — exporta JSON/Markdown
  - **Servidor** (real) — invoca `bench_server_pqc`, mede primitivas `@noble/post-quantum` com slider 10-100 iterações
- 6 algoritmos: ML-KEM-512/768/1024 + ML-DSA-44/65/87
- Estatísticas completas: mean, min, max, p50, p95, stddev, n
- Tamanhos oficiais FIPS 203/204 reportados

**Perfil**

- Coluna `users.photo_url` adicionada (data URL base64)
- Avatar via `image_picker` com redimensionamento 512×512
- `AuthProvider.refreshProfile()` recarrega phone + photoUrl da BD após edit
- Edição de telefone com validador +351 obrigatório (9 dígitos, começar por 9)
- Formatter `_PtPhoneFormatter` formata como "9XX XXX XXX" em tempo real

**Página "Sobre" reescrita**

- Versão 1.1.0 — Maio 2026
- Stack técnico completo (Frontend, Backend, BD, Cripto, Auth)
- 4 cards de normas NIST (FIPS 203, 204, AES-256-GCM, HKDF)
- 5 contribuições científicas listadas
- Menção explícita a Y2Q / Harvest Now Decrypt Later

**Documentação**

- 9 diagramas UML em formato draw.io em `../MCiber/diagramas/` (Contexto, Casos de Uso, Tabela de actores, 5 diagramas de sequência, Diagrama de Estado)
- `docs/ARCHITECTURE.md` (15 tabelas, 7 Edge Functions, RPCs, modelo de ameaça)
- `docs/DEPLOYMENT.md` (Supabase, comandos SQL operacionais)
- `docs/adr/ADR-001-PQC-IMPLEMENTATION.md` (estratégia PQC server-side em Flutter)
- `docs/adr/ADR-002-STATE-MANAGEMENT.md` (Provider + ChangeNotifier)
- `docs/adr/ADR-003-SECURITY-STRATEGY.md` (modelo de ameaça e mitigações)

### Alterado

- `SupabaseAccountService.observarContas()` agora enriquece com `mbWayLinked` via `_enrichWithMbWay` (batch query a `mbway_phones`)
- Tela `mbway_phone_verification_screen` simplificada — apenas input do número (removido fluxo OTP/email)
- Tela MBWay activate/deactivate reactiva ao estado actual da BD
- Helper text dos campos de telefone: "Indicativo Portugal (+351) obrigatório"
- Login chama `refreshProfile()` para hidratar `photoUrl` e `phone` da BD após signIn

### Corrigido

- IBAN de destinatário não encontrado em transferências (RLS bloqueava lookup) — resolvido via RPCs `SECURITY DEFINER`
- Avatar não actualizava após upload — `AuthProvider._user` é refrescado via `getUser` da tabela `public.users`
- Toggle MBWay não actualizava — `_enrichWithMbWay` popula `account.mbWayLinked` em tempo real
- Edge Function `bench_server_pqc` com erro "offset is out of bounds" — ML-DSA precisa de seed de 32 B (não 64 B)
- Edge Function `verify_dsa` com `ml_dsa65.lengths.public` indefinido — substituído por constante FIPS (1952 B)

---

## Versões anteriores

Versões anteriores a 1.1.0 não são compatíveis com o stack actual e foram descontinuadas. Para arqueologia detalhada das versões pré-1.1.0, consultar o histórico Git anterior à tag `v1.1.0`.
