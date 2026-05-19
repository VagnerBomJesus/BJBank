# Contributing to BJBank

**BJBank** é um projecto académico de investigação focado em Criptografia Pós-Quântica aplicada a banca móvel. Este documento descreve as convenções e fluxo de trabalho para contribuir.

---

## Contexto académico

Dissertação de Mestrado em Cibersegurança · Instituto Politécnico da Guarda · 2026.

**Apropriado para**: investigação académica, fins educativos, *bug reports*, *security disclosures*, extensões de pesquisa.

**Não apropriado para**: sistemas bancários em produção, uso comercial, aplicações concorrentes.

---

## Stack técnica (v1.1.0)

| Camada | Tecnologia | Responsabilidade |
|---|---|---|
| **Cliente** | Flutter 3.8.1 + Dart 3.8.1 | UI, navegação, estado local |
| **Gestão de estado** | provider 6.1+ | ChangeNotifier + ChangeNotifierProxyProvider |
| **Cripto cliente** | pointycastle 3.9 | HKDF-SHA-256, AES-256-GCM, shared_secret derivation |
| **Cripto servidor** | `@noble/post-quantum 0.4` | ML-KEM-768 (encapsulation), ML-DSA-65 (signing) |
| **Backend** | Supabase | GoTrue (Auth), PostgreSQL 15 (RLS), Realtime (WebSocket) |
| **Edge Functions** | Deno 2.1 / V8 11.6 | 8 funções: pqc_bootstrap, handshake, sign, verify, transfer, benchmark |
| **ORM/Queries** | `supabase_flutter` 2.5+ | `SupabaseClient` com PostgrestClient |
| **Deep Links** | `app_links` 4.0+ | `bjbank://reset`, `bjbank://login` |

A aplicação corre exclusivamente em Flutter (multi-plataforma) — sem clientes nativos Android/iOS separados.

### Fluxo PQC end-to-end (síntese)

```
[Cliente Flutter] →(nonce)→ [Edge Function pqc_handshake_flutter]
                   ←(shared_secret + signature)← [Servidor ML-DSA-65]
         ↓ (verifica assinatura, faz TOFU pin)
    [HKDF-SHA-256] → AES key + nonceBase
         ↓
    [Payload canónico] →(sign via Edge Function)→ [flutter_sign_transfer]
         ↓
    [Envelope cifrado] → AES-256-GCM(IV, AAD)
         ↓ (POST executar_transferencia)
    [Servidor decifra + verifica + executa RPC atómica]
```

---

## Setup inicial

### Pré-requisitos
- Flutter 3.8+ (`flutter doctor` deve passar)
- Dart 3.8+
- Git
- Editor: VS Code + Dart extension, Android Studio, ou Xcode

### Desenvolvimento local

```bash
# 1. Clonar repositório
git clone https://github.com/VagnerBomJesus/BJBank.git
cd bjbank

# 2. Instalar dependências Flutter
flutter pub get

# 3. Verificar setup
flutter doctor

# 4. Escolher plataforma de teste
# Android emulator
emulator -avd <avd_name> &
flutter run -d emulator-5554

# iOS simulator
open -a Simulator
flutter run -d iphone

# Desktop (Windows/macOS/Linux)
flutter run -d windows
```

### Configuração Supabase

Duas opções:

**Opção 1: Usar projeto remoto existente**
```bash
# lib/services/supabase_config.dart já vem com URL + anon key
# Para produção, usar --dart-define:
flutter run \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-anon-key"
```

**Opção 2: Setup local com Supabase CLI** (ver `docs/DEPLOYMENT.md`)
```bash
# Instalar Supabase CLI
npm i -g @supabase/cli

# Inicializar projeto local
supabase init
supabase start

# Correr migrations
supabase migration up

# Usar URL local: http://localhost:54321
```

---

## Arquitectura

A aplicação organiza-se em quatro camadas (ver `docs/ARCHITECTURE.md`):

```
UI Layer (screens, widgets)
   |
   v
State Management (Provider + ChangeNotifier)
   |
   v
Service Layer (singletons)
   |
   v
Backend Supabase (HTTPS + JWT)
```

### Services principais

