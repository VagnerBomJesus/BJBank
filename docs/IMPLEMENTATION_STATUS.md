# BJBank - Estado de Implementação

## Visão Geral do Projeto

| Métrica | Valor |
|---------|-------|
| **Total de Ficheiros Dart** | 71 |
| **Ecrãs Implementados** | 35 |
| **Modelos de Dados** | 6 |
| **Serviços** | 9 |
| **Providers** | 3 |
| **ADRs** | 3 |
| **Progresso Geral** | ~80% |

---

## 1. FUNCIONALIDADES IMPLEMENTADAS ✅

### 1.1 Autenticação e Segurança

| Funcionalidade | Ficheiro | Estado | Notas |
|----------------|----------|--------|-------|
| Registo de utilizador | `auth_service.dart` | ✅ 100% | Email, password, nome, telefone |
| Login com email/password | `auth_service.dart` | ✅ 100% | Firebase Auth |
| Logout | `auth_service.dart` | ✅ 100% | Limpa sessão e storage |
| Recuperação de password | `forgot_password_screen.dart` | ✅ 100% | Email de reset |
| Verificação de email | `auth_service.dart` | ✅ 100% | Reenvio disponível |
| PIN de 6 dígitos | `secure_storage_service.dart` | ✅ 100% | SHA-256 + salt + 10k iterações |
| Autenticação biométrica | `secure_storage_service.dart` | ✅ 100% | Face ID, Touch ID, Fingerprint |
| Gestão de sessão | `secure_storage_service.dart` | ✅ 100% | Tokens seguros |
| Eliminação de conta | `auth_service.dart` | ✅ 100% | Cascade delete completo |

### 1.2 Operações Bancárias

| Funcionalidade | Ficheiro | Estado | Notas |
|----------------|----------|--------|-------|
| Visualizar saldo | `home_screen.dart` | ✅ 100% | Toggle visibilidade |
| Visualizar IBAN | `home_screen.dart` | ✅ 100% | Copiar para clipboard |
| Transferência por IBAN | `transfer_screen.dart` | ✅ 100% | Validação PT50 |
| Transferência MB WAY | `mbway_screen.dart` | ✅ 100% | Por número de telefone |
| Confirmação de transferência | `transfer_confirmation_screen.dart` | ✅ 100% | Resumo + PIN |
| Recibo de transferência | `transfer_receipt_screen.dart` | ✅ 100% | Partilhável |
| Histórico de transações | `history_screen.dart` | ✅ 100% | Filtros por tipo |
| Detalhes de transação | `home_screen.dart` | ✅ 100% | Bottom sheet |
| Análise financeira | `analysis_screen.dart` | ✅ 100% | Gráficos mensais |

### 1.3 Criptografia Pós-Quântica (PQC)

| Funcionalidade | Ficheiro | Estado | Notas |
|----------------|----------|--------|-------|
| Geração de par de chaves | `pqc_service.dart` | ✅ 100% | Dilithium 2/3/5 + Kyber 512/768/1024 |
| Assinatura de transações | `pqc_service.dart` | ✅ 100% | signTransfer() |
| Verificação de assinaturas | `pqc_service.dart` | ✅ 100% | verifySignature() |
| Armazenamento seguro de chaves | `pqc_service.dart` | ✅ 100% | Flutter Secure Storage |
| Informações do algoritmo | `pqc_service.dart` | ✅ 100% | Nível NIST, bits |
| Badge de segurança PQC | `quantum_safe_badge.dart` | ✅ 100% | UI indicator |
| **Handshake Híbrido** | `pqc_service.dart` | ⏳ 70% | TLS ECDHE + Kyber768 KEM (simulado) |
| **Benchmark PQC** | `pqc_benchmark_service.dart` | ⏳ 80% | 18 operações, N=10 iterações |
| **Ecrã Benchmark** | `pqc_benchmark_screen.dart` | ⏳ 80% | Tabela + barras + handshake + export |
| **Modelo de Métricas** | `pqc_metrics_model.dart` | ✅ 100% | JSON + Markdown |
| **ADR-001** | `docs/adr/ADR-001-*.md` | ✅ 100% | Classificação PoC Arquitetural |
| **ADR-002** | `docs/adr/ADR-002-*.md` | ✅ 100% | Design handshake híbrido |
| **ADR-003** | `docs/adr/ADR-003-*.md` | ✅ 100% | Metodologia benchmarking |
| **Testes PQC** | `test/pqc_test.dart` | ✅ 100% | 40 testes unitários (100% pass) |

