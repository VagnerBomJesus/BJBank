# Deployment — BJBank

Guia de deployment da aplicação BJBank (Flutter + Supabase).

## Pré-requisitos

- Flutter 3.8+ (`flutter doctor` sem issues)
- Conta Supabase ([supabase.com](https://supabase.com))
- Para Android: Android Studio + SDK 21+ (Android 5.0+)
- Para iOS: Xcode 14+ (macOS)
- (Opcional) [Supabase CLI](https://supabase.com/docs/guides/cli) para deploy de Edge Functions a partir do terminal

## 1. Setup do projecto Supabase

O projecto BJBank actual está em `https://jdybjrpmybkmmfdlwrzp.supabase.co` (Project ID `jdybjrpmybkmmfdlwrzp`).

Para criar um projecto novo do zero:

### 1.1 Criar projecto
1. Dashboard Supabase → New Project
2. Region: `eu-west-1` (Frankfurt ou Dublin)
3. Anotar `URL` e `anon key` (Project Settings → API)

### 1.2 Aplicar migrações SQL
Aplicar por ordem (Dashboard → SQL Editor):
1. Schema inicial: tabelas `users`, `accounts`, `transactions`, `sessions`, `cards`, `mbway_phones`, `mbway_contacts`, etc.
2. Função `bjbank_gerar_iban_pt()` (gera IBAN PT50 com check digits)
3. Trigger `handle_new_user` (cria perfil + conta + IBAN + auto-link MBWay no signup)
4. RPC `executar_transferencia_atomica` (debit/credit atómico)
5. RPCs `lookup_account_by_iban`, `lookup_account_by_phone`, `lookup_user_public` (`SECURITY DEFINER`)
6. Políticas RLS para cada tabela
7. Publicação `supabase_realtime` para `accounts` e `transactions`

Comandos SQL completos disponíveis pedindo via Supabase MCP `list_migrations` ou directamente em `supabase/migrations/` (se sincronizado via CLI).

### 1.3 Deploy das 8 Edge Functions

Via Supabase CLI:
```bash
supabase login
supabase link --project-ref jdybjrpmybkmmfdlwrzp
supabase functions deploy pqc_bootstrap
supabase functions deploy pqc_handshake_flutter
supabase functions deploy flutter_sign_transfer
supabase functions deploy verify_dsa
supabase functions deploy executar_transferencia
supabase functions deploy bench_server_pqc
supabase functions deploy send_otp_email
```

Ou via Dashboard: Project → Edge Functions → New function.

### 1.4 Configurar secrets das Edge Functions

Project Settings → Edge Functions → Secrets:

| Secret | Obrigatório | Usado por |
|---|---|---|
| `SUPABASE_URL` | auto-set | todas |
| `SUPABASE_ANON_KEY` | auto-set | todas |
| `SUPABASE_SERVICE_ROLE_KEY` | auto-set | `executar_transferencia`, `flutter_sign_transfer`, `pqc_handshake_flutter` |
| `RESEND_API_KEY` | opcional | `send_otp_email` (sem isto o OTP só vai aos logs) |
| `OTP_EMAIL_FROM` | opcional | `send_otp_email` (default: `BJBank <onboarding@resend.dev>`) |

### 1.5 Configurar Auth

Authentication → Email Templates → personalizar texto e redirect URL `bjbank://reset`.

Authentication → URL Configuration → Site URL: `bjbank://login`.

### 1.6 (Opcional) Configurar SMS provider

Para activar verificação SMS nativa do Supabase para MBWay:
1. Authentication → Providers → Phone → toggle ON
2. Selecionar Twilio/MessageBird/Vonage/Textlocal
3. Inserir credenciais (Twilio: Account SID + Auth Token + Messaging Service SID)

## 2. Cliente Flutter

### 2.1 Configurar URL/anon key

`lib/services/supabase_config.dart`:
```dart
static const String url = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://jdybjrpmybkmmfdlwrzp.supabase.co',
);
static const String anonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOi...',
);
```

Para sobrepor em build:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://meu-proj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### 2.2 Deep links Android

`android/app/src/main/AndroidManifest.xml` já tem os `intent-filter` para `bjbank://reset` e `bjbank://login`.

### 2.3 Build debug

```bash
flutter pub get
flutter run
```

### 2.4 Build release

```bash
# Android APK
flutter build apk --release --split-per-abi

# Android App Bundle (para Play Store)
flutter build appbundle --release

# iOS (em macOS com Xcode)
flutter build ios --release
```

### 2.5 Resolver problemas DNS no dispositivo Android

Se ao correr no dispositivo aparecer `Failed host lookup: 'jdybjrpmybkmmfdlwrzp.supabase.co'`:
1. Confirmar que o dispositivo tem internet (testar no browser)
2. Trocar para dados móveis (Wi-Fi de algumas redes filtra DNS)
3. Modificar DNS do Wi-Fi para `1.1.1.1` / `8.8.8.8`
4. Limpar cache DNS do telefone

## 3. Verificação pós-deployment

### Checklist
- [ ] Registar conta nova — IBAN gerado automaticamente
- [ ] Login + dashboard mostra saldo + lista de transacções
- [ ] Editar perfil — nome e telefone persistem
- [ ] Carregar foto — avatar actualiza
- [ ] Activar MBWay — toggle fica activo
- [ ] Transferir por IBAN entre 2 contas — saldos actualizam
- [ ] Transferir MBWay — recebe nome do destinatário ao escrever número
- [ ] Histórico — Realtime actualiza imediatamente após transferência
- [ ] Benchmark PQC servidor — 6 algoritmos com números coerentes
- [ ] Reset password — email chega com link `bjbank://reset`

### Verificar logs

Dashboard → Logs:
- **api** — chamadas HTTP a Postgrest/Auth
- **postgres** — queries lentas, errors
- **edge-function** — invocações das 8 funções
- **auth** — eventos de login/registo
- **realtime** — subscrições WebSocket

## 4. Operações comuns

### Confirmar email manualmente
```sql
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'user@example.com';
```

### Resetar par ML-DSA do servidor (rotação)
```sql
DELETE FROM public_config WHERE key = 'server_ml_dsa';
-- próximo pqc_handshake_flutter gera par novo
-- IMPORTANTE: invalida todos os pin TOFU no cliente
```

### Apagar dados de teste
```sql
DELETE FROM public.transactions;
DELETE FROM public.accounts WHERE saldo = 0;
DELETE FROM auth.users WHERE email LIKE '%@test.com';
-- cascade RLS limpa tudo associado
```

### Adicionar telefone MBWay manualmente
```sql
INSERT INTO public.mbway_phones (phone, account_id, user_id, ativo)
SELECT '+351912345678', a.id, u.id, true
FROM public.users u
JOIN public.accounts a ON a.user_id = u.id
WHERE u.email = 'cliente@example.com';
```

## 5. Notas de segurança

- **Service role key NUNCA no cliente** — só nas Edge Functions
- **Anon key pode estar no cliente** — é protegida por RLS
- Em produção, rodar chaves de service_role periodicamente (Settings → API → Reset)
- Configurar rate limiting nas Edge Functions (Project Settings → API → Rate Limits)
- Activar 2FA na conta Supabase do administrador