| Serviço | Ficheiro | Responsabilidade |
|---|---|---|
| **SupabaseAuthService** | `lib/services/supabase_auth_service.dart` | `signIn()`, `signUp()`, `signOut()`, `updatePassword()`, `deleteAccount()`, `sendPasswordReset()` |
| **SupabaseAccountService** | `lib/services/supabase_account_service.dart` | Streams Realtime de `accounts` e `transactions`; lookup saldos |
| **SupabaseTransferService** | `lib/services/supabase_transfer_service.dart` | **Orquestra pipeline PQC**: (1) handshake (2) construir payload canónico (3) assinar (4) cifrar (5) POST RPC |
| **SupabasePqcHandshakeService** | `lib/services/supabase_pqc_handshake_service.dart` | Nonce + shared_secret + HKDF-SHA-256; verifica assinatura servidor |
| **TrustedServerKeyService** | `lib/services/trusted_server_key_service.dart` | TOFU pinning persistente da chave ML-DSA do servidor (SharedPreferences) |
| **SupabaseMbwayService** | `lib/services/supabase_mbway_service.dart` | `activateMbway()`, `deactivateMbway()`, `lookupByPhone()`, `payViaPhone()` |
| **PqcBenchmarkService** | `lib/services/pqc_service.dart` | Benchmark local PoC (simulado, para PoC arquitectural) |
| **ServerPqcBenchmarkService** | `lib/services/server_pqc_benchmark_service.dart` | Invoca `bench_server_pqc` Edge Function; mede primitivas reais (@noble/post-quantum) |
| **DeepLinkHandler** | `lib/services/deep_link_handler.dart` | Rota `bjbank://reset` → ResetPasswordScreen; `bjbank://login` → LoginScreen |

**Instanciação**: todos os services usam **singleton com factory**:
```dart
class MyService {
  static final MyService _instance = MyService._internal();
  factory MyService() => _instance;
  MyService._internal();
}
```

### Providers principais

`AuthProvider`, `AccountProvider`, `MbWayProvider`, `TransferProvider`, `SettingsProvider`, `CardProvider`, `NotificationProvider`.

---

## Casos de uso

A aplicação implementa 34 casos de uso documentados em `MCiber/diagramas/02_casos_de_uso.drawio`. Subsistemas principais:

1. **Autenticação** — registo, login, reset, alterar password, logout, eliminar conta
2. **Perfil** — ver, editar nome/telefone, carregar foto
3. **Transferências** — por IBAN, por MBWay, recibo com badge PQC
4. **MBWay** — ativar, desativar, limites (constraint UNIQUE: 1 número por conta)
5. **Histórico** — ver Realtime, filtrar por tipo, pesquisar, detalhe
6. **Cartões** — gerir definições e limites
7. **PQC** — benchmarks local/servidor, exportar JSON/Markdown
8. **Administração** — via Supabase Dashboard (SQL Editor + Edge Functions)

---

## Workflow de desenvolvimento

### 1. Criar branch

```bash
git checkout -b feat/nome-da-feature
```

Prefixos: `feat/`, `fix/`, `refactor/`, `docs/`, `test/`, `chore/`.

### 2. Implementar uma nova feature

Ordem recomendada:

#### A. Setup no Backend (Supabase)
1. Criar tabela(s) em Postgres com RLS via `supabase migration` ou SQL Editor
2. Se necessário, criar Edge Function em Deno (`functions/src/index.ts`)
3. Testar RPC/Function localmente com `supabase functions serve`

#### B. Frontend Flutter
1. **Modelo** (`lib/models/<feature>_model.dart`)
   - `@immutable` em todos os campos
   - Implementar `copyWith()`, `fromJson()`, `toJson()`
   - Usar `==` e `hashCode` com Equatable ou manual

2. **Service** (`lib/services/supabase_<feature>_service.dart`)
   - Singleton com factory
   - Métodos que chamam Supabase (CRUD, RPC, streaming)
   - Tratamento de erro explícito
   - Documentação JSDoc em métodos públicos

3. **Provider** (`lib/providers/<feature>_provider.dart`)
   - Estender `ChangeNotifier`
   - Usar `ChangeNotifierProxyProvider` se depender de outro
   - Chamar service methods
   - Manter estado simples e reativo

4. **Screen** (`lib/screens/<feature>/<feature>_screen.dart`)
   - `StatelessWidget` por padrão
   - Consumir provider via `context.watch()` ou `context.read()`
   - Validação local antes de chamar service
   - Feedback visual (loading, erro, sucesso)

5. **Routes** (`lib/routes/app_routes.dart`)
   - Adicionar entrada em `AppRoutes`
   - Conectar com Navigator 2.0 se necessário

### 3. Padrões obrigatórios

#### Imutabilidade
```dart
// ✅ BOM
class AccountModel {
  final String id;
  final String iban;
  final double balance;

  const AccountModel({
    required this.id,
    required this.iban,
    required this.balance,
  });
}

// ❌ MALO
class AccountModel {
  var id;  // var não é imutável
  late String iban;  // late é OK para inicialização em factory
}
```

