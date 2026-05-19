# BJBank — Changelog

Histórico de alterações relevantes. Formato baseado em [Keep a Changelog](https://keepachangelog.com).

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
