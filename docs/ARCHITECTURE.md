# Arquitectura — BJBank

Documento técnico que descreve a arquitectura actual da aplicação BJBank com pipeline PQC end-to-end sobre Supabase.

## Visão de camadas

```
┌────────────────────────────────────────────────────────────────────────┐
│                          UI Layer (Flutter)                            │
│   Screens (auth, home, transfer, history, profile, settings, security) │
└───────────────────────────────┬────────────────────────────────────────┘
                                │  Provider (ChangeNotifier)
┌───────────────────────────────▼────────────────────────────────────────┐
│                       State Management Layer                           │
│   AuthProvider · AccountProvider · MbWayProvider · TransferProvider    │
│   CardProvider · SettingsProvider · NotificationProvider               │
└───────────────────────────────┬────────────────────────────────────────┘
                                │
┌───────────────────────────────▼────────────────────────────────────────┐
│                          Service Layer                                 │
│  SupabaseAuthService                  → Supabase Auth (GoTrue)         │
│  SupabaseAccountService               → Postgrest + Realtime           │
│  SupabaseMbwayService                 → mbway_phones + transfer        │
│  SupabaseTransferService              → pipeline PQC E2E (ML-DSA+GCM)  │
│  SupabasePqcHandshakeService          → handshake + HKDF               │
│  TrustedServerKeyService              → TOFU pinning (SharedPrefs)     │
│  FirestoreService (proxy)             → API legacy → Supabase          │
│  PqcBenchmarkService (local)          → benchmark PoC                  │
│  ServerPqcBenchmarkService            → invoca bench_server_pqc        │
└───────────────────────────────┬────────────────────────────────────────┘
                                │  HTTPS + JWT
┌───────────────────────────────▼────────────────────────────────────────┐
│                          Backend Supabase                              │
│  ┌──────────┐  ┌─────────────────┐  ┌──────────┐  ┌─────────────────┐  │
│  │  Auth    │  │  Postgres 15    │  │ Realtime │  │ Edge Functions  │  │
│  │ (GoTrue) │  │   + RLS         │  │ (WebSk.) │  │   (Deno 2.1)    │  │
│  └──────────┘  └─────────────────┘  └──────────┘  └────────┬────────┘  │
│                                                            │           │
│                                              ┌─────────────▼────────┐  │
│                                              │ @noble/post-quantum  │  │
│                                              │ ML-KEM-* / ML-DSA-*  │  │
│                                              └──────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

## State Management

Padrão escolhido: **Provider + ChangeNotifier**.

- `AuthProvider` mantém o `UserModel` actual + ouve `currentUserStream` do `SupabaseAuthService`. Tem método `refreshProfile()` que enriquece com `photo_url`/`phone` via RPC.
- `AccountProvider` mantém `primaryAccount` + `transactions`. Inicia 2 streams Realtime ao login (`observarContas` + `observarTransacoes`). O método `_enrichWithMbWay` faz batch query a `mbway_phones` para preencher `mbWayLinked` em cada conta.
- `MbWayProvider` expõe contactos recentes (`mbway_contacts`) e operação `pagar(...)` que delega a `SupabaseTransferService.executar(...)`.
- `TransferProvider` mantém o serviço PQC (singleton).
- `SettingsProvider` mantém preferências locais (tema, biometria).

## Service Layer detalhado

### `SupabaseAuthService`

Mapeia o `supabase.auth` SDK para o `UserModel` interno. Métodos:
- `signIn`, `signUp` (com phone metadata), `signOut`
- `sendPasswordReset(email)` — redirect para `bjbank://reset`
- `updatePassword`
- `currentUserStream` — `onAuthStateChange` mapeado para `UserModel?`

### `SupabaseAccountService`

- `observarContas()` — `_sb.from('accounts').stream(primaryKey:['id']).eq('user_id', uid)` + `asyncMap(_enrichWithMbWay)`
- `observarTransacoes(accountId)` — stream de `transactions` ordenadas por timestamp
- `obterContas()`, `obterTransacoes()` — fetch one-shot para refresh manual
- `_enrichWithMbWay(accounts)` — batch query a `mbway_phones` por `account_id IN (...)` e popula `mbWayLinked` + `mbWayPhone`
- Mappers `_accountFromRow`, `_transactionFromRow` — Postgrest row → domain model

### `SupabasePqcHandshakeService`

