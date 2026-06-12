# BJBank — Requisitos Funcionais e Não Funcionais

Versão refletida: **v1.4.0** (2026-06-12, codename `fair-runtime`)
Plataformas alvo: **Android** (nativo PQC via BC 1.80), **iOS** (modo legacy server-managed)

**Ver também:** [`THESIS_READINESS.md`](THESIS_READINESS.md) (checklist defesa) · [`FUTURE_WORK.md`](FUTURE_WORK.md) (roadmap pós-tese)

Legenda:
- ✅ Implementado e testado
- 🟡 Implementado parcialmente / em validação
- 🔵 Implementado server-side, falta cliente iOS
- ❌ Não implementado (planeado / fora de escopo)
- ⏸️ Fora do âmbito desta versão

---

## 1. Requisitos Funcionais (RF)

### 1.1. Autenticação e Gestão de Conta

| ID | Descrição | Estado | Localização |
|---|---|:-:|---|
| RF-01 | Signup com email + password + nome + telefone +351 | ✅ | `SupabaseAuthService.signUp`, trigger `tg_handle_new_user` |
| RF-02 | Login com email + password (Supabase GoTrue) | ✅ | `SupabaseAuthService.signIn` |
| RF-03 | Recuperação de password via email (deep link `bjbank://reset`) | ✅ | `SupabaseAuthService.sendPasswordReset` |
| RF-04 | Alteração de password autenticada | ✅ | `SupabaseAuthService.updatePassword` |
| RF-05 | Eliminação de conta (RGPD art. 17 — "direito ao esquecimento") | ✅ | `SupabaseAuthService.deleteAccount` |
| RF-06 | Definição e validação de PIN local (hash + salt em FlutterSecureStorage) | ✅ | `SecureStorageService.setPin / verifyPin` |
| RF-07 | Autenticação biométrica (impressão digital / Face ID) | ✅ | `local_auth 2.3` |
| RF-08 | OTP por email (Resend API) para operações sensíveis | 🟡 | `send_otp_email` (Edge Function deployada, UI parcial) |
| RF-09 | SCA PSD2 (Strong Customer Authentication) — 2FA combinado | 🟡 | PIN + biometria implementados; possessão (device-pinned chave PQC) ✅; conhecimento (PIN) ✅; inerência (biometria) ✅ |

### 1.2. Perfil

| ID | Descrição | Estado | Localização |
|---|---|:-:|---|
| RF-10 | Visualizar perfil (nome, email, telefone, foto) | ✅ | `ProfileScreen`, `SupabaseAuthService.fetchProfile` |
| RF-11 | Editar nome e telefone | ✅ | `ProfileScreen` + `users` UPDATE |
| RF-12 | Upload de foto de perfil (base64 inline) | ✅ | `image_picker` + `users.photo_url` |
| RF-13 | Eliminar foto | ✅ | |

### 1.3. Contas e Saldos

| ID | Descrição | Estado | Localização |
|---|---|:-:|---|
| RF-14 | Conta criada automaticamente no signup com IBAN PT50 válido | ✅ | `tg_handle_new_user` + `bjbank_gerar_iban_pt()` |
| RF-15 | IBAN com check NIB calculado (algoritmo Banco de Portugal) | ✅ | `bjbank_calcular_check_nib` (pesos `73,17,89,38,62,45,53,15,50,5,49,34,81,76,27,90,9,30,3`) |
| RF-16 | IBAN com check IBAN MOD-97-10 ISO 7064 | ✅ | `bjbank_calcular_iban_check` |
| RF-17 | Saldo inicial €0 (banco real, sem demo money) | ✅ | `tg_handle_new_user` |
| RF-18 | Mostrar saldo em tempo real (Realtime WebSocket) | ✅ | `AccountProvider.loadAccount` + `accounts` channel |
| RF-19 | Ocultar saldo (toggle olho) | ✅ | `SettingsProvider.ocultarSaldo` + `BalanceCard` |
| RF-20 | Mostrar IBAN formatado (`PT50 9999 0001 ...`) com botão copiar | ✅ | `BalanceCard._formatIbanFull` |

### 1.4. Transferências

