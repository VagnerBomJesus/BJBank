# BJBank - TODO: O Que Falta Implementar

**Data:** 17/04/2026
**Status do Projeto:** 65% completo (9/14 requisitos principais)

---

## 📊 Status Geral

| Fase | Requisitos | Status | Progresso |
|------|-----------|--------|-----------|
| **Phase 1** | RF01-RF05 | ✅ Completo | 100% |
| **Phase 2** | RF06-RF08 | ✅ Completo | 100% |
| **Phase 3** | RF09-RF10 | ✅ Completo | 100% |
| **Phase 4** | RF11-RF14 | 🔧 Parcial | 30-50% |
| **Badges** | 10 tipos | ✅ Completo | 100% |
| **Testes** | Widget/Unit | ❌ Não iniciado | 0% |

---

## 🎯 PRIORIDADE 1: Concluir Fase 4 (Requisitos Originais)

### RF11: Gestão de Cartões Avançada

**Status:** 70% implementado (UI done, backend falta)

**O que já existe:**
- ✅ CardProvider com ChangeNotifier
- ✅ CardSettingsDialog UI
- ✅ Integração com home screen
- ✅ Models básicos

**O que falta:**

```dart
1. lib/models/card_model.dart (EXTEND)
   ├── Enum CardType { physical, virtual }
   ├── Enum CardStatus { active, blocked, expired, cancelled }
   ├── Properties:
   │   ├── cardNumber (encrypted)
   │   ├── cardHolder
   │   ├── expiryDate
   │   ├── cvv (encrypted)
   │   ├── cardLimit
   │   ├── spentAmount
   │   ├── type (physical/virtual)
   │   └── status
   ├── Methods:
   │   ├── formatCardNumber() → "****1234"
   │   ├── isExpired()
   │   ├── availableBalance()
   │   └── maskSensitiveData()
   └── Estimativa: 150 linhas

2. lib/services/card_service.dart (CREATE)
   ├── createCard(CardModel) → Firestore
   ├── blockCard(cardId)
   ├── unblockCard(cardId)
   ├── updateCardLimit(cardId, newLimit)
   ├── getCardStatistics()
   ├── deleteCard(cardId)
   ├── streamCards() → Real-time updates
   └── Estimativa: 250 linhas

3. lib/providers/card_provider.dart (EXTEND)
   ├── Integrar CardService
   ├── Real-time card list updates
   ├── Error handling
   ├── Loading states
   └── Estimativa: 100 linhas

4. Firestore Collections
   ├── /users/{userId}/cards/{cardId}
   │   ├── cardNumber (encrypted)
   │   ├── cardHolder
   │   ├── expiryDate
   │   ├── cvv (encrypted)
   │   ├── limit
   │   ├── type
   │   ├── status
   │   ├── createdAt
   │   └── updatedAt
   └── Security Rules: Read/write only own cards
```

**Estimativa:** 3-4 dias
**Prioridade:** 🔴 CRÍTICA

---

### RF12: Notificações Push Firebase (FCM)

**Status:** 50% implementado (service criado, triggers faltam)

**O que já existe:**
- ✅ NotificationService com FCM initialization
- ✅ Topic subscription logic
- ✅ Message handling básico
- ✅ NotificationBadge UI widget

**O que falta:**

```dart
1. lib/services/notification_service.dart (EXTEND)
   ├── setupTransactionTriggers()
   │   └── Listen Firestore transactions + enviar push
   ├── setupSecurityAlerts()
   │   └── PQC signature verification alerts
   ├── setupBillReminders()
   │   └── Daily/weekly bill reminders
   ├── setupLoanPaymentReminders()
   │   └── Loan payment due dates
   ├── handleNotificationTap(message) → Deep linking
   └── Estimativa: 200 linhas

2. lib/screens/settings/notification_preferences_screen.dart (CREATE)
   ├── ToggleButton por tipo:
   │   ├── Transactions
   │   ├── Security
   │   ├── Bills
   │   ├── Goals
   │   └── Marketing
   ├── Horários silenciosos (quiet hours)
   ├── Sons e vibrações customizadas
   ├── Salvar preferências em SharedPreferences
   └── Estimativa: 280 linhas

3. lib/models/notification_preference.dart (CREATE)
   ├── type (transaction, security, bill, goal, marketing)
   ├── enabled
   ├── notificationSound
   ├── vibrationEnabled
   ├── quietHoursStart
   ├── quietHoursEnd
   └── Estimativa: 100 linhas

4. Firestore Cloud Functions (Backend - Node.js)
   ├── onTransactionCreated trigger
   │   └── Send notification to receiver
   ├── onBillDueReminder scheduled function
   │   └── Daily check for upcoming bills
   ├── onSecurityAlert trigger
   │   └── Failed login attempts, etc.
   ├── onLoanPaymentDue trigger
   │   └── Payment reminders
   └── Estimativa: 400 linhas TypeScript

5. Deep Linking Configuration
   ├── android:deepLinks in AndroidManifest.xml
   ├── Associated Domains em iOS
   ├── Route handling no app
   └── Estimativa: 100 linhas
```

