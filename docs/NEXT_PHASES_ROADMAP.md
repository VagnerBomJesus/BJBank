# BJBank - Roadmap de Próximas Fases (Maio-Dezembro 2026)

## 📋 O QUE FALTA IMPLEMENTAR DO PLANO ORIGINAL

### Phase 5: Completar Funcionalidades do Plano Original ⚠️

#### 5.1 Gestão de Cartões Avançada (RF11) - 40% do caminho feito

**Status Atual:** 70% implementado
- ✅ NotificationService, CardProvider, CardSettingsDialog criados
- ✅ UI com Material Design 3
- ❌ Backend Firestore de cartões
- ❌ Cartões virtuais
- ❌ Integração com transações

**O que falta (1 sprint):**
```dart
// lib/models/card_model.dart (NEW)
├── Tipos: physical, virtual
├── Status: active, blocked, expired, cancelled
├── Propriedades: cardNumber, expiryDate, cvv, limit, spent
├── Métodos: formatCardNumber(), isExpired, availableBalance
└── 280+ linhas

// lib/services/card_service.dart (EXTEND)
├── createCard() → Firestore
├── blockCard(), unblockCard()
├── updateCardLimit()
├── getCardStatistics()
└── 200+ linhas

// lib/providers/card_provider.dart (EXTEND)
└── Integrar com Backend
```

**Estimativa:** 3-4 dias

---

#### 5.2 Notificações Push Firebase (RF12) - 50% do caminho feito

**Status Atual:** 50% implementado
- ✅ NotificationService implementado
- ✅ FCM initialization
- ✅ Topic subscription
- ❌ Triggers Firestore (transações em tempo real)
- ❌ Preferências de notificações
- ❌ Deep linking

**O que falta (1 sprint):**
```dart
// lib/services/notification_service.dart (EXTEND)
├── setupTransactionTriggers()
├── setupSecurityAlerts()
├── setupBillReminders()
├── handleNotificationTap() → Deep linking
└── 150+ linhas

// lib/screens/settings/notification_preferences_screen.dart (NEW)
├── Toggle por tipo
├── Horários silenciosos
├── Sons e vibrações personalizadas
└── 250+ linhas

// Firestore Cloud Functions (Backend)
├── onTransactionCreated() → notify user
├── onBillDue() → daily reminder
├── onSecurityAlert() → immediate notification
└── 150+ linhas
```

**Estimativa:** 4-5 dias

---

#### 5.3 Pagamentos por QR Code (RF13) - 0% implementado

**Status Atual:** Não iniciado
- ❌ Scanner QR Code
- ❌ Geração de QR codes
- ❌ Parsing de dados

**Implementação (1 sprint):**
```dart
// lib/services/qr_code_service.dart (NEW)
├── generateQRForTransfer(iban, amount, reference)
├── parseQRData(qrString) → transfer params
├── validateQRFormat()
└── 200+ linhas

// lib/screens/qr/qr_scanner_screen.dart (NEW)
├── Camera preview com scanner
├── Vibração ao escanear
├── Processamento de dados
├── Deep linking para transfer
└── 300+ linhas

// lib/screens/qr/qr_payment_confirmation_screen.dart (NEW)
├── Mostrar detalhes do QR lido
├── Confirmar transferência
├── PIN verification
└── 250+ linhas

// pubspec.yaml (UPDATE)
└── Add: qr_code_scanner: ^1.0.0
```

**Estimativa:** 4-5 dias

---

#### 5.4 Exportação de Dados RGPD (RF14) - 0% implementado

**Status Atual:** Não iniciado
- ❌ PDF generation
- ❌ JSON export
- ❌ Data deletion

**Implementação (1 sprint):**
```dart
// lib/services/export_service.dart (NEW)
├── exportTransactionsAsPDF()
├── exportAccountAsJSON()
├── exportFullDataAsZIP()
├── deleteAllUserData()
└── 300+ linhas

// lib/screens/settings/data_export_screen.dart (NEW)
├── Opções de export (PDF, JSON, ZIP)
├── Seleção de período
├── Download com status
├── Request data deletion
└── 300+ linhas

// pubspec.yaml (UPDATE)
└── Add: pdf: ^3.0.0, archive: ^3.0.0
```

