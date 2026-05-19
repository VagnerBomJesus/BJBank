# ⚠️ DEPRECATED — Firebase já não é usado

A aplicação BJBank foi **migrada de Firebase para Supabase** em Maio de 2026.

Este documento é mantido apenas por contexto histórico. Para a stack actual ver:

- [`README.md`](../README.md) — visão geral
- [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) — arquitectura técnica
- [`docs/DEPLOYMENT.md`](DEPLOYMENT.md) — guia de deployment Supabase
- [`docs/adr/ADR-001-PQC-IMPLEMENTATION.md`](adr/ADR-001-PQC-IMPLEMENTATION.md) — decisões PQC

---

## Razões da migração

1. **Edge Functions Deno + npm imports nativos** — permite usar `@noble/post-quantum` directamente do servidor sem builds intermédios
2. **Postgres com SQL e RLS** — controlo declarativo de segurança vs. regras Firestore proprietárias
3. **RPCs SECURITY DEFINER** — facilita lookups públicos (IBAN→user) com privacidade preservada
4. **Realtime sobre tabelas standard** — substituiu listeners do Firestore
5. **Custo** — tier gratuito Supabase suporta o projecto académico sem cartão de crédito
6. **Source-available** — facilita o capítulo de reprodutibilidade da tese

## Mapeamento Firebase → Supabase usado na migração

| Firebase | Supabase |
|---|---|
| Firebase Auth | Supabase Auth (GoTrue) |
| Firestore | Postgres 15 + Postgrest |
| Firestore listeners | Realtime (WebSocket) |
| Cloud Functions | Edge Functions (Deno) |
| Firebase Cloud Messaging | (não migrado — fica como dívida técnica) |
| Firebase Storage | (não usado — base64 em coluna `text`) |
| Firebase Rules | RLS policies SQL |

## Ficheiros legacy

Marcados como `DEPRECATED` no código (sandbox impediu delete):
- `lib/services/transfer_service.dart`, `mbway_service.dart`, `bill_service.dart`, etc.
- `lib/services/seed_data_service.dart`, `firebase_config.dart`
- `lib/firebase_options.dart`
- `lib/compat/firebase_*.dart` (shims que mantêm compatibilidade dos modelos antigos)

Eliminar com `git rm` quando conveniente.