**Nota:** A implementação atual é um **Simulador de Interface PQC = PoC Arquitetural** (ver ADR-001).
Para produção, integrar liboqs via FFI (interface pública de `PqcService` mantém zero breaking changes).

### 1.4 Gestão de Perfil e Configurações

| Funcionalidade | Ficheiro | Estado | Notas |
|----------------|----------|--------|-------|
| Visualizar perfil | `profile_screen.dart` | ✅ 100% | Nome, email, telefone |
| Editar perfil | `profile_screen.dart` | ✅ 100% | Atualiza Firestore |
| Foto de perfil | `profile_screen.dart` | ✅ 100% | Câmara/Galeria |
| Alterar PIN | `settings_screen.dart` | ✅ 100% | Verificação do antigo |
| Ativar/desativar biometria | `settings_screen.dart` | ✅ 100% | Toggle |
| Dados da conta bancária | `account_details_screen.dart` | ✅ 100% | IBAN, número conta |
| Vincular MB WAY | `account_details_screen.dart` | ✅ 100% | Por telefone |
| Privacidade e dados | `privacy_screen.dart` | ✅ 100% | RGPD info |
| Ajuda e FAQ | `help_screen.dart` | ✅ 100% | Accordion |
| Sobre a app | `about_screen.dart` | ✅ 100% | Versão, links |

### 1.5 Interface do Utilizador

| Funcionalidade | Ficheiro | Estado | Notas |
|----------------|----------|--------|-------|
| Splash screen animado | `splash_screen.dart` | ✅ 100% | Logo + loading |
| Onboarding (4 slides) | `onboarding_screen.dart` | ✅ 100% | Carrossel |
| Design system completo | `theme/*.dart` | ✅ 100% | Cores, tipografia, espaçamento |
| Tema claro | `app_theme.dart` | ✅ 100% | Material 3 |
| Tema escuro | `app_theme.dart` | ✅ 100% | Material 3 |
| Bottom navigation | `home_screen.dart` | ✅ 100% | 4 tabs + FAB |
| Pull-to-refresh | `home_screen.dart` | ✅ 100% | Atualiza dados |
| Feedback háptico | Vários | ✅ 100% | Toque, erro |
| Animações suaves | Vários | ✅ 100% | Transições |
| Strings em português | `app_strings.dart` | ✅ 100% | 100% localizado |

### 1.6 Base de Dados e Backend

| Funcionalidade | Ficheiro | Estado | Notas |
|----------------|----------|--------|-------|
| Configuração Firebase | `firebase_options.dart` | ✅ 100% | Core + Auth + Firestore |
| Coleção users | `firestore_service.dart` | ✅ 100% | CRUD completo |
| Coleção accounts | `firestore_service.dart` | ✅ 100% | CRUD completo |
| Coleção transactions | `firestore_service.dart` | ✅ 100% | CRUD completo |
| Streams em tempo real | `firestore_service.dart` | ✅ 100% | User, account, tx |
| Transações atómicas | `firestore_service.dart` | ✅ 100% | createTransfer() |
| Dados de seed | `seed_data_service.dart` | ✅ 100% | 10 utilizadores demo |

---

## 2. FUNCIONALIDADES PARCIALMENTE IMPLEMENTADAS ⏳

### 2.1 Gestão de Cartões

| Funcionalidade | Ficheiro | Estado | O que falta |
|----------------|----------|--------|-------------|
| Lista de cartões | `cards_screen.dart` | 60% | Dados mock, sem backend |
| Bloquear/desbloquear | `cards_screen.dart` | 30% | UI apenas, sem lógica |
| Detalhes do cartão | `cards_screen.dart` | 50% | Bottom sheet básico |
| Limites de gastos | - | 0% | Não iniciado |
| Cartão virtual | - | 0% | Não iniciado |

### 2.2 Notificações

| Funcionalidade | Ficheiro | Estado | O que falta |
|----------------|----------|--------|-------------|
| Lista de notificações | `inbox_screen.dart` | ✅ 85% | 3 tabs: Atividade (tx), Segurança (PQC status), Sistema |
| Badge de notificação | `home_screen.dart` | 50% | Ícone presente, sem contagem real |
| Push notifications | - | 0% | Firebase Cloud Messaging |
| Notificações de transação | - | 0% | Triggers Firestore |

