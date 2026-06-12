# Problemas Críticos do Protocolo PQC — Estado e Resolução

**Última revisão:** 12 Jun 2026 — versão **v1.4.0** (`fair-runtime`).

> **Documentos relacionados:**
> - [`THESIS_READINESS.md`](THESIS_READINESS.md) — checklist específico de defesa de tese
> - [`FUTURE_WORK.md`](FUTURE_WORK.md) — roadmap pós-tese (iOS Swift, ARM real, side-channel)

## Resumo executivo

Dos 3 problemas críticos originalmente identificados:

| # | Problema | Android | iOS |
|---|---|:-:|:-:|
| 1 | Chave privada ML-DSA do utilizador no servidor | ✅ **Resolvido v1.3.0** (Keystore-backed `EncryptedSharedPreferences`) | ❌ Pendente Swift plugin — ver `FUTURE_WORK §1` |
| 2 | Sem PFS no handshake | ✅ **Resolvido v1.3.0** (`pqc_handshake_flutter` v2 + `pqc_handshake_kem_complete`; `kemEncapsulate` local) | ❌ Mesmo Edge Function (modo `legacy` server-managed) |
| 3 | `verify_dsa` delegada ao servidor (trust circular) | ✅ **Resolvido v1.3.0** (`DevicePqcService.verifyDsa` local) | ❌ Pendente Swift plugin |

**Onde estamos (v1.4.0):**

- Android: cripto pós-quântica REAL on-device (BouncyCastle 1.80 ML-DSA-65 + ML-KEM-768 + SLH-DSA-SHAKE-128f + X25519). Chave privada nunca sai do TEE/StrongBox. PFS pós-quântico real (`sharedSecret` calculado no dispositivo via `kemEncapsulate`, nunca em wire em claro). **Os 3 problemas críticos estão resolvidos no Android.**
- Novo em v1.4.0: comparação fair-runtime — `PqcPlugin.classicBenchmark` mede ECDSA-P256/ECDH-P256 na MESMA runtime BC 1.80, permitindo afirmações algoritmo-vs-algoritmo sem viés de runtime.
- iOS: continua server-managed por falta de plugin Swift. Limitação assumida na tese — ver `FUTURE_WORK §1`.

A secção seguinte mantém a descrição original de cada problema para contexto. As notas "Resolução implementada" no fim de cada secção descrevem o que foi feito.

---

## Problema 1 — Chave privada ML-DSA do utilizador vive no servidor

### O que é

A chave privada ML-DSA-65 do utilizador (4032 bytes) está em `public.flutter_client_keys.secret_key_base64` como BYTEA codificada em base64. A Edge Function `flutter_sign_transfer` lê-a a cada transferência, executa `ml_dsa65.sign(privateKey, payload)` e devolve a assinatura ao cliente. **O cliente Dart nunca toca na chave privada — só envia o payload a assinar e recebe a assinatura pronta.**

Localizações concretas:
- `lib/services/supabase_transfer_service.dart:_assinarPayload()` — invoca `flutter_sign_transfer`.
- Edge Function `flutter_sign_transfer/index.ts` — `SELECT secret_key_base64 FROM flutter_client_keys` + `ml_dsa65.sign(...)`.
- Schema: `public.flutter_client_keys (user_id, public_key_base64, secret_key_base64, ...)`.

### Como afeta a integridade

**Não-repúdio destruído.** ML-DSA serve precisamente para provar que apenas quem tem a chave privada pôde ter assinado uma mensagem. Como o servidor tem ambas as chaves, o servidor pode forjar qualquer transferência em nome de qualquer utilizador, e a assinatura passa todos os checks. Resultado prático:

1. **Comprometimento do `service_role` ⇒ controlo total.** Um atacante com acesso ao `service_role` extrai `secret_key_base64` de qualquer utilizador, assina transferências para uma conta sua, e a Edge Function `executar_transferencia` valida sem reclamar (assinatura "válida" do utilizador legítimo).
2. **Insider risk.** Qualquer pessoa com acesso à base de dados (DBA, engenheiro on-call, contractor) tem capacidade técnica de assinar em nome de qualquer cliente.
3. **Disputa legal.** Num processo, o utilizador pode legitimamente alegar "a transferência tem a minha assinatura mas não fui eu — o banco tem a minha chave privada e podia tê-la gerado". A app não tem prova técnica para contradizer.
4. **Ataque retroativo.** Se a base de dados leak hoje, todas as transferências históricas tornam-se questionáveis em retrospectiva.