**Estimativa:** 3-4 dias

---

### Phase 6: Melhorias de Segurança & Performance 🔒

#### 6.1 Integração liboqs (PQC Real) - HIGH PRIORITY

**Status:** Simulado com HMAC (PoC Arquitetural)

**Implementação (2-3 sprints):**
```
1. Setup FFI bindings
   ├── liboqs-c dependencies
   ├── Android NDK build
   ├── iOS framework compilation
   └── Window MSVC build

2. Dart FFI Wrapper
   └── lib/services/pqc_ffi_service.dart (500+ linhas)
      ├── KeyPair generation (real Dilithium)
      ├── Sign/Verify (real Dilithium)
      ├── Encapsulate/Decapsulate (Kyber)
      └── Memory management

3. Integration
   └── Manter interface pública de PqcService (ZERO breaking changes)
```

**Dependências:**
- liboqs (C library)
- Dart FFI package
- Android NDK
- iOS deployment target

**Estimativa:** 2-3 sprints

---

#### 6.2 Certificate Pinning

**Implementação (3-5 dias):**
```dart
// lib/services/http_service.dart (NEW)
├── SHA-256 pin definitions
├── CertificatePinningInterceptor
├── Public key + Subject public key info pinning
└── 150+ linhas

// pubspec.yaml (UPDATE)
└── Add: dio: ^5.0.0
```

---

#### 6.3 Rate Limiting

**Implementação (3-5 dias):**
```dart
// lib/services/rate_limit_service.dart (NEW)
├── Request counting
├── Cooldown management
├── Per-endpoint limits
└── 150+ linhas

// Backend (Firestore Rules + Cloud Functions)
└── Limit: 5 transfers/hour, 20/day
```

---

### Phase 7: Testes Automatizados 🧪

**Target:** >70% code coverage

**Implementação (2 sprints):**

```
test/
├── models/
│   ├── account_model_test.dart (100+ linhas)
│   ├── transaction_model_test.dart (100+ linhas)
│   ├── bill_model_test.dart (100+ linhas)
│   ├── investment_model_test.dart (100+ linhas)
│   ├── loan_model_test.dart (100+ linhas)
│   ├── savings_goal_model_test.dart (100+ linhas)
│   └── budget_model_test.dart (100+ linhas)
│
├── services/
│   ├── auth_service_test.dart (150+ linhas)
│   ├── firestore_service_test.dart (200+ linhas)
│   ├── bill_service_test.dart (150+ linhas)
│   ├── investment_service_test.dart (150+ linhas)
│   ├── loan_service_test.dart (150+ linhas)
│   ├── budget_service_test.dart (150+ linhas)
│   └── pqc_service_test.dart (150+ linhas)
│
├── providers/
│   ├── auth_provider_test.dart (150+ linhas)
│   ├── account_provider_test.dart (150+ linhas)
│   ├── bill_provider_test.dart (150+ linhas)
│   ├── investment_provider_test.dart (150+ linhas)
│   ├── loan_provider_test.dart (150+ linhas)
│   └── budget_provider_test.dart (150+ linhas)
│
└── widgets/
    ├── home_screen_test.dart (200+ linhas)
    ├── transfer_screen_test.dart (200+ linhas)
    └── settings_screen_test.dart (150+ linhas)

Total: ~3,000 linhas de testes
```

---

### Phase 8: Funcionalidades Secundárias 🎯

#### 8.1 Multi-idioma (EN, ES, FR)

**Estimativa:** 1 sprint
```dart
// lib/l10n/
├── app_en.arb
├── app_es.arb
├── app_fr.arb
└── app_pt.arb (existente)

// pubspec.yaml
└── Add: flutter_localizations, intl

// Main setup
└── localizationsDelegates + supportedLocales
```

---

#### 8.2 Modo Offline