#### Singleton com Factory
```dart
class SupabaseTransferService {
  static final SupabaseTransferService _instance =
    SupabaseTransferService._internal();

  factory SupabaseTransferService() => _instance;
  SupabaseTransferService._internal();
}
```

#### Provider com Dependencies
```dart
// ✅ Quando TransferProvider depende de AuthProvider
ChangeNotifierProxyProvider<AuthProvider, TransferProvider>(
  create: (_) => TransferProvider(),
  update: (_, authProvider, transferProvider) {
    transferProvider?.updateAuth(authProvider);
    return transferProvider!;
  },
)
```

#### Validação Local + Error Handling
```dart
Future<void> executeTransfer(TransferModel transfer) async {
  // 1. Validação local
  if (transfer.amount <= 0) {
    throw ArgumentError('Amount must be positive');
  }

  // 2. Chamar service com try/catch
  try {
    notifyListeners();  // loading state
    final result = await _transferService.execute(transfer);
    _transfer = result;
  } on PqcException catch (e) {
    _error = 'PQC error: ${e.message}';  // erro específico
  } catch (e) {
    _error = 'Unknown error: $e';  // fallback
  } finally {
    notifyListeners();  // atualizar UI
  }
}
```

#### Tratamento de Erro em Services
```dart
// Sempre retornar Result<T> ou lançar exceções específicas
class SupabaseTransferService {
  Future<TransactionModel> execute(TransferModel tx) async {
    try {
      final response = await supabase
        .rpc('executar_transferencia', params: {...});
      return TransactionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw TransactionException('DB error: ${e.message}');
    } on SocketException catch (e) {
      throw NetworkException('Network error: $e');
    }
  }
}
```

### 4. Edge Functions (Deno)

As funções cripto rodam em `functions/src/index.ts`. Para desenvolver:

```bash
# 1. Criar nova função
mkdir functions/src/features/my_feature

# 2. Implementar em TypeScript/Deno
# functions/src/features/my_feature/index.ts
export async function handler(req: Request): Promise<Response> {
  const { data } = await req.json();
  // lógica aqui
  return new Response(JSON.stringify({ result }), {
    headers: { 'Content-Type': 'application/json' },
    status: 200,
  });
}

# 3. Testar localmente
supabase functions serve

# 4. Deploy
supabase functions deploy my_feature
```

**Padrões obrigatórios para Edge Functions**:
- ✅ Validar JWT (`Authorization: Bearer <token>`)
- ✅ Usar `@noble/post-quantum` para operações PQC
- ✅ Logging explícito (`console.log`)
- ✅ Tratamento de erro com status codes apropriados

### 5. Testes

```bash
flutter test                     # corre toda a suite
flutter test test/services/      # só services
flutter test --coverage          # com cobertura
flutter test -v                  # verbose
```

Meta de cobertura: **70% sobre services**, 50% sobre providers.

**Testes de mock Supabase**:
```dart
void main() {
  final mockSupabase = MockSupabaseClient();
  late SupabaseAuthService authService;

  setUp(() {
    authService = SupabaseAuthService();
    // mockSupabase.auth.signUp(...).thenAnswer(...);
  });

  test('signUp returns UserModel on success', () async {
    // expect(...)
  });
}
```

### 5. Análise estática

```bash
flutter analyze                  # tem de passar sem warnings
dart format lib/                 # formatação consistente
```

### 6. Commit & PR

```bash
git add .
git commit -m "feat(area): descrição curta"
git push origin feat/nome-da-feature
```

Mensagens seguem [Conventional Commits](https://www.conventionalcommits.org/).

---

## Padrões de código

### Imports ordenados

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// 2. Packages externos (alfabético)
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart';  // Cripto
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 3. Imports relativos do projecto (alfabético)
import '../models/account_model.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_transfer_service.dart';
```

### Naming Conventions

| Tipo | Padrão | Exemplo |
|---|---|---|
| Ficheiros | `snake_case.dart` | `supabase_transfer_service.dart` |
| Classes | `UpperCamelCase` | `SupabaseTransferService`, `AccountModel` |
| Variáveis/Métodos | `lowerCamelCase` | `executeTransfer()`, `accountBalance` |
| Constantes | `lowerCamelCase` | `maxTransferAmount`, `defaultTimeout` |
| Privados | Prefixo `_` | `_handleError()`, `_account` |
| Getters privados | `_<name>` | `_supabaseClient`, `_hkdfKey` |
| Booleanos | `is<Adjective>` ou `has<Noun>` | `isLoading`, `hasError`, `canTransfer` |

### Widgets e UI

```dart
// ✅ BOM: StatelessWidget por padrão
class TransferScreen extends StatelessWidget {
  const TransferScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferência')),
      body: Consumer<TransferProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(context, provider);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransferProvider provider) {
    // ...
  }
}

