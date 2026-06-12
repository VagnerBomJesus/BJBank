# PQC On-Device Migration — Plano de Correção

**Objetivo:** mover a criptografia pós-quântica do servidor para o dispositivo, eliminando o trust no servidor e respeitando o que está prometido na ADR-003.

**Estado atual** (auditoria 11 Jun 2026): ver secção "Diagnóstico" no fim. Em curto: `PqcService` é stub, ML-DSA/ML-KEM correm no servidor, chave privada do utilizador vive em `flutter_client_keys`, handshake protegido só pelo TLS, IV do AES-GCM derivado por XOR. Não é o que a app vende.

---

## Fases

### Fase 0 — Quick wins (sem impacto no protocolo wire)

| # | O quê | Onde | Risco |
|---|---|---|---|
| 0.1 | Trocar `SecureRandom('Fortuna')` mal semeado por `Random.secure()` (CSPRNG do SO) | `supabase_transfer_service.dart`, `supabase_pqc_handshake_service.dart` | Baixo. Cliente-only. |
| 0.2 | Replay protection server-side: tabela `seen_tx_ids` + validação `\|now - timestamp\| < 30s` | Supabase migration + Edge Function `executar_transferencia` | Baixo. Cliente já envia timestamp no payload assinado. |
| 0.3 | Apagar função morta `public.handle_new_user()` (substituída por `tg_handle_new_user`) | Supabase migration | Nulo. Não está ligada a nenhum trigger. |

**Aplicado nesta fase:** 0.1 + 0.2. (0.3 é cosmético, fica para depois.)

### Fase 1 — IV random por mensagem (BREAKING)

- **Problema:** `_derivarIv()` em `supabase_transfer_service.dart:158-165` faz `iv[i] = nonceBase[i] XOR txId[i % len]`. Retry sobre mesmo `txId` reutiliza IV+chave → quebra catastrófica AES-GCM.
- **Correção:** IV = 12 bytes puramente random (`Random.secure()`), incluídos no início do envelope.
- **Wire format novo:** `[12 bytes IV][4 bytes len payload][payload][4 bytes len sig][sig]` cifrado com AES-GCM (AAD = sessionId UTF-8 + IV).
- **Lado servidor:** Edge Function `executar_transferencia` precisa ler IV do envelope em vez de derivá-lo.
- **Compatibilidade:** versionar o envelope com 1 byte de version no início (`v=0x02`). Servidor aceita ambos durante 1 release.

### Fase 2 — ML-DSA no dispositivo (CRÍTICO)

Mover assinatura do servidor para o cliente. Sem isto, **toda** a camada "ML-DSA" é teatro criptográfico (o servidor pode forjar transferências em nome do utilizador).

**Opções de implementação Dart/Flutter:**

| Opção | Vantagens | Desvantagens |
|---|---|---|
| `cryptography_flutter` + plataforma nativa (Kotlin BouncyCastle / Swift CryptoKit + libsodium) | Performance nativa, código testado. Kotlin já está parcialmente referido nos comentários. | Mais código nativo, builds por plataforma. |
| `liboqs` via FFI (já no `pubspec.yaml` como `oqs 2.4.0` — falha em Android atualmente) | Lib oficial, todos os parameter sets | Falhou no Android (ver `pqc_service.dart` linha 5). Precisa investigar. |
| Pure Dart (port do `@noble/post-quantum`) | Sem código nativo | Lento (esp. keygen ML-DSA-65 ~50ms em alto-end), risco de side-channels |

**Recomendado:** Kotlin (Android) + Swift (iOS) com BouncyCastle/libsodium, expostos via Pigeon/MethodChannel.

**Fluxo novo:**

1. **Onboarding (signup):** gerar par ML-DSA-65 localmente. Privada → `FlutterSecureStorage` (Keystore Android / Keychain iOS). Pública → POST para Supabase via Edge Function `register_user_pubkey`.
2. **Assinatura:** `flutter_sign_transfer` deixa de existir. Cliente assina localmente; envia só `signatureBase64 + publicKeyBase64` (ou referência ao `client_key_id`).
3. **Verificação:** Edge Function `verify_transfer` usa a pubkey registada (não confia na pubkey enviada pelo cliente — busca por `user_id`).

**Migração das chaves existentes:**

- Schema novo: `flutter_client_keys.migrated_at`, `revoked_at` opcionais.
- Ao primeiro login depois do update da app, app verifica se utilizador tem chave nova local. Se não:
  - Gera par novo.
  - Chama RPC `register_user_pubkey(new_pubkey)` que insere e marca a antiga como `revoked_at = now()`.
  - Server-side, novas transferências exigem pubkey não revogada.