Fluxo `obterOuEstabelecer()`:
1. **Bootstrap (se primeira vez)** — `pqc_bootstrap` → guarda chave pública ML-DSA do servidor em `TrustedServerKeyService` (SharedPreferences). TOFU pinning.
2. **Handshake** — gera nonce 32 B, POST `pqc_handshake_flutter`, recebe `{sessionId, sharedSecret, signature}`
3. **Verificação** — `verify_dsa` valida a assinatura ML-DSA do servidor sobre `(nonce | shared_secret | server_dsa_pub | sessionId)`. Também compara `serverDsaPublic` com o pinned (rejeita se mudar)
4. **Derivação** — HKDF-SHA-256 com `salt=sessionId`, `info='BJBank-v1|session-keys'`, `len=44` → AES key (32 B) + nonceBase (12 B)

Resultado: `SessionKeys { sessionId, chaveCifragem, nonceBase }`. Cacheada em memória até `invalidar()`.

### `SupabaseTransferService.executar(...)`

Orquestra o pipeline:
1. `obterOuEstabelecer()` para ter sessionKeys
2. Gera `txId` (UUID v4) + `nonce` 16 B + timestamp
3. Constrói payload canónico em bytes — função `_construirPayload` produz bytes determinísticos compatíveis com o transcript canónico do servidor
4. Invoca `flutter_sign_transfer` com `payloadBase64` → recebe `{signatureBase64, clientDsaPublicBase64}`
5. Constrói envelope: `[4B|payload_len][payload][4B|sig_len][signature]`
6. Cifra com `pc.GCMBlockCipher(pc.AESEngine())`: `key = session.chaveCifragem`, `iv = session.nonceBase ⊕ txId`, `aad = utf8(sessionId)`, tag 128 bits
7. POST `executar_transferencia` com `{sessionId, ivBase64, envelopeBase64, clientDsaPublicBase64}`

Em caso de sucesso devolve `txId`.

### `TrustedServerKeyService`

TOFU pinning persistente:
- `setTrustedKey(bytes)` — guarda primeiro acesso
- `getTrustedKey()` — usado pelo handshake para comparar
- `verificar(serverKey)` — throws se diferente do pinned

### `FirestoreService` (proxy)

API legacy mantida para minimizar churn nas screens. Métodos como `getUser`, `findAccountByIban`, `createTransfer`, `linkMbWayVerified` delegam internamente a Postgrest/RPCs/Edge Functions Supabase.

## Database — Schema

15 tabelas em `public`, todas com RLS.

### `users`
```sql
id              UUID PK (FK → auth.users)
email           TEXT
nome_completo   TEXT
nif             TEXT NULL
phone           TEXT NULL ('+351XXXXXXXXX')
photo_url       TEXT NULL (data URL base64)
pqc_public_key_base64 TEXT NULL (chave ML-DSA do cliente — TOFU)
created_at      TIMESTAMPTZ
```

### `accounts`
```sql
id              UUID PK
user_id         UUID FK → users
iban            TEXT UNIQUE ('PT50...')
nome            TEXT
saldo           NUMERIC
moeda           TEXT ('EUR')
tipo            TEXT ('CORRENTE' | 'POUPANCA' | 'CARTAO_CREDITO')
created_at      TIMESTAMPTZ
```

### `transactions`
```sql
id                    UUID PK
account_id            UUID FK → accounts
conta_origem_iban     TEXT
conta_destino_iban    TEXT
montante              NUMERIC (negativo na origem, positivo no destino)
moeda                 TEXT
descricao             TEXT
timestamp             TIMESTAMPTZ
estado                TEXT ('CONFIRMADA' | 'PENDENTE' | 'REJEITADA' | 'REVOGADA')
nonce                 BYTEA
assinatura_mldsa      BYTEA
cliente_dsa_public    BYTEA
session_id            TEXT
```

### `sessions`
```sql
id                    TEXT PK (UUID)
user_id               UUID
shared_secret_base64  TEXT
expires_at            BIGINT (epoch millis)
created_at            TIMESTAMPTZ
```

### `mbway_phones`
```sql
phone           TEXT PK ('+351XXXXXXXXX')
account_id      UUID FK → accounts (UNIQUE — 1 número/conta)
user_id         UUID FK → users
ativo           BOOLEAN
criada_em       TIMESTAMPTZ
```

### `mbway_contacts`
```sql
id              UUID PK
owner_user_id   UUID
name            TEXT
phone           TEXT
last_used       TIMESTAMPTZ
use_count       INT
```

### `flutter_client_keys`
```sql
user_id            UUID PK FK → auth.users
public_key_base64  TEXT
secret_key_base64  TEXT  ← chave privada server-managed
criada_em          TIMESTAMPTZ
```

