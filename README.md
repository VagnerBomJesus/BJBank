# BJBank — Banca Móvel Pós-Quântica

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)](https://docs.flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase)](https://supabase.com)
[![NIST FIPS 203/204](https://img.shields.io/badge/NIST-FIPS%20203%2F204-green)](https://csrc.nist.gov/projects/post-quantum-cryptography)
[![Status](https://img.shields.io/badge/Status-Demonstrável-brightgreen)]()

<div align="center">

**Banca móvel pós-quântica · Tese de Mestrado · Instituto Politécnico da Guarda · 2026**

Autor: **Vagner Bom Jesus** · Orientador: **Prof. Rui A. P. Perdigão**

</div>

---

## Sumário

- [Visão geral](#visão-geral)
- [Arquitectura](#arquitectura)
- [Stack técnico](#stack-técnico)
- [Pipeline pós-quântico](#pipeline-pós-quântico-end-to-end)
- [Funcionalidades implementadas](#funcionalidades-implementadas)
- [Estrutura do projecto](#estrutura-do-projecto)
- [Backend Supabase](#backend-supabase)
- [Setup local](#setup-local)
- [Benchmarks PQC](#benchmarks-pqc)
- [Documentação](#documentação)
- [Estado actual e o que falta](#estado-actual-e-o-que-falta)
- [Licença](#licença)

---

## Visão geral

**BJBank** é uma aplicação bancária móvel que investiga a viabilidade da Criptografia Pós-Quântica (PQC) em operações financeiras face ao cenário *Harvest Now, Decrypt Later* (Y2Q). Implementa o pipeline completo de uma transferência interbancária — handshake, assinatura, cifragem, verificação server-side, persistência atómica — usando algoritmos pós-quânticos padronizados pelo NIST em **FIPS 203 (ML-KEM)** e **FIPS 204 (ML-DSA)**.

O projecto fornece **duas implementações paralelas** para servir como objecto de comparação na tese:

| | App Kotlin (Android nativo) | App Flutter |
|---|---|---|
| **Estratégia cripto** | Canónica — chave privada vive no device | Pragmática — assinatura delegada ao servidor |
| **Lib PQC** | BouncyCastle 1.82 (local) | `@noble/post-quantum 0.4` (Edge Function) |
| **Motivo** | Modelo de ameaça mais forte | Sem libs Dart fiáveis para ML-DSA |
| **Limitação documentada** | — | Servidor mantém chaves privadas dos utilizadores em `flutter_client_keys` cifradas com derivação do JWT |

---

## Arquitectura

```
┌────────────────────┐                ┌──────────────────────────────────────┐
│  BJBank App        │                │  Supabase                            │
│  (Flutter / Kotlin)│ ◀─ HTTPS+JWT ▶ │  ┌────────────┐  ┌────────────────┐ │
└────────────────────┘                │  │  Auth      │  │  Postgres 15   │ │
         │                            │  │  (GoTrue)  │  │  + RLS         │ │
         │ ML-DSA-65                  │  └────────────┘  └────────────────┘ │
         │ AES-256-GCM                │  ┌────────────┐  ┌────────────────┐ │
         ▼                            │  │  Realtime  │  │  Edge Functions│ │
   BouncyCastle / PointyCastle        │  │ (WebSocket)│  │  (Deno)        │ │
                                      │  └────────────┘  └────────────────┘ │
                                      │           │              │           │
                                      │           ▼              ▼           │
                                      │      streams         @noble/         │
                                      │    accounts +        post-quantum    │
                                      │   transactions       (ML-KEM,ML-DSA) │
                                      └──────────────────────────────────────┘
```

Detalhe completo: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · diagramas UML em [`../MCiber/diagramas/`](../Claude/Projects/MCiber/diagramas).

---

## Stack técnico

**Cliente Flutter**
- Flutter 3.8.1 + Dart 3.8.1
- Provider (state management)
- `supabase_flutter` 2.5+
- `pointycastle` 3.9 (HKDF-SHA256, AES-256-GCM client-side)
- `image_picker`, `app_links`, `share_plus`

**Cliente Kotlin (Android)**
- Kotlin + Jetpack Compose
- Hilt (DI), Navigation, BiometricPrompt
- BouncyCastle 1.82 (ML-KEM-768, ML-DSA-65 locais)

**Backend Supabase**
- **Auth** (GoTrue) — email/password com JWT + email confirmation
- **Postgres 15** — 15 tabelas com RLS; RPCs `SECURITY DEFINER` para lookup público
- **Realtime** — subscrições WebSocket em `accounts` e `transactions`
- **Edge Functions** (Deno 2.1, V8 11.6) — 8 funções activas:
  - `pqc_bootstrap` — entrega chave pública ML-DSA-65 do servidor (TOFU pinning)
  - `pqc_handshake_flutter` — handshake adaptado para Flutter (server emite shared_secret)
  - `flutter_sign_transfer` — assina payload com ML-DSA-65 (server-side, para cliente Flutter)
  - `verify_dsa` — verifica assinatura ML-DSA-65 arbitrária
  - `executar_transferencia` — verifica assinatura + decifra envelope + chama RPC atómica
  - `bench_server_pqc` — benchmark de primitivas reais (`@noble/post-quantum`)
  - `send_otp_email` — envio de código OTP por email via Resend (opcional)

---

## Pipeline pós-quântico end-to-end

Sequência completa de uma transferência por IBAN:

1. **Lookup do destinatário** — `RPC lookup_account_by_iban` (`SECURITY DEFINER` contorna RLS para devolver só `account_id`, `user_id`, `iban`, `owner_name`)
2. **Handshake**
   - Cliente gera nonce 32 B aleatórios e POST `pqc_handshake_flutter`
   - Servidor gera `shared_secret` 32 B, assina `(nonce | shared_secret | server_dsa_pub | sessionId)` com ML-DSA-65, persiste em `sessions`
   - Cliente verifica assinatura via `verify_dsa` e faz pin da chave pública do servidor (TOFU)
   - HKDF-SHA-256 deriva 44 bytes → AES key (32 B) + nonceBase (12 B)
3. **Construção do payload canónico** — bytes idênticos ao cliente Kotlin:
   ```
   [4B|txId] [4B|origem_iban] [4B|destino_iban] [4B|montante] [4B|descricao] [8B timestamp_be] [4B|nonce16]
   ```
4. **Assinatura ML-DSA-65** — Kotlin assina localmente; Flutter delega via `flutter_sign_transfer`
5. **Envelope cifrado**
   - Envelope = `[4B|payload][4B|signature]`
   - Cifra AES-256-GCM com IV = `nonceBase ⊕ txId`, AAD = `sessionId`
6. **POST `executar_transferencia`**
   - Decifra (AAD obrigatório)
   - `ml_dsa65.verify(clientDsaPublic, payload, signature)`
   - Reconstrói transcript canónico e compara byte-a-byte
   - Pina `clientDsaPublic` na primeira vez; rejeita se mudar (TOFU)
7. **RPC atómica `executar_transferencia_atomica`**
   - `SELECT FOR UPDATE` em conta origem e destino
   - Valida saldo e ownership
   - `UPDATE` saldos
   - `INSERT` em `transactions`: linha negativa na origem, positiva no destino
   - Tudo numa única transacção SQL

Diagrama detalhado: `MCiber/diagramas/06_seq_transferencia_iban.drawio`.

---

## Funcionalidades implementadas

### Autenticação
- Registo com email/password/nome/telefone (+351 obrigatório)
- Login com JWT
- Recuperação de palavra-passe via deep link `bjbank://reset`
- Alteração de palavra-passe (re-auth com password actual)
- Logout
- Eliminar conta (cascade RLS)

### Perfil
- Editar nome e telefone (validador +351 com formato 9 dígitos)
- Carregar foto de perfil (camara/galeria, redimensionada 512×512, base64 em `users.photo_url`)
- Refresh automático após edição

### Conta bancária
- IBAN PT gerado automaticamente no signup (trigger `handle_new_user`)
- Saldo em EUR
- Vista pelo dashboard com Realtime

### Transferências
- **Por IBAN** com validação MOD 97
- **Por MBWay** (telefone → IBAN via `mbway_phones`)
- Confirmação em ecrã separado
- Recibo com badge PQC após sucesso
- Histórico actualizado em tempo real

### MBWay
- Activar com número (auto-formatação +351 9XX XXX XXX)
- 1 número por conta (constraint `UNIQUE(account_id)`)
- Desactivar
- Configurar limites diário e por transacção
- Auto-link em `mbway_phones` se telefone fornecido no signup

### Histórico
- Lista com Realtime
- Filtros: Todas, Receitas, Despesas, Transferências, MBWay
- Pesquisa por descrição/categoria
- Agrupamento por data (Hoje, Ontem, Esta Semana, Este Mês, MM/AAAA)
- Modal de detalhe com badge PQC

### Cartões
- Visualizar cartões associados
- Toggle de definições (contactless, online, internacional)
- Editar limites diário/mensal

### Segurança / PQC
- Benchmark PQC local (Dilithium2/3/5 + Kyber512/768/1024)
- Benchmark PQC servidor (primitivas reais `@noble/post-quantum`)
- Export JSON / Markdown dos resultados
- Página "Sobre" actualizada com stack técnico completo

---

## Estrutura do projecto

```
bjbank/
├─ lib/
│  ├─ main.dart                              # entry point + DeepLinkHandler
│  ├─ app.dart                               # MultiProvider + MaterialApp
│  ├─ models/                                # UserModel, AccountModel, TransactionModel, …
│  ├─ providers/                             # AuthProvider, AccountProvider, MbWayProvider, …
│  ├─ routes/                                # AppRouter, AppRoutes
│  ├─ services/
│  │  ├─ supabase_config.dart                # URL + anon key
│  │  ├─ supabase_auth_service.dart          # signIn/signUp/updatePassword
│  │  ├─ supabase_account_service.dart       # streams accounts/transactions
│  │  ├─ supabase_mbway_service.dart         # lookup phone, pagar()
│  │  ├─ supabase_transfer_service.dart      # PIPELINE PQC end-to-end
│  │  ├─ supabase_pqc_handshake_service.dart # handshake + HKDF
│  │  ├─ trusted_server_key_service.dart     # TOFU pinning
│  │  ├─ firestore_service.dart              # proxy legacy com API Supabase
│  │  ├─ pqc_service.dart                    # stub PoC (benchmark local)
│  │  ├─ pqc_benchmark_service.dart          # benchmark local
│  │  ├─ server_pqc_benchmark_service.dart   # invoca bench_server_pqc
│  │  └─ deep_link_handler.dart              # bjbank://reset, bjbank://login
│  ├─ screens/
│  │  ├─ auth/                               # login, register, forgot_password, seed
│  │  ├─ home/                               # dashboard + quick actions
│  │  ├─ transfer/                           # transfer_screen, mbway_screen, confirmação, recibo
│  │  ├─ history/                            # history_screen com filtros + pesquisa
│  │  ├─ cards/                              # cards_screen + card_settings_dialog
│  │  ├─ profile/                            # profile_screen com avatar
│  │  ├─ settings/                           # mbway_settings, mbway_phone_verification, about, …
│  │  └─ security/                           # pqc_benchmark_screen
│  ├─ compat/                                # shims legacy de Firebase (deprecation)
│  └─ theme/                                 # colors, spacing, typography, app_strings
├─ assets/
│  ├─ logo_bjbank.png
│  └─ mbway.png                              # logo oficial MB WAY
├─ docs/
│  ├─ ARCHITECTURE.md
│  ├─ DEPLOYMENT.md
│  └─ adr/
│     ├─ ADR-001-PQC-IMPLEMENTATION.md
│     ├─ ADR-002-STATE-MANAGEMENT.md
│     └─ ADR-003-SECURITY-STRATEGY.md
├─ android/                                  # plugins, manifest com deep links bjbank://
├─ ios/
├─ CHANGELOG.md
├─ CONTRIBUTING.md
└─ README.md (este ficheiro)
```

---

## Backend Supabase

**Project URL**: `https://jdybjrpmybkmmfdlwrzp.supabase.co`

### Tabelas (15, todas com RLS)

| Tabela | Propósito |
|---|---|
| `users` | Perfis (id, email, nome, phone, photo_url, pqc_public_key_base64) |
| `accounts` | Contas bancárias (IBAN, saldo, tipo) |
| `transactions` | Movimentos com assinatura ML-DSA persistida |
| `sessions` | Sessões PQC (shared_secret + expires_at) |
| `mbway_phones` | Mapping phone → account (UNIQUE account_id) |
| `mbway_contacts` | Contactos recentes MBWay |
| `cards` | Cartões com limites |
| `flutter_client_keys` | Chaves ML-DSA do cliente Flutter (server-managed) |
| `public_config` | Chaves ML-DSA do servidor |
| `bills`, `loans`, `investments`, `savings_goals`, `budgets`, `notification_preferences` | Reservadas para futuro |

### RPCs públicas (`SECURITY DEFINER`)

- `lookup_account_by_iban(p_iban)` — devolve só id/user_id/iban/owner_name
- `lookup_account_by_phone(p_phone)` — JOIN mbway_phones + accounts + users
- `lookup_user_public(p_user_id)` — id, nome, photo_url
- `executar_transferencia_atomica(...)` — debit+credit numa transacção
- `bjbank_gerar_iban_pt()` — IBAN PT50 com check digits

### Política RLS (resumida)

- `accounts`: SELECT só do dono (`user_id = auth.uid()`); WRITE só `service_role`
- `transactions`: SELECT só de contas próprias; WRITE só `service_role` (via Edge Function)
- `mbway_phones`: SELECT a qualquer autenticado (para lookup); INSERT/DELETE só do próprio
- `users`: SELECT/UPDATE só do próprio
- Operações destrutivas em massa → SQL Editor do Supabase Dashboard com service_role

---

## Setup local

### Pré-requisitos

- Flutter 3.8+ (`flutter doctor`)
- Android Studio ou Xcode (para correr em dispositivo)
- Conta Supabase com o projecto BJBank acessível (URL + anon key estão hardcoded em `lib/services/supabase_config.dart` para conveniência académica — para produção, mover para `--dart-define`)

### Instalação

```bash
git clone https://github.com/VagnerBomJesus/BJBank.git
cd bjbank
flutter pub get
flutter run
```

Para emulador Android com problemas DNS: ver `docs/DEPLOYMENT.md`.

### Deep links

Configurados em `android/app/src/main/AndroidManifest.xml`:
- `bjbank://reset` — reset de password
- `bjbank://login` — link directo de login

---

## Benchmarks PQC

A app inclui ecrã de benchmark (`Settings → Segurança → Benchmark PQC`) com duas modalidades:

**Local (PoC)**: Mede serialização + I/O do cliente Flutter (modo simulação, primitivas mockadas). Útil para discutir overhead arquitectural.

**Servidor (real)**: Invoca `bench_server_pqc` Edge Function que mede `@noble/post-quantum` real. Configurável (10-100 iterações × 6 algoritmos). Exporta JSON ou Markdown.

**Resultados representativos** (Deno 2.1 / V8 11.6, N=50):

| Algoritmo | Op | Mean | P50 | P95 |
|---|---|---|---|---|
| ML-KEM-768 | keygen | 0.53 ms | 0.41 ms | 0.53 ms |
| ML-KEM-768 | encaps | 0.53 ms | 0.47 ms | 0.66 ms |
| ML-KEM-768 | decaps | 0.55 ms | 0.51 ms | 0.72 ms |
| ML-DSA-65 | keygen | 4.08 ms | 3.63 ms | 4.18 ms |
| ML-DSA-65 | sign | 12.64 ms | 10.37 ms | 27.01 ms |
| ML-DSA-65 | verify | 4.43 ms | 3.62 ms | 3.97 ms |

Comparação com clássico (SUPERCOP @ Intel i7-6500U):
- **ECDSA-P256 sign 0.24 ms vs ML-DSA-65 sign 12.6 ms** → overhead ~52×
- **X25519 ECDH 0.06 ms vs ML-KEM-768 encaps 0.53 ms** → overhead ~9×

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Arquitectura detalhada (camadas, providers, services) |
| [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) | Deploy Supabase, Edge Functions, secrets |
| [`docs/adr/ADR-001-PQC-IMPLEMENTATION.md`](docs/adr/ADR-001-PQC-IMPLEMENTATION.md) | Decisão da estratégia PQC dupla (Kotlin local vs Flutter server-side) |
| [`docs/adr/ADR-002-STATE-MANAGEMENT.md`](docs/adr/ADR-002-STATE-MANAGEMENT.md) | Provider + Realtime |
| [`docs/adr/ADR-003-SECURITY-STRATEGY.md`](docs/adr/ADR-003-SECURITY-STRATEGY.md) | Estratégia de segurança, modelo de ameaças |
| [`CHANGELOG.md`](CHANGELOG.md) | Histórico de versões |
| [`MCiber/diagramas/`](../../Claude/Projects/MCiber/diagramas) | 9 diagramas UML em formato draw.io |

---

## Estado actual e o que falta

### Funcional ✅
- Auth completa (registo/login/reset/alterar password/eliminar conta)
- Perfil com avatar e telefone +351 validado
- Transferências por IBAN com pipeline PQC end-to-end funcional
- MBWay (activar com 1 número/conta, transferir, lookup público)
- Histórico em tempo real com filtros e pesquisa
- 8 Edge Functions deployadas e acessíveis
- Benchmark PQC server-side com primitivas reais

### Parcialmente implementado ⚠️
- QR Code (telas existem mas botão da home mostra "Em breve")
- Cards (UI funcional mas `CardProvider` ainda usa shim legacy)
- Notifications (`FirebaseMessaging` shim — sem push real)

### Para a parte académica da tese 📚
- Pipeline clássico paralelo (ECDH-P256 + ECDSA-P256) para benchmark PQC vs Clássico no mesmo runtime
- Recolha de dados experimentais com N=200+ para citar com confiança
- Replay protection explícita na RPC `executar_transferencia_atomica` (txId UNIQUE constraint)
- Diagramas UML finais (já gerados em `MCiber/diagramas/`)

### Limpeza técnica
- Ficheiros legacy marcados como `DEPRECATED` (eliminar com `git rm` quando conveniente):
  - `lib/services/transfer_service.dart`, `mbway_service.dart`, `bill_service.dart`, `budget_service.dart`, `investment_service.dart`, `loan_service.dart`, `savings_goal_service.dart`
  - `lib/services/seed_data_service.dart`, `firebase_config.dart`
  - `lib/firebase_options.dart`
  - `lib/providers/bill_provider.dart`, `budget_provider.dart`, `investment_provider.dart`, `loan_provider.dart`, `savings_goal_provider.dart`
- Shims `lib/compat/firebase_*.dart` podem ser eliminados quando modelos perderem as factories `fromFirestore`

---

## Licença

Investigação académica. Uso comercial requer autorização explícita.

© 2026 Vagner Bom Jesus · Instituto Politécnico da Guarda · Todos os direitos reservados.

---

## Contacto

- **GitHub**: [VagnerBomJesus/BJBank](https://github.com/VagnerBomJesus/BJBank)
- **Email**: vagneripg@gmail.com
- **Backend Supabase**: `jdybjrpmybkmmfdlwrzp.supabase.co`