| ID | Descrição | Estado | Localização |
|---|---|:-:|---|
| RF-21 | Transferência por IBAN com lookup público de destinatário | ✅ | `lookup_account_by_iban` SECURITY DEFINER |
| RF-22 | Transferência MB WAY por número de telemóvel | ✅ | `lookup_account_by_phone` |
| RF-23 | Validação do montante (positivo, > 0, formato XX.YY) | ✅ | `TransferProvider.executar` |
| RF-24 | Descrição opcional na transferência (texto livre) | ✅ | `transactions.descricao` |
| RF-25 | Confirmação prévia com resumo antes de enviar | ✅ | `TransferConfirmationScreen` |
| RF-26 | Receipt após sucesso (txId, IBAN, montante, timestamp) | ✅ | `TransferReceiptScreen` |
| RF-27 | Histórico Realtime de transações com filtros (entradas/saídas/MB WAY/tudo) | ✅ | `HistoryScreen` + `transactions` channel |
| RF-28 | Agrupamento por dia (Hoje / Ontem / 28 Mai) | ✅ | `HistoryScreen._agrupar` |
| RF-29 | Pesquisa por descrição | ✅ | `HistoryScreen` search box |
| RF-30 | Geração de QR code para receber transferência | 🟡 | Ecrã existe (`qr_code_generator_screen`) mas botão da Home "Em breve" |
| RF-31 | Pagamento por QR code (scan) | 🟡 | `qr_payment_confirmation_screen` parcial |

### 1.5. MB WAY

| ID | Descrição | Estado | Localização |
|---|---|:-:|---|
| RF-32 | Activar MB WAY com número de telemóvel (+351 obrigatório) | ✅ | `MbwayProvider.activar` + `mbway_phones` |
| RF-33 | Constraint 1 número por conta (UNIQUE em `mbway_phones.account_id`) | ✅ | Schema |
| RF-34 | Auto-link no signup (se phone fornecido) | ✅ | `tg_handle_new_user` |
| RF-35 | Contactos MB WAY recentes (cache `mbway_contacts`) | ✅ | `MbwayProvider.loadContacts` |
| RF-36 | Lookup de nome do destinatário antes de confirmar | ✅ | `lookup_user_public` |

### 1.6. Cartões

| ID | Descrição | Estado | Localização |
|---|---|:-:|---|
| RF-37 | Listar cartões do utilizador | 🟡 | `CardsScreen` UI ok, dados shim |
| RF-38 | Bloquear / desbloquear cartão | ❌ | UI mockada |
| RF-39 | Definir limites de gasto | ❌ | |
| RF-40 | Ver detalhes / CVV | ❌ | |
| RF-41 | Adicionar cartão virtual | ❌ | |

### 1.7. Definições

| ID | Descrição | Estado | Localização |
|---|---|:-:|---|
| RF-42 | Tema (claro / escuro / automático) | ✅ | `SettingsProvider.tema` |
| RF-43 | Idioma (pt-PT default) | ✅ | `MaterialApp.locale` |
| RF-44 | Notificações (toggles por tipo) | 🟡 | `notification_preferences_screen` UI ok, push backend não integrado |
| RF-45 | Privacidade (data export, RGPD art. 15) | 🟡 | Ecrã informativo, export por implementar |
| RF-46 | Política de privacidade + Termos | ✅ | `privacy_policy_screen`, `terms_of_service_screen` |
| RF-47 | Sobre (versão, créditos) | ✅ | `about_screen` |
| RF-48 | Benchmark PQC servidor | ✅ | `pqc_benchmark_screen` + `bench_server_pqc` Edge Function |
| RF-49 | Benchmark PQC on-device (Android) | ✅ | `PqcPlugin.benchmark(N)` mede ML-DSA keygen/sign/verify + ML-KEM encap + SLH-DSA sign + X25519 agree com P50/P95/P99 |
| RF-50 | Benchmark clássico fair-runtime BC nativo | ✅ v1.4.0 | `PqcPlugin.classicBenchmark(N)` mede ECDSA-P256 + ECDH-P256 em BC 1.80 nativo. Material para comparação algoritmo-vs-algoritmo sem viés runtime |
| RF-51 | Benchmark clássico Dart PointyCastle referência | ✅ v1.4.0 | `ClassicCryptoService.benchmark` mostra custo runtime Dart interpretado |
| RF-52 | Card UI ratios automáticos PQC vs Clássico | ✅ v1.4.0 | `DeviceBenchmarkScreen._buildFairComparison` calcula PQC.p50/Clássico.p50 e formata "Nx mais lento/rápido" |
| RF-53 | Export JSON dos 3 datasets com nota metodológica | ✅ v1.4.0 | `_exportar` partilha via share_plus |
| RF-54 | Versionamento centralizado (single source of truth) | ✅ v1.4.0 | `lib/app_version.dart` substitui hardcodes "1.0.0" (settings) e "1.1.0 / BC 1.82" (about) |