**Estimativa:** 5-6 dias
**Prioridade:** 🔴 CRÍTICA

---

### RF13: Pagamentos por QR Code

**Status:** 0% implementado

**O que falta:**

```dart
1. lib/services/qr_code_service.dart (CREATE)
   ├── generateQRForTransfer(TransferData)
   │   └── Create QR code with encrypted transfer data
   ├── parseQRData(qrString) → TransferData
   │   └── Extract and validate QR data
   ├── validateQRFormat()
   ├── encryptQRData(data)
   └── Estimativa: 200 linhas

2. lib/screens/qr/qr_scanner_screen.dart (CREATE)
   ├── Camera preview (mobile_camera or camera package)
   ├── QR detection in real-time
   ├── Haptic feedback on successful scan
   ├── Flash toggle
   ├── Galeria para selecionar QR code
   ├── Error handling
   └── Estimativa: 350 linhas

3. lib/screens/qr/qr_payment_confirmation_screen.dart (CREATE)
   ├── Show parsed QR data:
   │   ├── Recipient name
   │   ├── Amount
   │   ├── Reference
   │   └── Payment date
   ├── Confirm/Cancel buttons
   ├── Edit amount before confirming
   ├── Show transaction preview
   └── Estimativa: 250 linhas

4. lib/screens/qr/qr_code_generator_screen.dart (CREATE)
   ├── Generate QR for own IBAN
   ├── Include amount (optional)
   ├── Include reference (optional)
   ├── Display generated QR
   ├── Share QR code
   ├── Save QR as image
   └── Estimativa: 250 linhas

5. Dependencies
   ├── qr: ^3.0.0 (QR code generation)
   ├── qr_flutter: ^4.0.0 (QR display)
   ├── mobile_scanner: ^3.0.0 (QR scanning)
   └── Update pubspec.yaml
```

**Estimativa:** 6-7 dias
**Prioridade:** 🟠 IMPORTANTE

---

### RF14: Integração com API Bancária Externa

**Status:** 0% implementado

**O que falta:**

```dart
1. lib/services/external_bank_service.dart (CREATE)
   ├── Connect to banking API (Stripe/Plaid)
   ├── verifyAccount()
   ├── linkBankAccount()
   ├── unlinkBankAccount()
   ├── getExternalTransactions()
   ├── Error handling (API failures)
   └── Estimativa: 300 linhas

2. lib/models/external_account_model.dart (CREATE)
   ├── bankName
   ├── accountNumber (masked)
   ├── accountType
   ├── verificationStatus
   ├── linkedDate
   └── Estimativa: 80 linhas

3. lib/screens/settings/linked_accounts_screen.dart (CREATE)
   ├── List linked bank accounts
   ├── Link new account flow
   ├── Unlink account
   ├── Account verification status
   └── Estimativa: 250 linhas

4. Backend Integration (Requires API Key)
   ├── Stripe Connect setup
   ├── Plaid API integration
   ├── Bank account verification
   ├── Transaction sync
   └── Estimativa: 500 linhas (backend)

5. Security
   ├── Encrypt bank credentials
   ├── PQC signatures for API calls
   ├── Rate limiting
   ├── Audit logging
   └── GDPR compliance
```

**Estimativa:** 7-10 dias (+ backend setup)
**Prioridade:** 🟡 RECOMENDADO
**Nota:** Requer integração com serviços terceiros

---

## 🎯 PRIORIDADE 2: Badge System - Fase 4

### ProgressBadge (Não Iniciado)

**Status:** 0% implementado

**O que falta:**