// ✅ BOM: Extrair widgets complexos
class _TransferForm extends StatefulWidget {
  const _TransferForm({required this.onSubmit});
  final VoidCallback onSubmit;

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

// ❌ MALO: Muita lógica inline
class TransferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(...),
          TextField(...),
          ElevatedButton(onPressed: () { ... })
        ],
      ),
    );
  }
}
```

### Cripto e PQC

```dart
// ✅ Sempre usar tipos específicos para dados criptográficos
import 'dart:typed_data';

class PqcHandshakeService {
  // Nonce de 32 bytes
  Uint8List _generateNonce() {
    final random = Random.secure();
    return Uint8List(32).map((_) => random.nextInt(256)).toList() as Uint8List;
  }

  // HKDF com info explícito
  Uint8List _deriveKey(Uint8List sharedSecret, String info) {
    final hkdf = HKDF(sha256);
    return hkdf.process(sharedSecret, 44, Uint8List(0), utf8.encode(info));
  }

  // AAD (Additional Authenticated Data) sempre incluído
  Future<Uint8List> _encryptPayload(
    Uint8List plaintext,
    Uint8List aesKey,
    String aad,  // sessionId ou context
  ) async {
    final iv = _deriveIv(aesKey);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(aesKey), 128, iv, utf8.encode(aad)));
    return cipher.process(plaintext);
  }
}
```

---

## Segurança

### Princípios não-negociáveis

1. **PQC standardizada**
   - ✅ ML-KEM-768 para key encapsulation (FIPS 203)
   - ✅ ML-DSA-65 para assinatura digital (FIPS 204)
   - ❌ Nunca usar primitivas PQC não-standardizadas
   - ❌ Não combinar PQC com clássico (hybrid) sem justificação forte

2. **Cripto simétrica**
   - ✅ AES-256-GCM com IV unique por mensagem
   - ✅ AAD obrigatório (sessionId + timestamp)
   - ✅ HKDF-SHA-256 com info string explícito
   - ❌ Nunca reusar IV

3. **Gestão de chaves**
   - ✅ Chave pública ML-DSA do servidor → TOFU pinning (SharedPreferences)
   - ✅ Chave privada servidor → gerada no Edge Function, nunca exponha
   - ✅ Session key derivada → HKDF com info contextual
   - ❌ Nunca hardcode secret keys no código

4. **Row Level Security (RLS)**
   ```sql
   -- ✅ Todos os SELECT precisam de auth.uid()
   ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "users_select_own_accounts"
     ON accounts FOR SELECT
     USING (user_id = auth.uid());

   -- ✅ Operações sensíveis apenas via service_role
   CREATE POLICY "service_write_only"
     ON transactions FOR INSERT
     WITH CHECK (false);  -- nunca INSERT directo
   ```

5. **Edge Functions**
   - ✅ `verify_jwt: true` por padrão
   - ✅ Validar input (tipo, tamanho, formato)
   - ✅ Logging explícito (sem secrets)
   - ❌ Nunca confiar em headers do cliente
   - ❌ Nunca logar tokens ou chaves privadas

6. **Client-side**
   - ✅ Validação local antes de chamar API
   - ✅ Trata JWT como opaco (não decode)
   - ✅ Limpar sensitive data em logout
   - ❌ Nunca store plaintext passwords
   - ❌ Nunca exponha Supabase URL pública

### Y2Q (Harvest Now, Decrypt Later)

A aplicação assume adversário que:
- Colecta traffic criptado hoje
- Espera por quantum computing para descriptografar amanhã

**Mitigação**:
- PQC ML-DSA-65 + ML-KEM-768 resiste a quantum
- Assinatura persistida em `transactions` (auditoria futura)
- Rekey não necessária (não há long-term shared secrets)

### Reportar Vulnerabilidades

⚠️ **Não abrir issues públicos para segurança!**

Contactar directamente: `vagneripg@gmail.com`
- Assunto: `[SECURITY] Descrição breve`
- Corpo: descrição, steps para reproduzir, possível mitigação
- Máximo 90 dias para disclosure responsável

### Checklist de segurança para PRs

- [ ] Nenhuma chave privada em git (`.env` no `.gitignore`)
- [ ] Nenhum `print()` ou `console.log()` com dados sensíveis
- [ ] Todas as RPC SQL com `SECURITY DEFINER` têm RLS
- [ ] Edge Functions com `verify_jwt: true`
- [ ] Validação local em todos os inputs
- [ ] Crypto sempre com `dart:typed_data` e tipos explícitos
- [ ] Nenhuma reutilização de IV
- [ ] TOFU pinning testado

---

## Documentação

### Ficheiros obrigatórios a atualizar

| Ficheiro | Quando | O quê |
|---|---|---|
| `README.md` | Setup, stack, ou features públicas | Sumário, arquitectura, funcionalidades |
| `docs/ARCHITECTURE.md` | Mudança em camadas ou padrões | Diagramas, fluxos, decisões técnicas |
| `docs/DEPLOYMENT.md` | Configuração Supabase ou secrets | Passos setup, variáveis ambiente, troubleshooting |
| `docs/adr/ADR-NNN-*.md` | **Decisão significativa** | Problema, alternativas, decisão, consequências |
| `CHANGELOG.md` | Cada PR mergeado | Entrada resumida em secção apropriada |

### Architectural Decision Records (ADRs)

Para decisões significativas (PQC, state management, segurança, etc.), criar um ADR:

```markdown
# ADR-004 — Exemplo de Decisão

