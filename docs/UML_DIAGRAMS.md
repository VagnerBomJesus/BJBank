# BJBank — Diagramas UML

Documento consolidado com todos os diagramas UML do sistema, escritos em **Mermaid** (renderização automática em GitHub, GitLab, IDEs Markdown).

Versão refletida: **v1.2.0** (Junho 2026) — pós-implementação do plugin nativo Android + endurecimento criptográfico.

## Índice

1. [Diagrama de Componentes — Arquitectura geral](#1-diagrama-de-componentes--arquitectura-geral)
2. [Diagrama de Deployment — Distribuição física](#2-diagrama-de-deployment--distribuição-física)
3. [Diagrama de Sequência — Onboarding PQC (login/signup)](#3-diagrama-de-sequência--onboarding-pqc)
4. [Diagrama de Sequência — Transferência segura (protocolo wire v2)](#4-diagrama-de-sequência--transferência-segura)
5. [Diagrama de Sequência — Handshake PQC](#5-diagrama-de-sequência--handshake-pqc)
6. [Diagrama de Estado — Sessão PQC](#6-diagrama-de-estado--sessão-pqc)
7. [Diagrama de Estado — Chave ML-DSA do utilizador](#7-diagrama-de-estado--chave-ml-dsa-do-utilizador)
8. [Diagrama de Classes — Camada de serviços PQC](#8-diagrama-de-classes--camada-de-serviços-pqc)
9. [Diagrama de Classes — Providers (gestão de estado)](#9-diagrama-de-classes--providers)
10. [Diagrama Entidade-Relacionamento — Schema Postgres](#10-diagrama-entidade-relacionamento--schema-postgres)
11. [Diagrama de Fluxo de Dados — Geração de IBAN](#11-diagrama-de-fluxo-de-dados--geração-de-iban)
12. [Diagrama de Atividade — Anti-replay multi-camada](#12-diagrama-de-atividade--anti-replay)
13. [Diagrama de Sequência — Handshake PFS pós-quântico (KEM v2)](#13-diagrama-de-sequência--handshake-pfs-pós-quântico-kem-v2)
14. [Diagrama Comparativo — Modo legacy vs KEM](#14-diagrama-comparativo--modo-legacy-vs-kem)

---

## 1. Diagrama de Componentes — Arquitectura geral

Vista de alto nível: três camadas (Flutter UI, Edge Functions, Postgres) e a trust boundary onde a cripto privada vive.

```mermaid
flowchart TB
    subgraph Dispositivo["📱 Dispositivo Android — Trust Boundary"]
        direction TB
        UI["Flutter UI<br/>(Screens + Widgets)"]
        Providers["Providers<br/>(AuthProvider, AccountProvider, ...)"]
        Services["Services Dart<br/>(SupabaseTransferService, SupabasePqcHandshakeService)"]
        DevicePqc["DevicePqcService<br/>(MethodChannel bridge)"]
        Native["PqcPlugin.kt<br/>BouncyCastle 1.80<br/>ML-DSA-65 + ML-KEM-768"]
        Keystore[("🔒 EncryptedSharedPreferences<br/>Keystore-backed<br/>(StrongBox/TEE)")]
        UI --> Providers
        Providers --> Services
        Services --> DevicePqc
        DevicePqc -.MethodChannel.-> Native
        Native --> Keystore
    end

    subgraph Supabase["☁️ Supabase Cloud"]
        direction TB
        EdgeFn["Edge Functions Deno 2.1<br/>@noble/post-quantum 0.4"]
        Postgres[("PostgreSQL 17<br/>15 tabelas + RPCs<br/>Row Level Security")]
        Realtime["Realtime<br/>WebSocket"]
        Auth["Supabase Auth<br/>JWT + GoTrue"]
        EdgeFn --> Postgres
        Realtime --> Postgres
        Auth --> Postgres
    end

    Services -- "REST + JWT" --> Auth
    Services -- "invoke()" --> EdgeFn
    Services -- "channel.subscribe()" --> Realtime

    classDef trust fill:#d4edda,stroke:#28a745,stroke-width:2px,color:#000
    classDef cloud fill:#cfe2ff,stroke:#0d6efd,stroke-width:2px,color:#000
    class Dispositivo trust
    class Supabase cloud
```

**Pontos críticos:**
- A `Trust Boundary` é o próprio dispositivo Android. Privada ML-DSA do utilizador nunca atravessa esta linha.
- iOS ainda fora desta boundary (privada em `flutter_client_keys.secret_key_base64` no Postgres). Plano: plugin Swift análogo.

---

## 2. Diagrama de Deployment — Distribuição física

```mermaid
flowchart LR
    subgraph Android["📱 Android Device"]
        App["BJ Bank APK<br/>(com.bjbank.ipg)"]
        BC["BouncyCastle 1.80<br/>(dexed)"]
        TEE["TEE / StrongBox<br/>(AndroidKeyStore)"]
        App --- BC
        BC --- TEE
    end

    subgraph PlayStore["Google Play"]
        Listing["Store listing pt-PT<br/>6 phone + 4×7-inch + 4×10-inch screenshots"]
    end

    subgraph SupabaseRegion["☁️ Supabase eu-north-1"]
        FN1["pqc_bootstrap"]
        FN2["pqc_handshake_flutter"]
        FN3["executar_transferencia (v2)"]
        FN4["flutter_sign_transfer (legado)"]
        FN5["verify_dsa (legado)"]
        FN6["bench_server_pqc"]
        FN7["send_otp_email"]
        DB[("PostgreSQL 17")]
        FN1 & FN2 & FN3 & FN4 & FN5 & FN6 & FN7 --> DB
    end

    subgraph External["Externos"]
        Resend["Resend<br/>(OTP email)"]
    end

    App -- "TLS 1.3<br/>JWT" --> FN1 & FN2 & FN3
    App -.fallback iOS.-> FN4 & FN5
    FN7 --> Resend
    Listing -.distribui.- App
```

---

## 3. Diagrama de Sequência — Onboarding PQC

Acontece automaticamente após **login** ou **signup** bem sucedidos. Idempotente — pode ser chamado várias vezes sem efeitos.

```mermaid
sequenceDiagram
    autonumber
    actor U as Utilizador
    participant LS as LoginScreen
    participant AP as AuthProvider
    participant SA as SupabaseAuthService
    participant DO as DevicePqcOnboardingService
    participant DP as DevicePqcService
    participant Native as PqcPlugin.kt
    participant KS as EncryptedSharedPreferences
    participant RPC as Postgres RPC

    U->>LS: email + password
    LS->>AP: login(email, password)
    AP->>SA: signIn(...)
    SA-->>AP: User
    AP->>AP: refreshProfile()
    AP-)DO: _onboardPqc() (fire-and-forget)

    DO->>DP: isAvailable()
    DP->>Native: invokeMethod('isAvailable')
    Native-->>DP: true (Android)
    DP-->>DO: true

    DO->>DP: hasKey()
    DP->>Native: invokeMethod('hasKey')
    Native->>KS: contains(priv) && contains(pub)
    KS-->>Native: false (primeira vez)
    Native-->>DP: false
    DP-->>DO: false

    DO->>DP: generateDsaAndGetPublic()
    DP->>Native: invokeMethod('generateDsa')
    Native->>Native: MLDSAKeyPairGenerator.init(ml_dsa_65)<br/>+ generateKeyPair()
    Native->>KS: put(priv base64) + put(pub base64)
    Native-->>DP: {publicKey: 1952B, privateKey: 4032B}
    DP-->>DO: publicKey (1952B)

    DO->>RPC: register_client_pubkey(pubBase64)
    RPC->>RPC: UPDATE flutter_client_keys SET revoked_at=now() WHERE user_id=uid AND revoked_at IS NULL
    RPC->>RPC: INSERT flutter_client_keys (managed_by='device', migrated_at=now())
    RPC-->>DO: uuid (user_id)

    DO-->>AP: OnboardingResult.created()
    AP-->>LS: login OK
    LS-->>U: navega para Home
```

---

## 4. Diagrama de Sequência — Transferência segura

Fluxo completo de transferência com o **protocolo wire v2** (serial monotónico + protocolVersion=2). Privada ML-DSA vive no Keystore — assinatura é local no Android.

```mermaid
sequenceDiagram
    autonumber
    participant Caller as Screen
    participant STS as SupabaseTransferService
    participant HS as SupabasePqcHandshakeService
    participant DP as DevicePqcService
    participant Native as PqcPlugin
    participant EF as executar_transferencia<br/>(Edge Function v2)
    participant DB as Postgres

    Caller->>STS: executar(origem, destino, montante, descricao)
    STS->>HS: obterOuEstabelecer()
    alt Sessão em cache (<50 min)
        HS-->>STS: SessionKeys (cached)
    else Expirada localmente
        HS->>EF: pqc_handshake_flutter
        EF->>DB: INSERT sessions
        EF-->>HS: {sessionId, sharedSecret, signature}
        HS->>DP: verifyDsa(serverPub, transcript, sig)
        DP->>Native: invokeMethod('verifyDsa')
        Native-->>DP: true
        HS-->>STS: SessionKeys (nova)
    end

    STS->>STS: serial = _proximoSerial(sessionId)
    STS->>STS: payload_v2 = canonical(<br/>txId, origem.upper, destino.upper,<br/>montante.fixed(2), descricao.trim,<br/>timestamp, nonce, serial)

    STS->>DP: signDsa(payload_v2)
    DP->>Native: invokeMethod('signDsa', {message})
    Native->>Native: load priv from EncryptedSharedPreferences
    Native->>Native: MLDSASigner.init(forSigning=true)<br/>.update(msg).generateSignature()
    Native-->>DP: signature (3309B)
    DP-->>STS: signature

    STS->>DP: getPublicKey()
    DP-->>STS: clientDsaPublic (1952B)

    STS->>STS: envelope = [len|payload|len|sig]
    STS->>STS: iv = Random.secure(12B)
    STS->>STS: ciphertext = AES-256-GCM(<br/>envelope, sessionKey, iv,<br/>aad=sessionId)

    STS->>EF: POST executar_transferencia {<br/>sessionId, ivBase64,<br/>envelopeBase64,<br/>clientDsaPublicBase64,<br/>protocolVersion: 2, serial}

    EF->>DB: SELECT sessions (user, sharedSecret, last_serial)
    DB-->>EF: row
    EF->>EF: rejeita se serial <= last_serial
    EF->>EF: decifra envelope com sessionKey

    EF->>DB: pubkey_for_user(uid)
    DB-->>EF: registered_pub
    EF->>EF: rejeita se clientDsaPub != registered_pub (412)

    EF->>EF: ml_dsa65.verify(pub, payload, sig)
    EF->>EF: reconstrói canonical v2 byte-a-byte
    EF->>EF: rejeita se |now - timestamp| > 30s

    EF->>DB: RPC executar_transferencia_atomica(...)
    Note over DB: SELECT FOR UPDATE origem<br/>UNIQUE(txId)<br/>UPDATE saldos<br/>INSERT transactions
    DB-->>EF: OK

    EF->>DB: UPDATE sessions SET last_serial = serial
    EF-->>STS: {status: 'OK', txId}
    STS-->>Caller: txId
```

---

## 5. Diagrama de Sequência — Handshake PQC

Detalhe do estabelecimento de sessão. Cliente verifica localmente a assinatura ML-DSA do servidor (sem `verify_dsa` server-side).

```mermaid
sequenceDiagram
    autonumber
    participant HS as SupabasePqcHandshakeService
    participant TS as TrustedServerKeyService<br/>(TOFU pinning)
    participant FN1 as pqc_bootstrap
    participant FN2 as pqc_handshake_flutter
    participant DP as DevicePqcService
    participant Native as PqcPlugin
    participant DB as Postgres

    Note over HS: 1. Bootstrap (1ª vez ou cache miss)
    HS->>TS: temChavePublica()?
    TS-->>HS: false
    HS->>FN1: GET pqc_bootstrap
    FN1->>DB: SELECT public_config WHERE key='server_ml_dsa'
    DB-->>FN1: serverDsaPub
    FN1-->>HS: {serverDsaPublicBase64}
    HS->>TS: setTrustedKey(serverDsaPub)
    TS->>TS: persist em FlutterSecureStorage

    Note over HS: 2. Handshake
    HS->>HS: clientNonce = Random.secure(32B)
    HS->>FN2: POST {clientNonceBase64}
    FN2->>FN2: sharedSecret = randomBytes(32)
    FN2->>FN2: transcript = clientNonce ‖ sharedSecret ‖<br/>serverDsaPub ‖ sessionId
    FN2->>FN2: signature = ml_dsa65.sign(serverPriv, transcript)
    FN2->>DB: INSERT sessions (sharedSecret, expires_at=now+1h)
    FN2-->>HS: {sessionId, sharedSecret, signature, serverDsaPub}

    Note over HS: 3. Pin check + verificação LOCAL (Android)
    HS->>TS: verificar(serverDsaPub)
    TS->>TS: constant-time compare vs pinned
    TS-->>HS: OK (sem mismatch)

    HS->>HS: reconstrói transcript
    HS->>DP: verifyDsa(serverDsaPub, transcript, signature)
    DP->>Native: invokeMethod('verifyDsa')
    Native->>Native: MLDSASigner.init(forSigning=false, pubKeyParams)<br/>.update(transcript).verifySignature(sig)
    Native-->>DP: true
    DP-->>HS: true

    Note over HS: 4. Derivação chave AES
    HS->>HS: derived = HKDF-SHA-256(<br/>sharedSecret, salt=sessionId,<br/>info='BJBank-v1|session-keys', 44B)
    HS->>HS: SessionKeys(<br/>sessionId, aesKey=derived[0:32],<br/>nonceBase=derived[32:44])
    HS->>HS: _cached = session; _cachedAt = now()
```

---

## 6. Diagrama de Estado — Sessão PQC

Estados do singleton `SupabasePqcHandshakeService` em runtime.

```mermaid
stateDiagram-v2
    [*] --> Idle: app launch
    Idle --> Bootstrapping: obterOuEstabelecer()<br/>(TOFU pin ausente)
    Idle --> Handshaking: obterOuEstabelecer()<br/>(TOFU pin existe)
    Bootstrapping --> Handshaking: bootstrap OK
    Bootstrapping --> Failed: bootstrap erro
    Handshaking --> Verifying: handshake response
    Verifying --> Active: verifyDsa OK
    Verifying --> Failed: verifyDsa falha<br/>(MitM ou erro)

    Active --> Active: transferência<br/>(idade < 50 min)
    Active --> Idle: invalidar() / logout
    Active --> Idle: idade >= 50 min<br/>(TTL local)

    Failed --> Idle: retry manual
    note right of Active
        _cached != null
        _cachedAt != null
        idade < _maxAge (50min)
    end note
    note right of Idle
        _cached == null
    end note
```

---

## 7. Diagrama de Estado — Chave ML-DSA do utilizador

Ciclo de vida da chave no `flutter_client_keys`, com transições server-managed → device-managed.

```mermaid
stateDiagram-v2
    [*] --> NoKey: signup (sem trigger registo PQC ainda)
    NoKey --> ServerManaged: 1ª transferência (legado)<br/>flutter_sign_transfer gera par<br/>secret_key_base64 NOT NULL
    NoKey --> DeviceManaged: signup novo (v1.2)<br/>onboarding → register_client_pubkey<br/>managed_by='device'<br/>secret_key_base64 NULL

    ServerManaged --> DeviceManaged: utilizador legado<br/>faz login no Android<br/>onboarding gera par local<br/>revoked_at = now()<br/>(nova entrada com managed_by='device')

    DeviceManaged --> Revoked: register_client_pubkey<br/>(reinstalação,<br/>mudança de dispositivo)
    ServerManaged --> Revoked: register_client_pubkey
    Revoked --> [*]: opcional: DELETE histórico

    note right of DeviceManaged
        ✅ Trust no dispositivo
        ✅ Não-repúdio real
        ✅ Privada no Keystore/StrongBox
    end note
    note right of ServerManaged
        ⚠️ Privada no Postgres
        ❌ Servidor pode forjar
        Legado iOS + utilizadores antigos
    end note
```

---

## 8. Diagrama de Classes — Camada de serviços PQC

```mermaid
classDiagram
    class SupabaseTransferService {
        -SupabasePqcHandshakeService _handshake
        -Map~String,int~ _serialPorSessao
        -int _protocolVersion = 2
        +executar(origem, destino, montante, descricao) Future~String~
        -_construirPayloadV2(...) Uint8List
        -_assinarPayload(payload) Future~_Assinatura~
        -_aesGcmCifrar(key, iv, plaintext, aad) Uint8List
        -_proximoSerial(sessionId) int
    }

    class SupabasePqcHandshakeService {
        -TrustedServerKeyService _trusted
        -SessionKeys? _cached
        -DateTime? _cachedAt
        -static Duration _maxAge = 50min
        +obterOuEstabelecer() Future~SessionKeys~
        +invalidar() Future~void~
        -_executarBootstrap() Future~void~
        -_executarHandshake() Future~_HandshakeResposta~
        -_verificarAssinatura(r) Future~void~
        -_derivarSessionKeys(ikm, sessionId) SessionKeys
    }

    class DevicePqcService {
        <<singleton>>
        -bool? _available
        +isAvailable() Future~bool~
        +hasKey() Future~bool~
        +generateDsaAndGetPublic() Future~Uint8List~
        +getPublicKey() Future~Uint8List~
        +signDsa(message) Future~Uint8List~
        +verifyDsa(publicKey, message, signature) Future~bool~
        +kemEncapsulate(serverPubKey) Future~DeviceKemEncapsulation~
        +revokeKey() Future~void~
    }

    class DevicePqcOnboardingService {
        <<singleton>>
        -DevicePqcService _pqc
        +ensureKey() Future~OnboardingResult~
        +clearLocal() Future~void~
        -_fetchRegisteredPubkey() Future~String?~
        -_registerOnServer(pubBase64) Future~void~
    }

    class TrustedServerKeyService {
        +setTrustedKey(bytes) Future~void~
        +getTrustedKey() Future~Uint8List?~
        +temChavePublica() Future~bool~
        +verificar(serverKey) Future~void~
    }

    class PqcPlugin {
        <<Kotlin native>>
        -SharedPreferences prefs
        +generateDsa() Map
        +signDsa(message) ByteArray
        +verifyDsa(pub, msg, sig) Boolean
        +kemEncapsulate(serverPub) Map
        +revokeKey() void
    }

    class SessionKeys {
        +String sessionId
        +Uint8List chaveCifragem (32B)
        +Uint8List nonceBase (12B)
    }

    class DeviceKemEncapsulation {
        +Uint8List ciphertext (1088B)
        +Uint8List sharedSecret (32B)
    }

    SupabaseTransferService --> SupabasePqcHandshakeService
    SupabaseTransferService --> DevicePqcService
    SupabasePqcHandshakeService --> TrustedServerKeyService
    SupabasePqcHandshakeService --> DevicePqcService
    SupabasePqcHandshakeService --> SessionKeys
    DevicePqcOnboardingService --> DevicePqcService
    DevicePqcService ..> PqcPlugin : MethodChannel<br/>'com.bjbank.ipg/pqc'
    DevicePqcService --> DeviceKemEncapsulation
```

---

## 9. Diagrama de Classes — Providers

Vista da camada `Provider + ChangeNotifier` (ver `ADR-002`).

```mermaid
classDiagram
    class ChangeNotifier {
        <<Flutter abstract>>
        +notifyListeners() void
        +addListener(VoidCallback)
        +removeListener(VoidCallback)
    }

    class AuthProvider {
        -SupabaseAuthService _auth
        -FirestoreService _profile
        -UserModel? _user
        -bool _isLoading
        -String? _errorMessage
        +login(email, password) Future~bool~
        +register(email, password, name, phone) Future~bool~
        +logout() Future~void~
        +sendPasswordReset(email) Future~bool~
        -_onboardPqc() Future~void~
    }

    class AccountProvider {
        -AccountService _accountService
        -Account? _primaryAccount
        -List~Transaction~ _transactions
        -StreamSubscription? _accountSubscription
        +loadAccount(userId) Future~void~
        +refreshTransactions(userId) Future~void~
    }

    class TransferProvider {
        -SupabaseTransferService _service
        +executar(origem, destino, montante, descricao) Future~String~
    }

    class MbwayProvider {
        -SupabaseMbwayService _service
        +activar(phone) Future~void~
        +lookupContact(phone) Future~MbwayContact?~
    }

    class SettingsProvider {
        +bool ocultarSaldo
        +ThemeMode tema
        +toggle...()
    }

    ChangeNotifier <|-- AuthProvider
    ChangeNotifier <|-- AccountProvider
    ChangeNotifier <|-- TransferProvider
    ChangeNotifier <|-- MbwayProvider
    ChangeNotifier <|-- SettingsProvider

    AccountProvider ..> AuthProvider : depends (userId)<br/>via ChangeNotifierProxyProvider
    TransferProvider ..> AccountProvider : refresh após sucesso
    MbwayProvider ..> AccountProvider : refresh após sucesso
```

---

## 10. Diagrama Entidade-Relacionamento — Schema Postgres

Tabelas principais. 15 tabelas no total — aqui as 8 críticas para o pipeline PQC + banca.

```mermaid
erDiagram
    auth_users ||--|| users : "1:1"
    users ||--o{ accounts : "1:N"
    users ||--o{ flutter_client_keys : "1:N (histórico)"
    accounts ||--o{ transactions : "1:N"
    accounts ||--o| mbway_phones : "1:1 opcional"
    users ||--o{ mbway_contacts : "1:N (owner)"
    sessions }o--|| users : "N:1"

    auth_users {
        uuid id PK
        text email
        jsonb raw_user_meta_data
    }

    users {
        uuid id PK_FK
        text email
        text nome_completo
        text phone "+351XXXXXXXXX"
        text photo_url
        text pqc_public_key_base64 "legado v1.1"
        timestamptz created_at
    }

    accounts {
        uuid id PK
        uuid user_id FK
        text iban UK "PT50..."
        text nome
        numeric saldo
        text moeda "EUR"
        text tipo "CORRENTE | POUPANCA"
        timestamptz created_at
    }

    transactions {
        uuid id PK
        uuid account_id FK
        text conta_origem_iban
        text conta_destino_iban
        numeric montante "+- (negativo origem)"
        text descricao
        timestamptz timestamp
        bytea nonce
        bytea assinatura_mldsa
        bytea cliente_dsa_public
        text session_id
        text estado "CONFIRMADA | PENDENTE"
    }

    sessions {
        text id PK "UUID"
        uuid user_id FK
        text shared_secret_base64
        bigint expires_at "epoch millis"
        integer last_serial "anti-replay v2"
        timestamptz created_at
    }

    flutter_client_keys {
        uuid user_id FK
        text public_key_base64
        text secret_key_base64 "NULL se device-managed"
        text managed_by "server | device"
        timestamptz revoked_at
        timestamptz migrated_at
        timestamptz criada_em
    }

    mbway_phones {
        text phone PK "+351XXXXXXXXX"
        uuid account_id FK UK
        uuid user_id FK
        boolean ativo
        timestamptz criada_em
    }

    mbway_contacts {
        uuid id PK
        uuid owner_user_id FK
        text name
        text phone
        timestamptz last_used
        integer use_count
    }
```

---

## 11. Diagrama de Fluxo de Dados — Geração de IBAN

Como uma conta nova recebe `PT50 9999 0001 …` válido.

```mermaid
flowchart LR
    Signup(["Auth.signUp(email, password)"]) --> Trigger["TRIGGER on_auth_user_created"]
    Trigger --> Fn["tg_handle_new_user()"]
    Fn --> CheckUser{User existe<br/>em public.users?}
    CheckUser -- não --> InsertUser["INSERT public.users<br/>(id, email, nome)"]
    CheckUser -- sim --> CheckAcc
    InsertUser --> CheckAcc{Já tem<br/>conta?}
    CheckAcc -- sim --> Fim((Fim))
    CheckAcc -- não --> Gen["bjbank_gerar_iban_pt()"]

    subgraph IBAN["Geração IBAN PT"]
        Gen --> P1["banco := '9999'<br/>balcao := '0001'"]
        P1 --> P2["conta := 11×random(0..9)"]
        P2 --> P3["nib_19 := banco ‖ balcao ‖ conta"]
        P3 --> CalcNib["bjbank_calcular_check_nib(nib_19)<br/>algoritmo BdP<br/>Σ(digit×peso) mod 97 → 98-resto"]
        CalcNib --> P4["bban := nib_19 ‖ check_nib"]
        P4 --> CalcIban["bjbank_calcular_iban_check(bban)<br/>MOD-97-10 ISO 7064"]
        CalcIban --> Retorno["RETURN 'PT' ‖ check_iban ‖ bban<br/>(sempre PT50 porque NIB válido)"]
    end

    Retorno --> InsertAcc["INSERT accounts<br/>(user_id, iban, saldo=0, moeda='EUR')"]
    InsertAcc --> Fim
```

---

## 12. Diagrama de Atividade — Anti-replay

Multi-camada: TLS, sessão, timestamp, txId único, serial monotónico.

```mermaid
flowchart TD
    Start([POST executar_transferencia]) --> CheckJWT{JWT válido?}
    CheckJWT -- não --> R401([401 Unauthorized])
    CheckJWT -- sim --> CheckSess{Sessão existe<br/>+ não expirada?}
    CheckSess -- não --> R410([410 Sessão expirada])
    CheckSess -- sim --> CheckOwner{Sessão pertence<br/>ao user JWT?}
    CheckOwner -- não --> R403([403 Forbidden])
    CheckOwner -- sim --> CheckSerial{protocolVersion=2<br/>+ serial > last_serial?}
    CheckSerial -- não --> R409([409 Serial replay])
    CheckSerial -- sim --> Decrypt["AES-256-GCM decrypt envelope"]
    Decrypt -- falha tag --> R400([400 Auth falhou])
    Decrypt -- sucesso --> CheckPubKey{Pubkey enviada =<br/>pubkey_for_user?}
    CheckPubKey -- não registada --> R412([412 Precondition])
    CheckPubKey -- diferente --> R403b([403 Pubkey mismatch])
    CheckPubKey -- igual --> VerifySig{ml_dsa65.verify<br/>OK?}
    VerifySig -- não --> R403c([403 Assinatura inválida])
    VerifySig -- sim --> Canonical{Canonical v2<br/>byte-a-byte =<br/>recebido?}
    Canonical -- não --> R400b([400 Payload não canónico])
    Canonical -- sim --> CheckTime{nowtimestamp\| ≤ 30s?}
    CheckTime -- não --> R400c([400 Replay temporal])
    CheckTime -- sim --> CheckTxId{txId UUID válido<br/>+ não usado?}
    CheckTxId -- duplicado --> R409b([409 UNIQUE violation])
    CheckTxId -- sim --> RPC["RPC executar_transferencia_atomica<br/>(SELECT FOR UPDATE, INSERT)"]
    RPC --> UpdateSerial["UPDATE sessions.last_serial = serial"]
    UpdateSerial --> Ok([200 OK txId])

    classDef rejected fill:#f8d7da,stroke:#dc3545,color:#000
    class R401,R403,R403b,R403c,R409,R409b,R410,R412,R400,R400b,R400c rejected
    classDef ok fill:#d4edda,stroke:#28a745,color:#000
    class Ok ok
```

---

## 13. Diagrama de Sequência — Handshake PFS pós-quântico (KEM v2)

Fluxo **completo** do handshake em modo KEM (Android v1.3.0+). Substitui o flow legado para clientes que declaram `clientKemCapability=true`.

```mermaid
sequenceDiagram
    autonumber
    participant HS as SupabasePqcHandshake&#xa;Service
    participant TS as TrustedServerKeyService&#xa;(TOFU pin)
    participant DP as DevicePqcService
    participant Native as PqcPlugin.kt&#xa;(MLKEMGenerator)
    participant EF1 as pqc_handshake_flutter v2
    participant EF2 as pqc_handshake_kem_complete
    participant DB as Postgres
    Note over HS,DB: Modo KEM — sharedSecret NUNCA atravessa a rede em claro

    HS->>HS: nonce = Random.secure(32B)
    HS->>EF1: POST {clientNonceBase64, clientKemCapability: true}
    EF1->>EF1: kemPair = ml_kem768.keygen(seed)<br/>serverKemPub (1184B)<br/>kemSecret (2400B)
    EF1->>EF1: transcript = clientNonce ‖ serverKemPub ‖ serverDsaPub ‖ sessionId
    EF1->>EF1: signature = ml_dsa65.sign(serverDsaPriv, transcript)
    EF1->>DB: cleanup_pending_kem_sessions() [>5min]
    EF1->>DB: INSERT pending_kem_sessions(sessionId, kemSecret, ...)
    EF1-->>HS: {mode: 'kem', sessionId, serverKemPub, serverDsaPub, signature}

    HS->>TS: verificar(serverDsaPub)
    TS-->>HS: OK (TOFU pin)
    HS->>DP: verifyDsa(serverDsaPub, transcript, signature)
    DP->>Native: invokeMethod('verifyDsa')
    Native->>Native: MLDSASigner.init(forSigning=false).update.verifySignature
    Native-->>DP: true
    DP-->>HS: true

    Note over HS,Native: Encapsulação LOCAL — kemSecret nunca cruza network

    HS->>DP: kemEncapsulate(serverKemPub)
    DP->>Native: invokeMethod('kemEncapsulate')
    Native->>Native: MLKEMGenerator.generateEncapsulated(serverKemPub)
    Native-->>DP: {ciphertext: 1088B, sharedSecret: 32B}
    DP-->>HS: encap

    Note over HS,EF2: 2ª fase — envia só o ciphertext

    HS->>EF2: POST {sessionId, ciphertextBase64}
    EF2->>DB: SELECT pending_kem_sessions WHERE id=sessionId
    DB-->>EF2: {kemSecret, created_at}
    EF2->>EF2: rejeita se TTL > 5min
    EF2->>EF2: sharedSecret = ml_kem768.decapsulate(ciphertext, kemSecret)
    EF2->>DB: INSERT sessions (sharedSecret, expires_at=now+1h)
    EF2->>DB: DELETE pending_kem_sessions WHERE id=sessionId
    Note over EF2,DB: 🔥 kemSecret DESTRUÍDA — sessões antigas safe contra HNDL
    EF2-->>HS: {ok: true, sessionId}

    HS->>HS: derived = HKDF-SHA-256(sharedSecret, salt=sessionId, info, 44B)<br/>aesKey = derived[0:32]<br/>nonceBase = derived[32:44]
    HS->>HS: _cached = SessionKeys(...)
```

---

## 14. Diagrama Comparativo — Modo legacy vs KEM

Lado a lado o que vai pela rede em cada modo. Visualização imediata da defesa contra HNDL.

```mermaid
flowchart TB
    subgraph leg["🔴 MODO LEGACY (iOS)"]
        direction TB
        l1["Cliente envia clientNonce 32B"] --> l2["Servidor gera sharedSecret 32B"]
        l2 --> l3["Servidor envia sharedSecret EM CLARO via TLS"]
        l3 --> l4["⚠️ HNDL aplicável"]
        l4 --> l5["Atacante grava TLS hoje<br/>quebra X25519 daqui a 5-10 anos<br/>lê sharedSecret<br/>decifra TODO o tráfego"]
    end

    subgraph kem["🟢 MODO KEM v1.3.0 (Android)"]
        direction TB
        k1["Cliente envia clientNonce 32B + clientKemCapability=true"] --> k2["Servidor gera par ML-KEM-768 efémero<br/>(persiste priv 5min em pending_kem_sessions)"]
        k2 --> k3["Servidor envia serverKemPub 1184B + assinatura ML-DSA"]
        k3 --> k4["Cliente Android faz kemEncapsulate LOCAL<br/>obtém (ciphertext 1088B, sharedSecret 32B)"]
        k4 --> k5["Cliente envia SÓ o ciphertext"]
        k5 --> k6["Servidor decapsula com priv → mesmo sharedSecret<br/>APAGA pending_kem_sessions"]
        k6 --> k7["✅ sharedSecret NUNCA viajou em claro<br/>HNDL falha — precisa quebrar ML-KEM-768"]
    end

    classDef bad fill:#f8d7da,stroke:#dc3545,color:#000
    classDef good fill:#d4edda,stroke:#28a745,color:#000
    class leg bad
    class kem good
```

---

## Notas de manutenção

- **Quando refazer**: ao introduzir nova Edge Function, RPC, ou mudança no protocolo wire. Para nova versão do protocolo (ex: v=3 com KEM on-device), adicionar novo diagrama sem apagar o v2.
- **Como editar**: este ficheiro é puro Markdown com blocos Mermaid. GitHub renderiza automaticamente. IDE: instalar extensão "Markdown Preview Mermaid Support".
- **Verificar sintaxe**: <https://mermaid.live/edit>