### 1.8. Segurança e PQC

| ID | Descrição | Estado | Localização |
|---|---|:-:|---|
| RF-50 | Geração de par ML-DSA-65 no signup (Android, BouncyCastle) | ✅ | `PqcPlugin.generateDsa` |
| RF-51 | Registo da pubkey no servidor via `register_client_pubkey` | ✅ | `DevicePqcOnboardingService.ensureKey` |
| RF-52 | Assinatura ML-DSA-65 local em transferências (Android) | ✅ | `PqcPlugin.signDsa` |
| RF-53 | Verificação ML-DSA-65 local no handshake (Android) | ✅ | `PqcPlugin.verifyDsa` |
| RF-54 | Handshake KEM v2 (PFS pós-quântico) Android | ✅ | `pqc_handshake_flutter` v2 + `pqc_handshake_kem_complete` + `PqcPlugin.kemEncapsulate` |
| RF-55 | Fallback server-managed para iOS / plugin indisponível | ✅ | `SupabaseTransferService._assinarPayload` (cai em `flutter_sign_transfer`) |
| RF-56 | TOFU pinning da chave ML-DSA do servidor | ✅ | `TrustedServerKeyService` |
| RF-57 | Encapsulação ML-KEM-768 local (Android) | ✅ | `PqcPlugin.kemEncapsulate` |
| RF-58 | Plugin nativo iOS (Swift) | ❌ | TODO: `ios/Runner/PqcPlugin.swift` com libsodium / SwiftCryptoKit |
| RF-59 | Hybrid X25519 + ML-KEM-768 (NIST recomendação transição) | ✅ | `PqcPlugin.x25519Generate/Agree` + `hybridDerive(ss_x25519 \|\| ss_kyber768)` via HKDF |
| RF-60 | SLH-DSA (FIPS 205) como segunda assinatura para alto valor | ✅ | `PqcPlugin.slhDsa{Keygen,Sign,Verify}` com `SLHDSAParameters.shake_128f` |
| RF-61 | Pipeline clássico paralelo (ECDH-P256 + ECDSA-P256) para benchmark | ✅ | `ClassicCryptoService` em Dart puro (pointycastle); modo configurável |
| RF-62 | Audit log com hash chaining (tamper-evident) | ✅ | `public.audit_log` + RPC `audit_append` + trigger automático em `transactions` + `audit_verify_chain()` |
| RF-63 | Rotação automática de chaves servidor | 🟡 | RPC `rotate_server_ml_dsa()` + tabela `server_key_history` + overlap window 24h. Falta Edge Function `rotate_server_keys` para cron |

---

## 2. Requisitos Não Funcionais (RNF)

### 2.1. Segurança Criptográfica

| ID | Descrição | Métrica / Critério | Estado |
|---|---|---|:-:|
| RNF-01 | Cripto pós-quântica NIST-padronizada | ML-KEM-768 (FIPS 203) + ML-DSA-65 (FIPS 204) | ✅ |
| RNF-02 | Chave privada do utilizador isolada do servidor | Em Keystore-backed `EncryptedSharedPreferences` (Android) | ✅ Android · 🔵 iOS |
| RNF-03 | PFS (Perfect Forward Secrecy) pós-quântico | `sharedSecret` calculado no dispositivo; nunca atravessa rede em claro | ✅ Android · ❌ iOS (legacy) |
| RNF-04 | Non-repúdio das transações | Cliente é único possuidor da chave privada ML-DSA | ✅ Android · ❌ iOS |
| RNF-05 | Confidencialidade do envelope de transferência | AES-256-GCM com IV random 12B + tag 128 bits | ✅ |
| RNF-06 | Integridade do envelope (autenticação) | AAD = sessionId; tag GCM | ✅ |
| RNF-07 | RNG criptográfico forte | `Random.secure()` (CSPRNG do SO); `BouncyCastle SecureRandom` | ✅ |
| RNF-08 | Janela temporal de replay protection | ≤ 30 segundos no `executar_transferencia_atomica` | ✅ |
| RNF-09 | Anti-replay por sessão | Serial monotónico em `sessions.last_serial` | ✅ |
| RNF-10 | Janela de captura HNDL | ≤ 5 min (`pending_kem_sessions` TTL) | ✅ Android |
| RNF-11 | TOFU + verificação local da pubkey servidor | Pin constant-time compare; verify local Android | ✅ |
| RNF-12 | RLS em todas as tabelas Postgres | 100% das 16 tabelas | ✅ |
| RNF-13 | Service role nunca exposto ao cliente | Somente em Edge Functions Deno | ✅ |
| RNF-14 | Side-channel resistance | BouncyCastle 1.80 (sem certificação FIPS — limitação aceite) | 🟡 |