```dart
1. lib/widgets/badges/progress_badge.dart (CREATE)

   Variants:
   a) CircularProgressBadge
      ├── Circular progress indicator
      ├── Percentage display
      ├── Custom colors
      ├── Size options
      └── Animação de preenchimento

   b) LinearProgressBadge
      ├── Linear progress bar
      ├── Percentage label
      ├── Custom height
      ├── Animated fill
      └── Milestone markers

   c) SegmentedProgressBadge
      ├── Multi-step progress
      ├── Step indicators
      ├── Step labels
      └── Current step highlight

   Features:
   ├── Dark theme support
   ├── Tooltip com detalhes
   ├── Accessibility labels
   └── Animation de transição

   Estimativa: 350 linhas
```

**Uso em:**
- Savings Goals progress tracking
- Budget spending progress
- Loan amortization progress
- Investment portfolio progress

**Estimativa:** 2-3 dias
**Prioridade:** 🟡 RECOMENDADO

---

### TypeBadge (Não Iniciado)

**Status:** 0% implementado

**O que falta:**

```dart
1. lib/widgets/badges/type_badge.dart (CREATE)

   Enums:
   a) InvestmentType
      ├── stocks
      ├── bonds
      ├── etfs
      ├── crypto
      ├── mutual_funds
      └── commodities

   b) LoanType
      ├── personal
      ├── mortgage
      ├── auto
      ├── student
      └── business

   c) CardType
      ├── credit
      ├── debit
      ├── virtual
      └── prepaid

   d) SavingsType
      ├── emergency_fund
      ├── vacation
      ├── education
      ├── home
      └── retirement

   Variants:
   a) TypeBadge
      ├── Icon + label
      ├── Compact/full
      └── Color per type

   b) TypeIndicator
      ├── Dot + label
      ├── Minimal footprint
      └── Semantic colors

   c) TypeChip
      ├── Selectable type
      ├── Filter support
      └── Visual feedback

   Features:
   ├── Portuguese labels
   ├── Dark theme support
   ├── Accessibility labels
   ├── Category-specific icons
   └── Color system per type

   Estimativa: 400 linhas
```

**Uso em:**
- Investment listings
- Loan management
- Card selection
- Savings goals categorization

**Estimativa:** 3-4 dias
**Prioridade:** 🟡 RECOMENDADO

---

## 🎯 PRIORIDADE 3: Integração dos Badges nos Ecrãs

### Screens a Atualizar

```dart
1. lib/screens/home/home_screen.dart
   ├── Add SecurityBadge to app bar
   ├── Add QuantumSafeBadge to transaction items
   ├── Add EncryptedTransactionBadge to list
   └── Estimativa: 1 dia

2. lib/screens/bills/bills_screen.dart
   ├── Add StatusBadge to bill items
   ├── Add CategoryBadge (compact) to categories
   ├── Add CounterBadge for overdue count
   └── Estimativa: 1.5 dias

3. lib/screens/transactions/transactions_history_screen.dart
   ├── Add StatusBadge per transaction
   ├── Add CategoryBadgeIndicator
   ├── Add EncryptedBadge for secure transactions
   └── Estimativa: 1.5 dias

4. lib/screens/loans/loans_screen.dart
   ├── Add PriorityBadge for payment urgency
   ├── Add StatusBadge for loan status
   ├── Add CategoryBadge for loan type
   └── Estimativa: 1.5 dias

5. lib/screens/goals/savings_goals_screen.dart
   ├── Add PriorityBadge for goal importance
   ├── Add ProgressBadge for goal progress
   ├── Add PriorityIndicator (star-based)
   └── Estimativa: 1.5 dias

6. lib/screens/investments/investments_screen.dart
   ├── Add TypeBadge for investment types
   ├── Add ProgressBadge for portfolio progress
   ├── Add PriorityBadge for alerts
   └── Estimativa: 1.5 dias

7. lib/screens/cards/cards_screen.dart
   ├── Add TypeBadge for card types
   ├── Add StatusBadge for card status
   ├── Add CategoryBadge for card category
   └── Estimativa: 1 dia

8. lib/screens/notifications/notifications_screen.dart
   ├── Add NotificationBadge per notification
   ├── Add StatusBadge for read/unread
   ├── Add CategoryBadge for notification type
   └── Estimativa: 1 dia
```