## Contexto
Por que precisamos tomar uma decisão?

## Alternativas consideradas
1. Opção A: pros e contras
2. Opção B: pros e contras
3. Opção C: pros e contras

## Decisão
Escolhemos **Opção B** porque...

## Consequências
- Positiva: ...
- Negativa: ...

## Referências
- Link para issue/discussão
- Documentação relevante
```

**ADRs actuais**:
- `ADR-001-PQC-IMPLEMENTATION.md` — ML-DSA/ML-KEM server-side, simetria client-side
- `ADR-002-STATE-MANAGEMENT.md` — Provider + Realtime
- `ADR-003-SECURITY-STRATEGY.md` — RLS, TOFU, Y2Q

### Comentários no código

```dart
/// Documentação pública (dartdoc).
/// Visível em `flutter pub doc`.
///
/// Exemplo:
/// ```dart
/// final service = SupabaseTransferService();
/// final tx = await service.execute(transfer);
/// ```
class SupabaseTransferService {
  /// Executa pipeline PQC end-to-end.
  ///
  /// Throws [PqcException] se handshake ou assinatura falhar.
  /// Throws [NetworkException] em erro de rede.
  Future<TransactionModel> execute(TransferModel transfer) async {
    // ...
  }
}
```

```sql
-- SQL: explicar intenção, não óbvio
-- Trigger: cria perfil + conta + IBAN automaticamente no signup
CREATE TRIGGER handle_new_user
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

```typescript
/**
 * Executa handshake PQC com cliente Flutter.
 * @param req - POST body com { nonce: string (base64) }
 * @returns { shared_secret, server_dsa_pub, session_id, signature }
 */
export async function handler(req: Request): Promise<Response> {
  // ...
}
```

---

## Checklist para PR

Antes de submeter um PR, verificar:

- [ ] Branch criada de `main` com nome `feat/`, `fix/`, `docs/`, etc.
- [ ] Commits seguem Conventional Commits
- [ ] Código passa `flutter analyze` (sem warnings)
- [ ] Código formatado com `dart format lib/`
- [ ] Testes criados (mínimo para services)
- [ ] Cobertura mantém 70%+ em services
- [ ] Documentação actualizada (README, ARCHITECTURE, ADR se necessário)
- [ ] CHANGELOG.md actualizado
- [ ] Nenhum `print()` ou `debugPrint()` em código production
- [ ] Segurança checklist concluído (ver acima)
- [ ] PR description clara (problema, solução, testes)

## Contacto

| Aspecto | Contacto |
|---|---|
| **Autor** | Vagner Bom Jesus — vagneripg@gmail.com |
| **Segurança** | vagneripg@gmail.com (com `[SECURITY]` em assunto) |
| **GitHub Issues** | [VagnerBomJesus/BJBank/issues](https://github.com/VagnerBomJesus/BJBank/issues) |
| **Orientador académico** | Prof. Doutor Rui A. P. Perdigão |
| **Instituição** | Instituto Politécnico da Guarda |
| **Supabase Project** | `jdybjrpmybkmmfdlwrzp.supabase.co` |

## Licença

Este projecto é académico. Uso comercial requer autorização explícita.

© 2026 Vagner Bom Jesus · Instituto Politécnico da Guarda · Todos os direitos reservados.

---

**Obrigado por contribuir para a investigação em banca móvel pós-quântica.** 🚀