- Utilizadores Vagner/Maude (chaves antigas) passam pelo fluxo na próxima abertura da app.

### Fase 3 — ML-KEM no dispositivo (PFS real)

- **Problema:** `pqc_handshake_flutter` devolve `sharedSecret` em claro no JSON, protegido só pelo TLS X25519 (não-PQC). HNDL aplica-se.
- **Correção:** ML-KEM-768 no cliente. Servidor envia public key encapsulada; cliente decapsula localmente; `sharedSecret` nunca atravessa a rede em claro.

**Fluxo:**

1. Cliente pede handshake → recebe `serverKemPublicKey` (assinada com ML-DSA do servidor, pin TOFU verificado localmente — não mais delegado a `verify_dsa` do mesmo servidor).
2. Cliente faz `kemEncapsulate(serverKemPublicKey)` localmente → `(ciphertext, sharedSecret)`.
3. Cliente envia `ciphertext` ao servidor. Sharedsecret nunca sai do dispositivo.
4. Servidor decapsula com a sua privada → recupera o mesmo sharedSecret.
5. Ambos derivam chaves de sessão com HKDF.

**Verify_dsa local:** depois da Fase 2, o cliente já tem capacidade de verificar assinaturas localmente. A pin TOFU + verificação local da assinatura do `serverKemPublicKey` resolve o problema "verify_dsa delegada ao próprio servidor".

### Fase 4 — Rotação de chaves

- Atualmente sem rotação automática (`docs/ARCHITECTURE.md:253`).
- Implementar: cada chave tem `created_at` + `expires_at`. Cliente verifica antes de cada handshake. Rotaciona automaticamente quando faltam < 7 dias. Tabela `server_kem_keys` com histórico para handshakes em curso.

### Fase 5 — Limpeza

- Remover `flutter_sign_transfer`, `pqc_handshake_flutter`, `verify_dsa` Edge Functions (já não usadas).
- Substituir `pqc_service.dart` stub por implementação real que chama o plugin nativo.
- Apagar `flutter_client_keys.secret_key_base64` (servidor já não guarda privadas).
- Atualizar ADR-003 secção "Trust boundaries".

---

## Ordem de execução

1. ✅ **Fase 0.1 (RNG)** — aplicar agora, 1 commit.
2. ✅ **Fase 0.2 (replay protection)** — aplicar agora, 1 migration.
3. **Fase 1 (IV random)** — 1 sprint. Coordenar cliente + Edge Function. Versionar envelope.
4. **Fase 2 (ML-DSA on-device)** — 2-3 sprints. Decidir Kotlin nativo vs liboqs primeiro.
5. **Fase 3 (ML-KEM on-device)** — 1 sprint depois da Fase 2.
6. **Fase 4 (rotação)** — 1 sprint.
7. **Fase 5 (limpeza)** — 1 sprint.

---

## Diagnóstico (resumo da auditoria 11 Jun 2026)

Severidade | Problema | Onde
---|---|---
CRÍTICO | Chave privada ML-DSA do utilizador no servidor | `flutter_client_keys.secret_key_base64`
CRÍTICO | Sem PFS no handshake — sharedSecret em claro no JSON, protegido só pelo TLS X25519 | `pqc_handshake_flutter` Edge Function
ALTO | IV AES-GCM derivado por XOR reutilizável em retry | `supabase_transfer_service.dart:158-165`
ALTO | Replay protection só por UNIQUE(transactions.id) | RPC `executar_transferencia_atomica`
MÉDIO | `verify_dsa` delegada ao mesmo servidor que assinou | `supabase_pqc_handshake_service.dart:140-154`
MÉDIO | SecureRandom Fortuna semeado com `microsecondsSinceEpoch \| identityHashCode` | `*.dart:_seed()`

---

## Notas finais

- **Compatibilidade durante a migração:** versionar o envelope com 1 byte de version no início. Aceitar v=0x01 (atual) e v=0x02 (novo) durante 1 release. Depois drop.
- **Onboarding:** cada utilizador novo passa pelo fluxo novo. Existentes (Vagner, Maude) fazem upgrade ao próximo login.
- **Testes:** vetores oficiais NIST FIPS 203/204 incluídos como golden tests. Comparar output com `@noble/post-quantum` antes de fazer cutover.
