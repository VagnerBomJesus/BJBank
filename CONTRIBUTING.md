# Contributing to BJBank

**BJBank** é um projecto académico de investigação focado em Criptografia Pós-Quântica aplicada a banca móvel. Este documento descreve as convenções e fluxo de trabalho para contribuir.

---

## Contexto académico

Dissertação de Mestrado em Cibersegurança · Instituto Politécnico da Guarda · 2026.

**Apropriado para**: investigação académica, fins educativos, *bug reports*, *security disclosures*, extensões de pesquisa.

**Não apropriado para**: sistemas bancários em produção, uso comercial, aplicações concorrentes.

---

## Stack técnica

| Camada | Tecnologia |
|---|---|
| Cliente | Flutter 3.8.1 + Dart 3.8.1 |
| Gestão de estado | provider 6.1+ |
| Cripto cliente | pointycastle 3.9 (HKDF, AES-256-GCM) |
| Backend | Supabase (Auth, PostgreSQL 15, Realtime, Edge Functions) |
| Cripto servidor | `@noble/post-quantum 0.4` (ML-KEM-768, ML-DSA-65) |
| Runtime Edge | Deno 2.1 / V8 11.6 |

A aplicação corre exclusivamente em Flutter (multi-plataforma) — não há cliente nativo Android/iOS separado.

---

## Setup inicial

```bash
# 1. Clonar
git clone https://github.com/VagnerBomJesus/BJBank.git
cd bjbank

# 2. Instalar dependências
flutter pub get

# 3. Configurar Supabase (URL + anon key)
# Editar lib/services/supabase_config.dart ou usar --dart-define
# Ver docs/DEPLOYMENT.md para detalhes completos

# 4. Correr a aplicação
flutter run
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

- `SupabaseAuthService` — autenticação (signIn, signUp, signOut, sendPasswordReset)
- `SupabaseAccountService` — accounts + transactions com Realtime
- `SupabaseMbwayService` — lookup phone → IBAN
- `SupabaseTransferService` — orquestra pipeline PQC end-to-end
- `SupabasePqcHandshakeService` — handshake + HKDF
- `TrustedServerKeyService` — TOFU pinning da chave ML-DSA do servidor
- `PqcBenchmarkService` / `ServerPqcBenchmarkService` — benchmarks PQC

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

### 2. Implementar

Para uma nova funcionalidade, segue tipicamente esta ordem:

1. **Modelo** em `lib/models/` (imutável, com `copyWith` e `fromJson`/`toJson`)
2. **Service** em `lib/services/` (singleton, comunica com Supabase)
3. **Provider** em `lib/providers/` (ChangeNotifier, chama o service)
4. **Screen** em `lib/screens/<feature>/` (UI reactiva consumindo o provider)
5. **Routes** em `lib/routes/app_routes.dart` (adicionar entrada)

### 3. Padrões obrigatórios

- **Modelos imutáveis** (`final` em todos os campos)
- **Singleton com factory** em todos os services
- **`ChangeNotifierProxyProvider`** quando o provider depende de outro
- **Validação local** antes de chamar service
- **Tratamento de erro** em todos os pontos de I/O

### 4. Testes

```bash
flutter test                     # corre toda a suite
flutter test test/services/      # só services
flutter test --coverage          # com cobertura
```

Meta de cobertura: 70% sobre a camada de services.

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

// 2. Packages externos
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 3. Imports relativos do projecto
import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';
```

### Naming

- **Ficheiros**: `snake_case.dart`
- **Classes**: `UpperCamelCase`
- **Variáveis/métodos**: `lowerCamelCase`
- **Constantes**: `lowerCamelCase`
- **Privados**: prefixo `_`

### Widgets

- `StatelessWidget` por defeito
- `StatefulWidget` apenas quando há estado local não-partilhado
- `const` em construtores sempre que possível

---

## Segurança

Princípios não-negociáveis:

1. **Todas as primitivas PQC** seguem FIPS 203 (ML-KEM) ou FIPS 204 (ML-DSA)
2. **AES-256-GCM** para envelope, com AAD obrigatório (sessionId)
3. **HKDF-SHA-256** para derivação de chaves
4. **TOFU pinning** da chave pública ML-DSA do servidor
5. **Row Level Security** activado em todas as tabelas Postgres
6. **Edge Functions** com `verify_jwt: true` excepto quando justificado
7. **service_role key** nunca exposta no cliente

Para reportar uma vulnerabilidade, contactar directamente: `vagneripg@gmail.com` com etiqueta `[SECURITY]` no assunto. Não abrir issues públicos para problemas de segurança.

---

## Documentação

Ao contribuir, manter actualizado:

- `README.md` se mudar setup ou stack
- `docs/ARCHITECTURE.md` se mudar camada ou padrão
- `docs/DEPLOYMENT.md` se mudar configuração Supabase
- `docs/adr/` se tomar decisão arquitectural significativa
- `CHANGELOG.md` em cada PR mergeado

Comentários no código:

- **Dart**: dartdoc (`///`) em métodos públicos e classes
- **SQL**: comentários `--` em migrations e RPCs explicando intenção
- **TypeScript** (Edge Functions): JSDoc nos exports

---

## Contacto

- **Autor**: Vagner Bom Jesus — vagneripg@gmail.com
- **GitHub**: [VagnerBomJesus/BJBank](https://github.com/VagnerBomJesus/BJBank)
- **Orientador**: Prof. Doutor Rui A. P. Perdigão
- **Instituição**: Instituto Politécnico da Guarda

---

**Obrigado por contribuir para a investigação em banca móvel pós-quântica.**