### 2.3 Documentos

| Funcionalidade | Ficheiro | Estado | O que falta |
|----------------|----------|--------|-------------|
| Lista de documentos | `documents_screen.dart` | ✅ 100% | Transações por mês, filtro ano/mês, badge PQC, exportar extrato |
| Download PDF | - | 0% | Geração de extratos PDF |
| Comprovativo de transferência | - | 0% | PDF export |

---

## 3. FUNCIONALIDADES PENDENTES 📋

### 3.1 Alta Prioridade

| Funcionalidade | Estimativa | Dependências |
|----------------|------------|--------------|
| Integração liboqs (PQC real) | 2 sprints | FFI, compilação nativa |
| Notificações push | 1 sprint | FCM, backend triggers |
| Testes automatizados (>70% coverage) | 2 sprints | flutter_test, mockito |
| Certificate pinning | 3 dias | dio, certificados |
| Rate limiting | 3 dias | Backend rules |

### 3.2 Média Prioridade

| Funcionalidade | Estimativa | Dependências |
|----------------|------------|--------------|
| Pagamentos QR Code | 1 sprint | qr_code_scanner |
| Modo offline | 2 sprints | Hive/SQLite, sync |
| Exportação dados (RGPD) | 1 sprint | PDF/JSON generation |
| Multi-idioma (EN, ES) | 1 sprint | flutter_localizations |
| Cartões virtuais | 2 sprints | Backend, integração |

### 3.3 Baixa Prioridade

| Funcionalidade | Estimativa | Dependências |
|----------------|------------|--------------|
| Widgets (iOS/Android) | 1 sprint | home_widget |
| Apple Pay / Google Pay | 2 sprints | APIs nativas |
| Open Banking (PSD2) | 3 sprints | APIs bancárias |
| Investimentos | 4 sprints | Novo módulo |
| Chat com suporte | 2 sprints | WebSocket, backend |

---

## 4. ALGORITMOS E FÓRMULAS IMPLEMENTADAS

### 4.1 Hash de PIN

```dart
// Localização: lib/services/secure_storage_service.dart
// Algoritmo: PBKDF2-like com SHA-256

HashPIN(pin, salt, iterations=10000):
  combined = pin + ":" + salt
  hash = SHA256(combined)
  for i in 1..9999:
    hash = SHA256(hash)
  return Base64(hash)

// Complexidade: O(iterations) = O(10000) ≈ O(1)
// Tempo médio: ~100ms
```

### 4.2 Assinatura Digital PQC (Simulada)

```dart
// Localização: lib/services/pqc_service.dart
// Algoritmo: CRYSTALS-Dilithium (simulado com HMAC)

SignTransaction(data, privateKey):
  dataHash = SHA256(data)
  hmac = HMAC-SHA256(dataHash, privateKey)
  return {
    signature: Base64(hmac),
    data: data,
    algorithm: "dilithium3",
    timestamp: now()
  }

// Em produção: substituir por liboqs Dilithium
```

### 4.3 Geração de IBAN Português

```dart
// Localização: lib/models/account_model.dart

GeneratePortugueseIban(bankCode, accountNumber):
  countryCode = "PT"
  checkDigits = 50  // Simplificado
  iban = countryCode + checkDigits + bankCode + accountNumber
  return formatIban(iban)  // PT50 XXXX XXXX XXXX XXXX XXXX X
```

### 4.4 Cálculo de Resumo Financeiro

```dart
// Localização: lib/providers/account_provider.dart

CalculateFinancialSummary(transactions, period):
  income = sum(tx.amount for tx in transactions if tx.type == income)
  expenses = sum(|tx.amount| for tx in transactions if tx.type in [expense, transfer])
  netFlow = income - expenses

  return {
    totalIncome: income,
    totalExpenses: expenses,
    netFlow: netFlow,
    transactionCount: len(transactions)
  }
```

### 4.5 Formatação de Moeda (EUR)

```dart
// Localização: lib/models/account_model.dart

FormatCurrency(amount, locale="pt_PT"):
  // 1234.56 → "1 234,56 €"
  return NumberFormat.currency(
    locale: locale,
    symbol: "€",
    decimalDigits: 2
  ).format(amount)
```

---