### `public_config`
```sql
key                TEXT PK ('server_ml_dsa')
public_key_base64  TEXT
secret_key_base64  TEXT
created_at         TIMESTAMPTZ
```

### Reservadas para funcionalidade futura
`cards`, `bills`, `loans`, `investments`, `savings_goals`, `budgets`, `notification_preferences`. A `cards` tem UI parcial; as outras são placeholders.

## Edge Functions

| Função | Verify JWT | Propósito |
|---|---|---|
| `pqc_bootstrap` | sim | Devolve chave pública ML-DSA do servidor (para TOFU) |
| `pqc_handshake_flutter` | sim | Gera shared_secret + assina transcript |
| `flutter_sign_transfer` | sim | Carrega ou gera par ML-DSA-65 do user, assina payload |
| `verify_dsa` | sim | Verifica assinatura ML-DSA-65 arbitrária |
| `executar_transferencia` | sim | Decifra envelope, verifica assinatura, chama RPC atómica |
| `bench_server_pqc` | sim | Benchmark de primitivas reais (até 100 iter/algoritmo) |
| `send_otp_email` | sim | Envia OTP por email via Resend (opcional) |

## RPCs com `SECURITY DEFINER`

| RPC | Resultado |
|---|---|
| `lookup_account_by_iban(p_iban)` | `{ account_id, user_id, iban, owner_name }` |
| `lookup_account_by_phone(p_phone)` | `{ account_id, user_id, iban, owner_name, phone }` |
| `lookup_user_public(p_user_id)` | `{ id, nome_completo, photo_url }` |
| `executar_transferencia_atomica(...)` | `void` (debit+credit numa transacção) |
| `bjbank_gerar_iban_pt()` | `text` (IBAN PT50 válido) |

## Cripto — primitivas e parâmetros

- **ML-KEM-768** (FIPS 203, nível NIST 3) — usado conceptualmente no handshake; no Flutter o `shared_secret` vem do servidor via TLS, simplificando a parte cliente
- **ML-DSA-65** (FIPS 204, nível NIST 3) — assinatura de payload de transferências e de transcript de handshake
- **AES-256-GCM** — cifragem do envelope `[payload | signature]`, tag 128 bits, IV 12 B, AAD = sessionId UTF-8
- **HKDF-SHA-256** — derivação de chave de sessão a partir de shared_secret
- **SHA-256** — hash interno do HKDF

Tamanhos oficiais:

| | pk | sk | ct/sig |
|---|---|---|---|
| ML-KEM-768 | 1184 B | 2400 B | 1088 B |
| ML-DSA-65 | 1952 B | 4032 B | 3309 B |

## Modelo de ameaça resumido

Ver `docs/adr/ADR-003-SECURITY-STRATEGY.md` para detalhe completo. Resumo:

| Ameaça | Mitigação |
|---|---|
| HNDL (Harvest Now, Decrypt Later) | Cifragem AES-GCM dentro de envelope + assinatura ML-DSA pós-quântica |
| Replay de transferência | `txId` UUID único + `sessions.expires_at` 1h + transcript canónico comparado byte-a-byte |
| MITM no handshake | TOFU pinning da chave ML-DSA do servidor; assinatura sobre transcript |
| Substituição de chave de cliente | Coluna `users.pqc_public_key_base64` pin no primeiro signing — rejeita mudanças |
| RLS bypass | `service_role` só nas Edge Functions; cliente usa JWT do utilizador |
| Saldo negativo / race condition | `SELECT FOR UPDATE` + saldo check + tudo numa transacção SQL |

## Limitações documentadas

1. **Chave privada Flutter no servidor** — `flutter_client_keys.secret_key_base64` é mantida em texto na BD (acessível apenas via service_role). Decisão pragmática pela falta de libs Dart fiáveis para ML-DSA. Solução real: HSM ou KMS.
2. **Rotação de chaves** — Não automatizada. Para rodar o par ML-DSA do servidor: `DELETE FROM public_config WHERE key='server_ml_dsa'` (próximo handshake gera nova).
3. **Sem replay protection explícito de nonce** — Confiamos no UUID v4 e no UNIQUE PK da `transactions.id`. Recomendado adicionar `WHERE NOT EXISTS` na RPC.
4. **SMS provider não configurado** — Verificação MBWay actual usa só validação de formato local. Activação SMS via Supabase requer configurar Twilio/MessageBird no Dashboard.