**Estimativa:** 2 sprints
```dart
// lib/services/offline_service.dart (NEW)
├── Local cache com Hive
├── Sync queue management
├── Conflict resolution
└── 300+ linhas

// pubspec.yaml
└── Add: hive: ^2.0.0, hive_flutter: ^1.1.0

// Firebase
└── Enable offline persistence
```

---

#### 8.3 Apple Pay / Google Pay

**Estimativa:** 2 sprints
```dart
// lib/services/payment_service.dart (NEW)
├── initializeApplePay()
├── initializeGooglePay()
├── processPayment()
└── 250+ linhas

// pubspec.yaml
└── Add: pay: ^2.0.0

// Native setup
├── Android: Google Merchant account
└── iOS: Apple Pay merchant ID
```

---

#### 8.4 Open Banking (PSD2)

**Estimativa:** 3 sprints
```dart
// lib/services/open_banking_service.dart (NEW)
├── OAuth2 flow
├── Account linking
├── Transaction fetching
├── 400+ linhas

// Integration
├── Bank API (Portuguese banks)
└── PSD2 compliance
```

---

## 📊 Roadmap Gantt Chart

```
2026 Q2 (Apr-Jun)
├─ Phase 5: Complete RF11-RF14
│  ├─ RF11: Advanced Cards (1 sprint) ▓▓▓▓░
│  ├─ RF12: Push Notifications (1 sprint) ▓▓▓▓░
│  ├─ RF13: QR Code Payments (1 sprint) ▓▓▓▓░
│  └─ RF14: RGPD Export (1 sprint) ▓▓▓▓░
│
└─ Phase 6: Security Improvements
   ├─ liboqs Integration (3 sprints) ▓▓▓░░░░░░
   ├─ Certificate Pinning (0.5 sprint) ▓░
   └─ Rate Limiting (0.5 sprint) ▓░

2026 Q3 (Jul-Sep)
├─ Phase 7: Automated Testing
│  └─ Unit + Integration Tests (2 sprints) ▓▓▓▓░░░░░░
│
└─ Phase 8a: Secondary Features (1)
   ├─ Multi-language (1 sprint) ▓▓▓▓░
   └─ Offline Mode (2 sprints) ▓▓▓▓▓▓░░░░

2026 Q4 (Oct-Dec)
├─ Phase 8b: Secondary Features (2)
│  ├─ Apple Pay / Google Pay (2 sprints) ▓▓▓▓▓▓░░░░
│  └─ Open Banking APIs (3 sprints) ▓▓▓▓▓▓▓▓▓░
│
└─ Production Deployment
   ├─ Play Store Release
   └─ App Store Release
```

---

## 🎯 Prioridades

### Must Have (Bloqueadores)
1. ✅ **Fases 1-4:** Completadas (Bills, Investments, Loans, Savings, Budget)
2. ⚠️ **Fase 5:** RF11-RF14 (Cartões, Notificações, QR Code, RGPD) - 2 semanas
3. ⚠️ **Fase 6.1:** liboqs (PQC Real) - 3 sprints

### Should Have (Melhorias)
4. **Fase 6.2-6.3:** Certificate Pinning + Rate Limiting - 1 sprint
5. **Fase 7:** Testes Automatizados - 2 sprints

### Nice to Have (Features)
6. **Fase 8:** Multi-idioma, Offline, Apple/Google Pay, Open Banking - 6+ sprints

---

## 💡 Recomendação

### Próximos 2 Meses (Junho 2026)

1. **Semanas 1-2:** RF11 + RF12 (Cartões + Notificações)
2. **Semana 3:** RF13 + RF14 (QR Code + RGPD)
3. **Semanas 4-8:** liboqs Integration (PQC Real)

**Output:** Aplicação 100% funcional com todas as features do plano original + 8 novas features financeiras

### Depois (Julho-Dezembro 2026)

4. Certificate Pinning + Rate Limiting
5. Testes Automatizados (>70% coverage)
6. Multi-idioma + Offline Mode
7. Payment integrations (Apple/Google Pay)
8. Production deployment

---

**Documento:** NEXT_PHASES_ROADMAP.md
**Versão:** 1.0
**Data:** 17/04/2026
**Preparado por:** Vagner Bom Jesus