**Total Estimativa:** 10 dias
**Prioridade:** 🟠 IMPORTANTE (depois de completar badges)

---

## 🧪 PRIORIDADE 4: Testes

### Widget Tests (Não Iniciado)

```dart
1. test/widgets/badges/
   ├── notification_badge_test.dart
   ├── counter_badge_test.dart
   ├── status_badge_test.dart
   ├── category_badge_test.dart
   ├── priority_badge_test.dart
   ├── progress_badge_test.dart (after implementation)
   ├── type_badge_test.dart (after implementation)
   └── Estimativa: 1,000 linhas

2. test/widgets/pqc/
   ├── quantum_safe_badge_test.dart
   ├── security_badge_test.dart
   └── Estimativa: 300 linhas

3. test/screens/
   ├── home_screen_test.dart (with badges)
   ├── bills_screen_test.dart (with badges)
   ├── ... (other screens)
   └── Estimativa: 2,000 linhas

4. test/services/
   ├── card_service_test.dart
   ├── notification_service_test.dart
   ├── qr_code_service_test.dart
   └── Estimativa: 1,000 linhas

5. test/models/
   ├── card_model_test.dart
   └── Estimativa: 300 linhas
```

**Total Estimativa:** 4,600+ linhas
**Estimativa de Tempo:** 10-14 dias
**Prioridade:** 🟡 RECOMENDADO (depois de implementação)

---

## 📋 Resumo de Prazos

### Curto Prazo (Próximas 2 semanas)

| Tarefa | Dias | Prioridade |
|--------|------|-----------|
| RF11: Card Management Backend | 3-4 | 🔴 CRÍTICA |
| RF12: Push Notifications | 5-6 | 🔴 CRÍTICA |
| RF13: QR Code Payments | 6-7 | 🟠 IMPORTANTE |
| Badge Integration (Preview) | 3-4 | 🟠 IMPORTANTE |

**Total:** 17-21 dias

---

### Médio Prazo (2-4 semanas)

| Tarefa | Dias | Prioridade |
|--------|------|-----------|
| RF14: External Bank API | 7-10 | 🟡 RECOMENDADO |
| ProgressBadge | 2-3 | 🟡 RECOMENDADO |
| TypeBadge | 3-4 | 🟡 RECOMENDADO |
| Badge Screen Integration (Complete) | 10 | 🟠 IMPORTANTE |

**Total:** 22-27 dias

---

### Longo Prazo (1-2 meses)

| Tarefa | Dias | Prioridade |
|--------|------|-----------|
| Widget Tests | 10-14 | 🟡 RECOMENDADO |
| Performance Optimization | 5-7 | 🟡 RECOMENDADO |
| Security Hardening | 3-5 | 🟡 RECOMENDADO |
| Documentation | 3-5 | 💙 NICE TO HAVE |

**Total:** 21-31 dias

---

## 🎯 Recomendação de Próximos Passos

### Sessão Próxima: **RF11 + RF12 (Card Management + Push Notifications)**

**Por quê:**
1. ✅ Completam os requisitos originais críticos
2. ✅ RF11 é 70% pronto (só falta backend)
3. ✅ RF12 é essencial para user engagement
4. ✅ Estimativa razoável (8-10 dias)

**Sequência Recomendada:**
```
Dia 1-2:  Card Model + Service
Dia 3-4:  Card Provider + Firestore integration
Dia 5-6:  Notification Service extensions
Dia 7-8:  Notification Preferences Screen
Dia 9-10: Cloud Functions + testing
```

---

## 📊 Completude Esperada após próximas fases

```
Antes (Agora):
├── ✅ RF01-RF05: 100%
├── ✅ RF06-RF08: 100%
├── ✅ RF09-RF10: 100%
├── 🔧 RF11-RF14: 30%
└── ✅ Badge System: 100%

Depois (RF11-RF12):
├── ✅ RF01-RF12: 100%
├── 🔧 RF13-RF14: 10%
└── ✅ Badge System: 100%
= **Total: 85% Completo**

Final (Tudo):
├── ✅ RF01-RF14: 100%
├── ✅ Badge System: 100%
├── ✅ Tests: 100%
└── ✅ Documentation: 100%
= **Total: 100% Completo**
```

---

**Última Atualização:** 17/04/2026
**Próxima Revisão:** Após implementação de RF11