## 5. MÉTRICAS DE CÓDIGO

### 5.1 Distribuição por Camada

| Camada | Ficheiros | Linhas (aprox.) | % do Total |
|--------|-----------|-----------------|------------|
| Screens (UI) | 35 | ~8,600 | 45% |
| Services | 9 | ~3,200 | 16% |
| Models | 6 | ~1,100 | 6% |
| Providers | 3 | ~600 | 3% |
| Theme | 8 | ~1,500 | 8% |
| Routes | 3 | ~310 | 2% |
| Widgets | 2 | ~400 | 2% |
| Config/Main | 3 | ~200 | 1% |
| **Total** | **71** | **~15,700** | **100%** |

### 5.2 Complexidade

| Ficheiro | Complexidade | Razão |
|----------|--------------|-------|
| `firestore_service.dart` | Alta | Transações atómicas, múltiplas coleções |
| `pqc_service.dart` | Alta | Criptografia, gestão de chaves |
| `home_screen.dart` | Média-Alta | UI complexa, múltiplos providers |
| `auth_service.dart` | Média | Firebase Auth, error handling |
| `secure_storage_service.dart` | Média | Biometria, PIN hashing |

---

## 6. MELHORIAS TÉCNICAS RECOMENDADAS

### 6.1 Segurança

1. **Integrar liboqs para PQC real**
   ```bash
   # Compilar liboqs para Android/iOS
   # Usar dart:ffi para bindings
   ```

2. **Adicionar certificate pinning**
   ```dart
   // dio interceptor com SHA-256 pin
   dio.interceptors.add(CertificatePinningInterceptor());
   ```

3. **Implementar root/jailbreak detection**
   ```dart
   // flutter_jailbreak_detection package
   if (await JailbreakDetection.isJailbroken) {
     // Bloquear ou alertar
   }
   ```

### 6.2 Performance

1. **Lazy loading de transações**
   ```dart
   // Paginação com Firestore
   .startAfterDocument(lastDoc)
   .limit(20)
   ```

2. **Cache de imagens de perfil**
   ```dart
   // cached_network_image package
   CachedNetworkImage(imageUrl: photoUrl)
   ```

3. **Reduzir rebuilds com Selector**
   ```dart
   // Em vez de context.watch
   context.select((AuthProvider p) => p.user?.name)
   ```

### 6.3 Arquitetura

1. **Migrar para Clean Architecture**
   ```
   lib/
   ├── core/           # Shared utilities
   ├── features/       # Feature modules
   │   ├── auth/
   │   │   ├── data/
   │   │   ├── domain/
   │   │   └── presentation/
   │   ├── transfer/
   │   └── ...
   └── injection.dart  # DI container
   ```

2. **Usar Riverpod para state management**
   ```dart
   // Type-safe, testable, auto-dispose
   final userProvider = StreamProvider((ref) => authRepo.userStream);
   ```

---

## 7. ROADMAP

```
2026 Q1 ✅ MVP CONCLUÍDO
├── Autenticação completa
├── Transferências IBAN/MB WAY
├── PQC simulado (PoC Arquitetural)
├── UI/UX polida
└── Sprint 2026 Q1 ✅ CONCLUÍDO (2026-02-18):
    ├── ADR-001: Classificação científica PoC Arquitetural
    ├── ADR-002: Design handshake híbrido TLS + Kyber768
    ├── ADR-003: Metodologia benchmarking PQC
    ├── PqcMetrics + PqcHybridHandshake + PqcHybridHandshakeResult
    ├── PqcBenchmarkService (18 operações, N=10, mediana+P95)
    ├── PqcBenchmarkScreen (benchmark + export JSON/Markdown)
    └── Dados NIST/SUPERCOP completos (RSA/ECDSA/ECDH vs Dilithium/Kyber)

2026 Q2 🔄 EM PROGRESSO
├── Integração liboqs (FFI real — ver ADR-001 roadmap)
├── Testes automatizados
├── Push notifications
└── Certificate pinning

2026 Q3 📋 PLANEADO
├── QR Code payments
├── Modo offline
├── Multi-idioma
└── Exportação RGPD

2026 Q4 📋 PLANEADO
├── Cartões virtuais
├── Open Banking APIs
├── Apple/Google Pay
└── Lançamento produção
```

---

**Documento atualizado em:** 05/02/2026
**Versão:** 1.0