### Implica no protocolo PQC?

**Sim, directamente.** O propósito do ML-DSA no protocolo é fornecer autenticação não-repudiável das transações. Sem a chave privada no dispositivo, o ML-DSA reduz-se funcionalmente a um HMAC server-side com extra steps — toda a complexidade pós-quântica fica sem propósito. A ADR-003 lista os ataques T1 (HNDL) e T4 (forge) como mitigados; com a chave privada no servidor, T4 não está mitigado.

### Como resolver

**Caminho A — Plugin nativo (recomendado).** Criar Pigeon plugin `pigeons/pqc.dart` exposto a Kotlin (BouncyCastle 1.78 com `MLDSAPrivateKeyParameters` parameter set 65) e Swift (libsodium ou implementação Apple CryptoKit + ML-DSA). Privada gerada no signup e guardada em `AndroidKeyStore` (StrongBox quando disponível) / `iOS Keychain` com `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. Substituir `_assinarPayload()` por `DevicePqcService.signDsa(privateKeyRef, payload)`. A privada nunca sai do TEE.

Schema e RPC já estão preparados: `flutter_client_keys.managed_by='device'`, `revoked_at`, `register_client_pubkey()` aplicados. Falta o plugin e a chamada cliente.

**Caminho B — Puro Dart (alternativa).** Portar `@noble/post-quantum 0.4` para Dart. ~3000 linhas de matemática lattice. Performance ~50ms keygen + 5ms sign em mid-range Android. Risco de side-channels (timing attacks) se não for implementado com cuidado constante-tempo.

**Migração das chaves existentes (Vagner, Maude).** No primeiro login pós-update:
1. App verifica se tem chave nova em `FlutterSecureStorage`.
2. Se não, gera par localmente.
3. Chama `register_client_pubkey(new_pubkey)` — RPC já existe e revoga implicitamente a antiga.
4. Server-side, marca `flutter_client_keys.secret_key_base64 = NULL` para essa chave (já permitido após migration desta sessão).

### ✅ Resolução implementada (Android)

- `android/app/src/main/kotlin/com/bjbank/ipg/PqcPlugin.kt` — BouncyCastle 1.80 `MLDSAKeyPairGenerator/MLDSASigner` low-level.
- Privada serializada em `EncryptedSharedPreferences` (AES-GCM-256 com `MasterKey` Keystore-backed; StrongBox quando disponível).
- `lib/services/device_pqc_service.dart` — bridge Dart via `MethodChannel('com.bjbank.ipg/pqc')`.
- `lib/services/device_pqc_onboarding_service.dart` — `ensureKey()` idempotente, chamado pelo `AuthProvider.login` e `register` fire-and-forget.
- `SupabaseTransferService._assinarPayload` — tenta `DevicePqcService.signDsa()` primeiro; fallback Edge Function `flutter_sign_transfer`.
- Server-side: schema preparado (`flutter_client_keys.managed_by`, `revoked_at`, `migrated_at`), RPC `register_client_pubkey()`, RPC `pubkey_for_user()` como fonte da verdade para Edge Functions.

**Estado iOS:** continua server-managed. Plugin Swift análogo ao Kotlin precisa de ser criado em `ios/Runner/PqcPlugin.swift` usando libsodium ou implementação Swift de ML-DSA.

---

## Problema 2 — Sem Perfect Forward Secrecy no handshake

### O que é

A Edge Function `pqc_handshake_flutter` devolve `{sessionId, sharedSecretBase64, signatureBase64}` ao cliente Dart. O `sharedSecretBase64` é o segredo final de 32 bytes que vai ser usado em HKDF para derivar a chave AES da sessão. **Esse JSON viaja em claro dentro do canal TLS Supabase (X25519 + AES-128-GCM clássico).**

O cliente Dart **não executa ML-KEM-768.** O `oqs` package (FFI para liboqs) falha no Android. O `PqcService.dart` é stub. Toda a operação KEM acontece server-side e o resultado é entregue pronto.

Localizações concretas:
- `lib/services/supabase_pqc_handshake_service.dart:35-37` — comentário explícito a admitir que confidencialidade depende do TLS.
- Edge Function `pqc_handshake_flutter/index.ts` — gera shared_secret aleatório de 32B, retorna em base64 no JSON.
- HKDF salt = sessionId (público, vai em claro em todas as requisições subsequentes).

### Como afeta a integridade

**HNDL (Harvest Now, Decrypt Later).** O modelo de ameaça que justifica usar PQC. Atacante com posição de rede grava tráfego TLS hoje. Daqui a 5–10 anos, quando um computador quântico relevante quebrar X25519 (Diffie-Hellman elíptico):

1. Atacante decifra o TLS retroativamente → recupera o JSON do handshake em claro.
2. Extrai `sharedSecretBase64`.
3. Calcula HKDF com `salt=sessionId` (público): `chaveAES = HKDF-SHA256(sharedSecret, sessionId, "BJBank-v1|session-keys", 32)`.
4. Decifra todos os envelopes AES-GCM dessa sessão.
5. Lê IBAN origem/destino, montantes, descrições, timestamps de cada transferência.

A app vende-se como "Banco digital seguro com criptografia pós-quântica" — mas a confidencialidade real depende inteiramente do TLS clássico. O ML-KEM no servidor não ajuda contra HNDL porque o ATACANTE que vence é o que captura o tráfego *entre cliente e servidor*, não o tráfego *dentro do servidor*.

Acresce que, mesmo no presente:

- Qualquer comprometimento do TLS (MitM com CA confiada injectada, vulnerabilidade no stack TLS do Android, certificado pinning falhado) expõe o sharedSecret sem qualquer barreira PQC.
- O `verify_dsa` é delegado ao mesmo servidor (Problema 3), portanto a "assinatura ML-DSA do servidor sobre o handshake" não acrescenta proteção real.

### Implica no protocolo PQC?

**Sim, directamente e como o caso mais grave.** Este é o problema canónico que motivou a transição para PQC à escala global. O propósito de existir um KEM pós-quântico (ML-KEM-768) é exactamente eliminar a dependência do Diffie-Hellman clássico. Tê-lo apenas server-side é o mesmo que não o ter.

### Como resolver

**Mover ML-KEM para o dispositivo.** Fluxo correcto:

1. Cliente pede handshake → recebe `serverKemPublicKey` (1184 bytes) + assinatura ML-DSA do servidor sobre ela.
2. Cliente verifica a assinatura **localmente** contra a pin TOFU (precisa do Problema 1 resolvido).
3. Cliente faz `kemEncapsulate(serverKemPublicKey)` → `(ciphertext, sharedSecret)`. O cálculo acontece no dispositivo.
4. Cliente envia `ciphertext` (1088 bytes) ao servidor. `sharedSecret` nunca sai do dispositivo.
5. Servidor decapsula com a sua privada ML-KEM → recupera o mesmo sharedSecret.
6. Ambos derivam chaves de sessão com HKDF.

Recomendação adicional: **Hybrid X25519 + ML-KEM-768**. NIST e RFCs recentes recomendam hybrids durante a transição porque protege contra falhas em qualquer dos algoritmos (lattice attacks que ainda não foram descobertos, falhas de implementação). `sharedSecret = HKDF(ss_x25519 || ss_kyber768)`. Custo: dois KEMs em vez de um. Benefício: segurança = max(X25519, ML-KEM-768) em vez de min().

Stub Dart já existe: `DevicePqcService.kemEncapsulate(serverKemPublicKey)` em `lib/services/device_pqc_service.dart`. Falta o plugin nativo.

### ⚠️ Resolução implementada — apenas infraestrutura

- `PqcPlugin.kemEncapsulate(serverPubKey)` — implementação Kotlin pronta via `MLKEMGenerator` (BC 1.80). Recebe pubkey ML-KEM-768 (1184 B), devolve `{ciphertext: 1088 B, sharedSecret: 32 B}`. **O `sharedSecret` nunca sai do plugin.**
- `DevicePqcService.kemEncapsulate()` — bridge Dart.
- **O flow ainda não é usado**, porque a Edge Function `pqc_handshake_flutter` continua a devolver `sharedSecretBase64` em claro em vez de `serverKemPublicKey`. Falta:
  1. Modificar `pqc_handshake_flutter` para gerar par ML-KEM efémero, devolver `serverKemPublicKey` + assinatura sobre ela (mas guardar a privada em memória curta na sessão).
  2. Cliente Dart faz `kemEncapsulate(serverKemPublicKey)` → envia `ciphertext` a um novo endpoint `pqc_handshake_complete`.
  3. Servidor decapsula com a privada efémera → recupera o mesmo `sharedSecret`.
  4. Ambos derivam chaves AES com HKDF.

### ✅ Atualização v1.3.0 — IMPLEMENTADO no Android

- `pqc_handshake_flutter` v2 aceita `clientKemCapability` no body. Em modo KEM, gera par ML-KEM-768 efémero, persiste a privada em `pending_kem_sessions` (TTL 5 min), devolve `{mode: 'kem', sessionId, serverKemPublicBase64, serverDsaPublicBase64, signatureBase64}` com assinatura sobre `clientNonce ‖ serverKemPub ‖ serverDsaPub ‖ sessionId`.
- Nova Edge Function `pqc_handshake_kem_complete` recebe `ciphertext`, faz `ml_kem768.decapsulate`, cria `sessions` finalizada, **APAGA `pending_kem_sessions`** (privada destruída).
- Cliente Dart `SupabasePqcHandshakeService._processarRespostaKem` chama `DevicePqcService.kemEncapsulate` localmente; **`sharedSecret` calculado no dispositivo, nunca atravessa a rede em claro.**
- Compatibilidade retroactiva: cliente sem `DevicePqcService.isAvailable()` (iOS) envia `clientKemCapability: false` → modo legacy.

**Defesa HNDL conseguida no Android:** atacante de rede que grave hoje e quebre X25519 amanhã só vê `clientNonce` + `serverKemPub` + `ciphertext`. Sem quebrar **também** ML-KEM-768 (lattice attacks futuros desconhecidos), não recupera `sharedSecret`.

**Janela residual de 5 min:** se atacante obtiver `service_role` enquanto `pending_kem_sessions` ainda existe, compromete o `sharedSecret` da sessão em curso. Sessões antigas ficam imunes porque a privada foi apagada.

---

## Problema 3 — `verify_dsa` delegada ao próprio servidor que assinou

### O que é

Após o handshake, o servidor devolve uma assinatura ML-DSA sobre os dados do handshake (`nonce || sharedSecret || sessionId`). Para verificar essa assinatura, o cliente envia `(pubkey, message, signature)` à Edge Function `verify_dsa` e confia no campo `valid: true/false` retornado.

Localizações:
- `lib/services/supabase_pqc_handshake_service.dart:140-154` (`_verificarAssinatura`).
- Edge Function `verify_dsa/index.ts` — chama `ml_dsa65.verify(...)` e devolve `{valid}`.

### Como afeta a integridade

**Trust circular.** A assinatura serve para o cliente verificar que está a falar com o servidor legítimo. Mas a verificação é delegada ao próprio servidor. Se o servidor está comprometido, `verify_dsa` retorna sempre `true`, mesmo para assinaturas forjadas:

1. Atacante compromete o servidor.
2. Gera o seu próprio par ML-DSA.
3. Substitui em runtime as respostas de `verify_dsa` para que retornem `true` para qualquer assinatura.
4. Cliente é enganado, aceita assinatura falsa, prossegue com sessão estabelecida com o atacante.

O TOFU pinning da chave pública (`TrustedServerKeyService`) NÃO protege contra isto. O pin garante que a *chave pública* que o cliente vai usar para verificar é a primeira que viu. Mas a *verificação propriamente dita* é delegada — se a função `verify_dsa` mente, o pin é irrelevante.

Esta é a forma "menos elegante" dos três problemas porque é facilmente resolvível — é apenas consequência de não ter ML-DSA local.

### Implica no protocolo PQC?

**Sim, indirectamente.** Viola um princípio básico de design de protocolos: verificação de assinatura deve ser feita pelo destinatário, não pelo emissor. ML-DSA foi desenhado precisamente para que qualquer um com a chave pública possa verificar autonomamente. Delegar a verificação ao próprio assinante anula a propriedade de autenticação.

### Como resolver

Quando o Problema 1 estiver resolvido (ML-DSA no dispositivo via plugin nativo), o cliente já tem a primitiva `verify`. Basta:

1. Importar `DevicePqcService` em `supabase_pqc_handshake_service.dart`.
2. Substituir `_verificarAssinatura()` para chamar `DevicePqcService.verifyDsa(pubKey, message, signature)` localmente.
3. Eliminar Edge Function `verify_dsa` do projeto (já não é chamada).

Stub Dart já existe: `DevicePqcService.verifyDsa(...)` em `lib/services/device_pqc_service.dart`. Mais uma vez, falta o plugin nativo.

### ✅ Resolução implementada (Android)

- `PqcPlugin.verifyDsa(publicKey, message, signature)` — implementação Kotlin via `MLDSASigner.init(false, pub)` + `update + verifySignature`.
- `SupabasePqcHandshakeService._verificarAssinatura` agora chama `DevicePqcService.verifyDsa()` localmente quando disponível. Fallback para Edge Function `verify_dsa` só se o plugin não estiver disponível (iOS ou erro nativo).
- Trust circular eliminado no Android: a verificação acontece no dispositivo do utilizador, com a pubkey TOFU-pinned em `TrustedServerKeyService`.

**Estado iOS:** continua a usar `verify_dsa` server-side. Fica resolvido em conjunto com o plugin Swift do Problema 1.

---

## Como os três problemas se relacionam com o protocolo PQC

O protocolo PQC assenta em três pilares:

1. **KEM (ML-KEM-768)** — para confidencialidade contra atacante quântico.
2. **Assinatura (ML-DSA-65)** — para autenticação não-repudiável.
3. **Trust boundary no dispositivo** — chaves nunca devem sair do dispositivo do utilizador.

Cada problema crítico viola pelo menos dois pilares:

| Problema | KEM | Assinatura | Trust |
|---|:-:|:-:|:-:|
| 1. Privada no servidor | — | ❌ | ❌ |
| 2. Sem PFS handshake | ❌ | — | ❌ |
| 3. Verify_dsa circular | — | ❌ | ❌ |

Os três estão amarrados pela mesma raiz: **falta de primitivas PQC no dispositivo**. Resolver um sem os outros é melhoria parcial. A solução é uma só, embora com etapas:

### Caminho de resolução (sprint plan)

| Sprint | Trabalho | Resolve |
|---|---|---|
| 1 | Criar plugin Pigeon `pqc.dart` + Kotlin stub BouncyCastle + iOS Swift stub | Infra |
| 2 | Implementar ML-DSA-65 keygen/sign/verify nativo + testes contra `@noble/post-quantum` golden vectors | Base do P1 |
| 3 | Onboarding: gerar par no signup, registar via `register_client_pubkey()` | P1 funcional |
| 4 | Substituir `_assinarPayload()` por chamada nativa. Migração Vagner/Maude no primeiro login. | **P1 resolvido** |
| 5 | Implementar ML-KEM-768 encapsulate nativo + Hybrid X25519+ML-KEM | Base do P2 |
| 6 | Refazer fluxo de handshake: servidor envia pubkey KEM, cliente encapsula localmente | **P2 resolvido** |
| 7 | Substituir `_verificarAssinatura()` por `DevicePqcService.verifyDsa`. Eliminar Edge Function `verify_dsa`. | **P3 resolvido** |
| 8 | Limpeza: apagar `flutter_client_keys.secret_key_base64`, `flutter_sign_transfer`, `pqc_handshake_flutter` | Drift técnica |

Total estimado: 4–6 semanas com 1 engenheiro Flutter familiar com Kotlin/Swift. Após estes 8 passos, a app passa a respeitar o que o nome "BJ Bank — Banca digital pós-quântica" promete. Antes deles, é teatro criptográfico bem encenado.