### 2.2. Performance

| ID | Descrição | Métrica / Critério | Estado |
|---|---|---|:-:|
| RNF-15 | Tempo de signup completo (incl. onboarding PQC) | < 5 s em rede 4G | 🟡 a medir |
| RNF-16 | Tempo de handshake KEM | < 2 s em rede 4G | 🟡 a medir |
| RNF-17 | Tempo de assinatura ML-DSA local (Android) | < 50 ms em MI 9 ARM | ✅ ferramenta de medição pronta (`PqcPlugin.benchmark`); valor por capturar em campo |
| RNF-18 | Tempo de verificação ML-DSA local | < 20 ms | ✅ idem |
| RNF-19 | Tempo de `kemEncapsulate` local | < 30 ms | ✅ idem |
| RNF-20 | Tempo de transferência end-to-end | < 3 s em rede 4G | 🟡 a medir |
| RNF-21 | Tamanho do APK release | < 100 MB | 🟡 a medir após R8 |
| RNF-22 | Cold-start da app | < 2 s | 🟡 |
| RNF-23 | Cache de sessão local | TTL 50 min (margem face ao server 1h) | ✅ |
| RNF-24 | Memória residente em idle | < 200 MB | 🟡 a medir |

### 2.3. Disponibilidade e Resiliência

| ID | Descrição | Métrica / Critério | Estado |
|---|---|---|:-:|
| RNF-25 | Tolerância a falha de sessão (auto-renovação) | Cliente refaz handshake se sessão expirar | ✅ |
| RNF-26 | Atomicidade das transferências | `SELECT FOR UPDATE` + transação Postgres | ✅ |
| RNF-27 | Idempotência de transferência | UNIQUE em `transactions.id` (UUID v4) | ✅ |
| RNF-28 | Cleanup automático de `pending_kem_sessions` | DELETE oportunista entradas > 5 min | ✅ |
| RNF-29 | Retry de transferência com mesmo `txId` | Bloqueado (UNIQUE violation 409) | ✅ |
| RNF-30 | Offline mode (read-only) | Não implementado | ⏸️ |
| RNF-31 | Rotação automática de chaves servidor | RPC `rotate_server_ml_dsa()` + overlap 24h + `acceptable_server_keys()` | 🟡 (cron externo por configurar) |
| RNF-32 | Rotação automática de chaves cliente | TODO: trigger > 90 dias | ❌ |

### 2.4. Usabilidade

| ID | Descrição | Métrica / Critério | Estado |
|---|---|---|:-:|
| RNF-33 | Idioma default | pt-PT | ✅ |
| RNF-34 | Suporte a Modo escuro | Sim, automático | ✅ |
| RNF-35 | Acessibilidade básica | Tamanho de toque ≥ 48dp; contraste WCAG AA | 🟡 audit pendente |
| RNF-36 | Mensagens de erro em português | 100% das transferências e auth | ✅ |
| RNF-37 | Feedback haptico em acções críticas | `HapticFeedback.mediumImpact` | ✅ |
| RNF-38 | Deep links (`bjbank://reset`, `bjbank://login`) | Funcionais | ✅ |

### 2.5. Manutenibilidade e Auditabilidade

| ID | Descrição | Métrica / Critério | Estado |
|---|---|---|:-:|
| RNF-39 | Arquitectura modular (Provider + Services) | Sim | ✅ |
| RNF-40 | Documentação técnica completa | README + ARCHITECTURE + 3 ADRs + 14 UML + drawio | ✅ |
| RNF-41 | Documentação cripto auditável | UML_DIAGRAMS sec. 5+13, ADR-003, PQC_REMAINING | ✅ |
| RNF-42 | CHANGELOG por versão | Sim, formato Keep a Changelog | ✅ |
| RNF-43 | Testes unitários | `test/pqc_test.dart`, `widget_test.dart` (cobertura baixa) | 🟡 |
| RNF-44 | Testes de integração | Não implementado | ❌ |
| RNF-45 | Audit log imutável de transações | Hash chaining SHA-256 em `public.audit_log` via trigger automático + `audit_verify_chain()` | ✅ |
| RNF-46 | Logs estruturados (JSON) no servidor | `console.log` simples nas Edge Functions | 🟡 |
| RNF-47 | Metrics / observability | Não implementado | ❌ |

### 2.6. Conformidade

| ID | Descrição | Métrica / Critério | Estado |
|---|---|---|:-:|
| RNF-48 | RGPD art. 15 (acesso aos dados) | Ecrã privacidade existe; export pendente | 🟡 |
| RNF-49 | RGPD art. 17 (direito ao esquecimento) | `SupabaseAuthService.deleteAccount` | ✅ |
| RNF-50 | RGPD art. 25 (privacy by design) | RLS + chave priv on-device + IBAN público mas saldo privado | ✅ |
| RNF-51 | RGPD art. 32 (segurança) | PQC + AES-GCM + RLS + JWT | ✅ |
| RNF-52 | PSD2 SCA (3-factor: posse, conhecimento, inerência) | Device-pinned key + PIN + biometria | ✅ |
| RNF-53 | PSD2 art. 97 (autenticação dinâmica) | Serial monotónico + janela ±30s | ✅ |
| RNF-54 | Aviso de cookies (não aplicável a app móvel) | n/a | ⏸️ |

### 2.7. Portabilidade

| ID | Descrição | Métrica / Critério | Estado |
|---|---|---|:-:|
| RNF-55 | Android API min | 24 (Android 7.0) | ✅ |
| RNF-56 | Android API target | 36 | ✅ |
| RNF-57 | iOS min version | 12.0 | 🟡 sem plugin PQC nativo |
| RNF-58 | Cross-platform UI | Flutter 3.8.1 | ✅ |
| RNF-59 | Internacionalização | Arquitectura pronta; só pt-PT activado | 🟡 |

---

## 3. Estado consolidado v1.4.0

### Implementado (✅)

- Toda a banca core: signup, login, perfil, conta, IBAN PT50 válido, saldo realtime, transferência IBAN, MB WAY, histórico realtime, deep links, MFA (PIN + biometria + device-pinned key).
- **PQC on-device Android**: ML-DSA-65 keygen/sign/verify + ML-KEM-768 encapsulate via BouncyCastle 1.80 + EncryptedSharedPreferences (Keystore).
- **PFS pós-quântico real (Android)**: handshake KEM v2 com `pending_kem_sessions` efémeras + `pqc_handshake_kem_complete`.
- Endurecimento do protocolo: `Random.secure()`, IV random, janela ±30s, serial monotónico, first-use injection bloqueada, normalização canonical, TTL local 50 min.
- Documentação completa: 14 diagramas Mermaid + 9 diagramas drawio + 3 ADRs + 6 documentos técnicos.
- RGPD art. 17, 25, 32; PSD2 SCA 3-factor.

### Implementado server-side, falta cliente iOS (🔵)

- Chave privada no Keystore (Android tem; iOS ainda usa `flutter_client_keys.secret_key_base64`).
- Verify ML-DSA local (Android tem; iOS ainda chama `verify_dsa` server).
- Encapsulação ML-KEM local (Android tem; iOS recebe `sharedSecret` em claro via TLS).

### Implementado parcialmente (🟡)

- OTP por email (Edge Function ok, UI incompleta).
- QR Code (telas existem, botão "Em breve").
- Cards (UI ok, dados shim).
- Notificações push (toggles ok, backend não integrado).
- Benchmarks (server-side ok, on-device por implementar).
- Testes unitários (cobertura ~10%).
- Acessibilidade WCAG (audit pendente).

### Adicionado nesta sprint v1.3.1 (Junho 2026, pós-PFS)

- ✅ **Benchmark PQC on-device** — `PqcPlugin.benchmark(N)` mede ML-DSA-65 keygen/sign/verify, ML-KEM-768 encap, SLH-DSA sign, X25519 agree com P50/P95/P99 + mean + stdev.
- ✅ **SLH-DSA (FIPS 205, SHAKE-128f)** — `slhDsaKeygen / slhDsaSign / slhDsaVerify` via BouncyCastle `SLHDSASigner`. Segunda assinatura para transferências de alto valor.
- ✅ **Hybrid X25519 + ML-KEM-768** — `x25519Generate / x25519Agree` + `hybridDerive(ss_x25519, ss_kyber, info, len)` que faz HKDF-SHA-256 sobre `ss_x25519 ‖ ss_kyber`. NIST RFC 9420 transição.
- ✅ **Pipeline clássico paralelo** — `ClassicCryptoService` em Dart puro com ECDH-P256 + ECDSA-P256 via PointyCastle. Próprio `benchmark` para comparação directa.
- ✅ **Audit log hash chaining** — tabela `audit_log` com `prev_hash` + `row_hash` SHA-256. Trigger automático em `transactions`. Função `audit_verify_chain()` detecta manipulação.
- ✅ **Rotação de chaves servidor** — tabela `server_key_history` + RPC `rotate_server_ml_dsa()` + RPC `acceptable_server_keys()` com janela overlap 24h. Cliente pode aceitar várias chaves pinned durante transição.

### Não implementado (❌)

- Plugin Swift PQC nativo para iOS.
- Rotação automática de chaves cliente (> 90 dias) — apenas servidor.
- Observability / metrics estruturados.
- Testes de integração end-to-end.
- Internacionalização activa (só pt-PT).
- Cards CRUD real.
- Edge Function `rotate_server_keys` (cron diário que chama `rotate_server_ml_dsa()`).

### Fora de âmbito (⏸️)

- Offline mode (read-only).
- Aviso de cookies (não aplicável a app móvel).
- Multi-conta por utilizador (apenas 1 conta CORRENTE por user).
- Investimentos / poupanças / créditos / orçamentos (tabelas reservadas, sem UI).
- Notificações geo-localizadas.

---

## 4. Trabalho futuro priorizado (post-v1.4.0)

> **Ver documento completo em [`FUTURE_WORK.md`](FUTURE_WORK.md)** — roadmap detalhado iOS Swift, ARM real, side-channel, paper follow-up.

### Bloqueante para defesa de tese
- ⚠️ Correr benchmark em device físico ARM (Pixel/Samsung) e exportar JSON
- ⚠️ Validar end-to-end fluxo PFS modo KEM em device físico com logcat

### Recomendado para defesa robusta
- Capítulo experimental com 3 datasets cruzados (Android-emul-x86 / Android-device-ARM / Server-V8-noble)
- Gráficos matplotlib P50 com error bars P95
- Tabela tamanhos FIPS (pk/sig/ct) lado a lado com clássicos
- Discussão sobre ML-DSA verify ser MAIS RÁPIDO que ECDSA verify em BC nativo (resultado contra-intuitivo)

### Outras sugestões originais (mantidas para referência)

| Prio | Item | Justificação académica |
|:---:|---|---|
| 1 | **Plugin PQC iOS (Swift)** | Cumprir "Aplicações **Móveis**" no plural |
| 2 | **Pipeline clássico baseline** | Demonstração empírica viabilidade PQC vs ECDH/ECDSA |
| 3 | **Benchmarks on-device** (Android nativo) | Dados para tese: keygen/sign/verify/encap × N=200 com P50/P95/P99 |
| 4 | **Hybrid X25519+ML-KEM** | NIST recomendado para transição; segurança = max(clássico, PQC) |
| 5 | **SLH-DSA segunda assinatura** | Defesa em profundidade criptográfica para alto valor |
| 6 | **Audit log hash chaining** | RGPD/banca: tamper-evident |
| 7 | **Rotação automática de chaves** | Operacional e académico |
| 8 | **Testes integração end-to-end** | Engenharia de software |
