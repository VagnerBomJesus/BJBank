# BJBank - System Architecture

**Date**: 18/04/2026
**Version**: 1.0
**Document Type**: Technical Architecture Guide

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Layered Architecture](#2-layered-architecture)
3. [Component Diagram](#3-component-diagram)
4. [Data Flow](#4-data-flow)
5. [Provider Architecture](#5-provider-architecture)
6. [Service Layer](#6-service-layer)
7. [Data Model](#7-data-model)
8. [Deployment Architecture](#8-deployment-architecture)
9. [Integration Patterns](#9-integration-patterns)
10. [Performance Considerations](#10-performance-considerations)

---

## 1. System Overview

### 1.1 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    User Device (Android/iOS)                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │             UI Layer (Material Design 3)                  │ │
│  │  • Screens (33+)                                           │ │
│  │  • Widgets (9+ custom)                                     │ │
│  │  • Badges (13 transaction types)                           │ │
│  └────────────────────┬───────────────────────────────────────┘ │
│                       │                                          │
│  ┌────────────────────▼───────────────────────────────────────┐ │
│  │          State Management (Provider Pattern)              │ │
│  │  • 12 Specialized Providers                               │ │
│  │  • ChangeNotifier architecture                            │ │
│  │  • Real-time listeners                                    │ │
│  └────────────────────┬───────────────────────────────────────┘ │
│                       │                                          │
│  ┌────────────────────▼───────────────────────────────────────┐ │
│  │           Services Layer (Business Logic)                 │ │
│  │  • 20 Services (auth, db, payments, etc.)                 │ │
│  │  • Firebase integration                                   │ │
│  │  • PQC cryptographic operations                           │ │
│  └────────────────────┬───────────────────────────────────────┘ │
│                       │                                          │
│  ┌────────────────────▼───────────────────────────────────────┐ │
│  │            Local Storage & Cache                          │ │
│  │  • Encrypted secure storage                               │ │
│  │  • SharedPreferences for settings                         │ │
│  │  • Firestore offline persistence                          │ │
│  └────────────────────┬───────────────────────────────────────┘ │
│                       │                                          │
│  ┌────────────────────▼───────────────────────────────────────┐ │
│  │         Security & Cryptography Layer                     │ │
│  │  • PQC (Kyber + ECDH)                                      │ │
│  │  • HMAC-SHA256                                             │ │
│  │  • libOQS native library                                   │ │
│  └────────────────────┬───────────────────────────────────────┘ │
│                       │                                          │
└───────────────────────┼──────────────────────────────────────────┘
                        │ HTTPS/TLS 1.3 + Certificate Pinning
                        ▼
        ┌───────────────────────────────────────────┐
        │      Firebase Backend (Google Cloud)      │
        ├───────────────────────────────────────────┤
        │  • Cloud Firestore (Real-time DB)         │
        │  • Authentication                          │
        │  • Cloud Messaging (FCM)                  │
        │  • Cloud Storage                          │
        │  • Cloud Functions (serverless)           │
        └───────────────────────────────────────────┘
```

### 1.2 Architecture Principles

- **Separation of Concerns**: UI, State Management, Services, Data clearly separated
- **Dependency Injection**: Services injected into providers for testability
- **Real-time Synchronization**: Firestore listeners for live updates
- **Offline-First**: Local persistence with sync when online
- **Security by Default**: Encryption at all layers
- **Type Safety**: Full null-safety with Dart static analysis

---

## 2. Layered Architecture

### 2.1 UI Layer

**Responsibility**: Present data to user, capture input, trigger actions

**Key Components**:
- **33+ Screens**: Organized by feature (auth, accounts, transactions, cards, etc.)
- **9+ Custom Widgets**: Reusable components (badges, cards, lists)
- **Material Design 3**: Modern, accessible, responsive design
- **Theming**: Dark/light theme support

**Examples**:
```
Screens/
├── auth/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   └── profile_screen.dart
├── accounts/
│   ├── accounts_screen.dart
│   └── account_detail_screen.dart
├── transactions/
│   ├── transactions_screen.dart
│   └── transaction_detail_screen.dart
└── ... (30+ more screens)
```

**Constraints**:
- ❌ No business logic in screens
- ❌ No direct Firebase calls
- ❌ No API calls
- ✅ Only UI logic and Consumer widgets

### 2.2 State Management Layer

**Responsibility**: Manage application state, notify listeners of changes

**Architecture**:
- **12 Providers**: One per domain (auth, accounts, cards, etc.)
- **ChangeNotifier**: Base class for all providers
- **Consumer & ProxyProvider**: UI subscription mechanism
- **StreamSubscription**: Real-time listeners for Firestore

**Provider Hierarchy**:
```
AuthProvider (root)
  ├─ AccountProvider (depends on auth)
  ├─ CardProvider (depends on auth)
  ├─ TransferProvider (depends on auth)
  ├─ BillProvider (depends on auth)
  ├─ LoanProvider (depends on auth)
  ├─ InvestmentProvider (depends on auth)
  ├─ SavingsGoalProvider (depends on auth)
  ├─ BudgetProvider (depends on auth)
  ├─ MbWayProvider (depends on auth)
  ├─ NotificationProvider (depends on auth)
  └─ SettingsProvider (independent)
```

**Template**:
```dart
class DomainProvider extends ChangeNotifier {
  final DomainService _service;

  // State
  List<Model> _items = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  // Initialization
  Future<void> initialize(String userId) async {
    _startListening(userId);
  }

  // Methods
  Future<void> fetchItems() async {
    _isLoading = true;
    try {
      _items = await _service.getItems();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### 2.3 Services Layer

**Responsibility**: Business logic, external integrations, data operations

**20 Services**:
```
Services/
├── Auth
│   └── auth_service.dart
├── Database
│   └── firestore_service.dart
├── Messaging
│   └── fcm_service.dart
├── Storage
│   └── cloud_storage_service.dart
├── Security
│   ├── pqc_service.dart
│   └── crypto_service.dart
├── Financial
│   ├── transfer_service.dart
│   ├── bill_service.dart
│   ├── loan_service.dart
│   └── investment_service.dart
├── Integration
│   ├── mb_way_service.dart
│   └── qr_code_service.dart
└── ... (more services)
```

**Service Interface Pattern**:
```dart
abstract class DomainService {
  Future<List<Model>> getItems();
  Future<Model> getItemById(String id);
  Future<Model> createItem(Model item);
  Future<void> updateItem(Model item);
  Future<void> deleteItem(String id);
  Stream<List<Model>> streamItems();
}

class DomainServiceImpl implements DomainService {
  final FirestoreService _firestore;

  @override
  Future<List<Model>> getItems() async {
    // Implementation
  }
}
```

**Dependency Injection**:
```dart
// Services are injected into providers
class DomainProvider extends ChangeNotifier {
  final DomainService _service; // Injected

  DomainProvider({DomainService? service})
    : _service = service ?? DomainServiceImpl();
}

// Easy to mock in tests
test('DomainProvider works correctly', () {
  final mockService = MockDomainService();
  final provider = DomainProvider(service: mockService);
  // Test
});
```

### 2.4 Data Layer

**Responsibility**: Persist and retrieve data

**Components**:
- **Firestore**: Cloud database for persistent data
- **Secure Storage**: Encrypted local storage for secrets
- **SharedPreferences**: User settings and preferences
- **SQLite (Optional)**: For complex queries and offline sync

**Models** (14 total):
```
Models/
├── user_model.dart
├── account_model.dart
├── transaction_model.dart
├── card_model.dart
├── transfer_model.dart
├── bill_model.dart
├── loan_model.dart
├── investment_model.dart
└── ... (6 more models)
```

**Model Pattern**:
```dart
class TransactionModel {
  final String id;
  final String accountId;
  final double amount;
  final String type;
  final DateTime timestamp;
  final String description;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.timestamp,
    required this.description,
  });

  // Serialization
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      accountId: data['accountId'],
      amount: data['amount'],
      type: data['type'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'amount': amount,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
    };
  }
}
```

### 2.5 Security Layer

**Responsibility**: Cryptographic operations, encryption, authentication

**Components**:
- **PQC Service**: Kyber + ECDH key exchange
- **Crypto Service**: HMAC, signatures, encryption
- **Auth Service**: Firebase authentication, session management
- **Secure Storage**: Encrypted credential storage

---

## 3. Component Diagram

### 3.1 Major Components

```
┌─────────────────────────────────────────────────────────────┐
│                    BJBank App                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Auth      │  │ Accounts    │  │ Cards       │        │
│  │ Screen      │  │ Screen      │  │ Screen      │        │
│  │             │  │             │  │             │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                 │                 │              │
│         └─────────────────┼─────────────────┘              │
│                           │                                │
│                ┌──────────▼──────────┐                     │
│                │  Provider Layer     │                     │
│                │  (12 providers)     │                     │
│                └──────────┬──────────┘                     │
│                           │                                │
│         ┌─────────────────┼─────────────────┐             │
│         │                 │                 │             │
│    ┌────▼────┐    ┌──────▼──────┐   ┌─────▼────┐         │
│    │Auth     │    │Account      │   │Card      │         │
│    │Service  │    │Service      │   │Service   │         │
│    │         │    │             │   │          │         │
│    └────┬────┘    └──────┬──────┘   └─────┬────┘         │
│         │                 │                 │             │
│         └─────────────────┼─────────────────┘             │
│                           │                                │
│                ┌──────────▼──────────┐                     │
│                │  Firestore Service  │                     │
│                │  (Database Access)  │                     │
│                └──────────┬──────────┘                     │
│                           │                                │
│                ┌──────────▼──────────┐                     │
│                │ Firebase Backend    │                     │
│                │ (Cloud Services)    │                     │
│                └─────────────────────┘                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Cross-Cutting Concerns

```
┌──────────────────────────────────────────────────────┐
│        Logging & Analytics (Cross-cutting)           │
│  • Debug logging in development                      │
│  • Analytics events in production                    │
│  • Error tracking (Sentry/Firebase Crashlytics)      │
└──────────────────────────────────────────────────────┘
          ▲
          │
┌─────────┴──────────────────────────────────────────┐
│      Security & Cryptography (Cross-cutting)       │
│  • Applied to all network requests                 │
│  • Applied to sensitive data storage               │
│  • Applied to inter-module communication           │
└─────────┬──────────────────────────────────────────┘
          │
┌─────────▼──────────────────────────────────────────┐
│      Error Handling (Cross-cutting)                │
│  • Try-catch in services                           │
│  • User-friendly error messages                    │
│  • Logging of errors                               │
└──────────────────────────────────────────────────────┘
```

---

## 4. Data Flow

### 4.1 User Authentication Flow

```
User enters credentials
           │
           ▼
┌─────────────────────────┐
│  Login Screen           │
│  (TextFields + Button)  │
└─────────────┬───────────┘
              │ onPressed()
              ▼
┌─────────────────────────┐
│  AuthProvider           │
│  .login(email, pwd)     │
└─────────────┬───────────┘
              │
              ▼
┌─────────────────────────┐
│  AuthService            │
│  .signInWithEmail()     │
└─────────────┬───────────┘
              │
              ▼
┌─────────────────────────┐
│  Firebase Auth          │
│  (Cloud Service)        │
└─────────────┬───────────┘
              │ idToken, refreshToken
              ▼
┌─────────────────────────┐
│  Secure Storage         │
│  (Save tokens)          │
└─────────────┬───────────┘
              │
              ▼
┌─────────────────────────┐
│  AuthProvider           │
│  .notifyListeners()     │
└─────────────┬───────────┘
              │
              ▼
┌─────────────────────────┐
│  Dashboard Screen       │
│  (Rebuilds with auth)   │
└─────────────────────────┘
```

### 4.2 Real-time Transaction Update Flow

```
New transaction in Firestore
           │
           ▼
┌──────────────────────────────┐
│  Firestore Listener          │
│  (in AccountProvider)        │
└──────────┬───────────────────┘
           │ Stream event
           ▼
┌──────────────────────────────┐
│  AccountProvider             │
│  ._startListening()          │
│  (updates _accounts list)    │
└──────────┬───────────────────┘
           │ notifyListeners()
           ▼
┌──────────────────────────────┐
│  Consumer<AccountProvider>   │
│  (rebuilds UI)               │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────────┐
│  Transactions Screen         │
│  (shows updated data)        │
└──────────────────────────────┘
```

### 4.3 Transfer Operation Flow

```
User initiates transfer
           │
           ▼
┌────────────────────────────────┐
│  Transfer Screen               │
│  (enter recipient, amount)     │
└──────────┬─────────────────────┘
           │ onConfirm()
           ▼
┌────────────────────────────────┐
│  TransferProvider              │
│  .createTransfer(transfer)     │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────┐
│  TransferService               │
│  .createTransfer()             │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────┐
│  FirestoreService              │
│  .createTransaction()          │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────┐
│  Firebase Firestore            │
│  (write to database)           │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────┐
│  Firestore Trigger             │
│  (Cloud Function)              │
│  • Debit sender account        │
│  • Credit recipient account    │
│  • Update balances             │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────┐
│  Firestore Listeners           │
│  (both accounts)               │
│  (AccountProvider)             │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────┐
│  Dashboard refreshes           │
│  (shows new balances)          │
└────────────────────────────────┘
```

---

## 5. Provider Architecture

### 5.1 Provider Dependency Graph

```
                    SettingsProvider
                          │
                    AuthProvider (root)
                          │
                ┌─────────┼─────────┬─────────┬───────────┐
                │         │         │         │           │
           AccountProvider CardProvider TransferProvider BillProvider
                │         │         │         │           │
           ┌────┴────┐    │         │         │     ┌─────┴─────┐
           │          │    │         │         │     │           │
      LoanProvider InvestmentProvider │         │ MbWayProvider │
                │         │         │         │     │           │
           SavingsGoalProvider BudgetProvider │     NotificationProvider
                                        │
                                 QrCodeProvider
```

### 5.2 Provider Initialization Sequence

```
App Launch
    │
    ▼
MultiProvider setup in main.dart
    │
    ├─ AuthProvider created
    │  └─ AuthProvider.initialize()
    │     ├─ Verify saved session
    │     ├─ Load user data
    │     └─ notify listeners
    │
    ├─ SettingsProvider created
    │  └─ Load user preferences
    │
    ├─ ProxyProvider (AccountProvider)
    │  ├─ Watches AuthProvider
    │  └─ Calls AccountProvider.initialize(userId)
    │
    ├─ ProxyProvider (CardProvider)
    │  ├─ Watches AuthProvider
    │  └─ Calls CardProvider.initialize(userId)
    │
    ├─ ... (other providers initialized via proxy)
    │
    └─ Firestore Real-time Listeners start
       ├─ Account balance stream
       ├─ Transaction stream
       ├─ Card stream
       └─ ... (all domain streams)
```

---

## 6. Service Layer

### 6.1 Service Classification

**Authentication & User**:
- AuthService (Firebase Auth)
- ProfileService (User data)

**Database & Storage**:
- FirestoreService (Real-time DB)
- CloudStorageService (File storage)
- SecureStorageService (Encrypted secrets)

**Messaging & Notifications**:
- FCMService (Firebase Cloud Messaging)
- NotificationService (Local notifications)

**Financial Operations**:
- TransferService (Money transfers)
- BillService (Bill management)
- LoanService (Loan management)
- InvestmentService (Portfolio)
- SavingsGoalService (Goals)
- BudgetService (Budgets)

**Payment Integration**:
- MbWayService (MB WAY payments)
- QrCodeService (QR code generation/scanning)

**Security & Cryptography**:
- PqcService (Post-quantum cryptography)
- CryptoService (HMAC, AES, etc.)

### 6.2 Service Communication Pattern

```dart
// Service interface
abstract class DomainService {
  Future<Model> get(String id);
  Future<List<Model>> list();
  Stream<Model> watch(String id);
}

// Implementation
class DomainServiceImpl implements DomainService {
  final FirestoreService _firestore;
  final Logger _logger;

  @override
  Future<Model> get(String id) async {
    try {
      final doc = await _firestore.getDocument('collection', id);
      return Model.fromFirestore(doc);
    } catch (e) {
      _logger.error('Failed to get model', e);
      rethrow;
    }
  }

  @override
  Stream<Model> watch(String id) {
    return _firestore
        .watchDocument('collection', id)
        .map((doc) => Model.fromFirestore(doc));
  }
}

// Provider using service
class DomainProvider extends ChangeNotifier {
  final DomainService _service;

  Model? _model;
  StreamSubscription? _subscription;

  Future<void> load(String id) async {
    _model = await _service.get(id);
    _subscribe(id);
    notifyListeners();
  }

  void _subscribe(String id) {
    _subscription = _service.watch(id).listen(
      (model) {
        _model = model;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

## 7. Data Model

### 7.1 Entity Relationship Diagram

```
┌──────────┐
│   User   │
│          │
│ • id     │
│ • email  │
│ • name   │
│ • pin    │
└────┬─────┘
     │ 1:N
     ▼
┌──────────────┐
│   Account    │
│              │
│ • id         │
│ • type       │
│ • balance    │
│ • currency   │
└────┬─────────┘
     │ 1:N
     ├──────────────────────┬──────────────┐
     │                      │              │
     ▼                      ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Transaction  │  │   Transfer   │  │     Bill     │
│              │  │              │  │              │
│ • id         │  │ • id         │  │ • id         │
│ • amount     │  │ • amount     │  │ • amount     │
│ • type       │  │ • recipient  │  │ • dueDate    │
│ • timestamp  │  │ • scheduled  │  │ • status     │
└──────────────┘  └──────────────┘  └──────────────┘

┌──────────────┐
│     Card     │
│              │
│ • id         │
│ • type       │
│ • number     │
│ • limit      │
└────┬─────────┘
     │ 1:N
     ▼
┌──────────────┐
│  CardLock    │
│              │
│ • type       │
│ • enabled    │
└──────────────┘
```

### 7.2 Model Relationships

**User → Account (1:N)**
- One user has multiple accounts
- Accounts linked by userId

**Account → Transaction (1:N)**
- One account has many transactions
- Transaction references accountId

**Account → Card (1:N)**
- One account can have multiple cards
- Card references accountId

**Account → Loan (1:N)**
- One account has multiple loans
- Loan references accountId

**Account → Investment (1:N)**
- One account has multiple investments

**User → Settings (1:1)**
- One user has one settings document
- Settings document referenced by userId

---

## 8. Deployment Architecture

### 8.1 Build Configuration

```
Development
    ├─ debug APK (Android)
    ├─ debug IPA (iOS)
    └─ debug web

Production
    ├─ release APK (Android)
    ├─ release IPA (iOS)
    └─ release web

Release Management
    ├─ Google Play Store
    ├─ Apple App Store
    └─ GitHub Releases
```

### 8.2 Firebase Configuration

**Android** (android/app/google-services.json):
```json
{
  "project_id": "bjbank-firebase-project",
  "api_key": "...",
  "app_id": "...",
  "database_url": "https://bjbank.firebaseio.com",
  "cloud_messaging_sender_id": "..."
}
```

**iOS** (ios/Runner/GoogleService-Info.plist):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>PROJECT_ID</key>
  <string>bjbank-firebase-project</string>
  ...
</dict>
</plist>
```

### 8.3 Environment-Specific Configuration

```dart
// lib/config/environment.dart
class Environment {
  static const String appName = 'BJBank';

  static const String firebaseProjectId = 'bjbank-firebase-project';
  static const String firebaseStorageBucket = 'bjbank.appspot.com';

  static const bool isProduction = bool.fromEnvironment('PRODUCTION');
  static const bool isDevelopment = !isProduction;

  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: isDevelopment ? 'debug' : 'warning',
  );
}
```

---

## 9. Integration Patterns

### 9.1 Firebase Integration

**Real-time Synchronization**:
```dart
// Provider listens to Firestore stream
void _startListening(String userId) {
  _subscription = _firestore
      .collection('users')
      .doc(userId)
      .collection('accounts')
      .snapshots()
      .listen(
    (snapshot) {
      _accounts = snapshot.docs
          .map((doc) => AccountModel.fromFirestore(doc))
          .toList();
      notifyListeners();
    },
    onError: (error) {
      _error = error.toString();
      notifyListeners();
    },
  );
}
```

**Offline Persistence**:
```dart
// Firestore automatically caches data
Future<void> setupFirestore() async {
  await FirebaseFirestore.instance.settings = FirestoreSettings(
    persistenceEnabled: true,
    cacheSizeBytes: FirestoreSettings.cacheSizeUnlimited,
  );
}
```

### 9.2 Push Notification Integration

**FCM Setup**:
```dart
// Initialize FCM in AuthProvider
Future<void> _initializeFcm() async {
  final token = await FirebaseMessaging.instance.getToken();
  await _firestore.updateUserToken(userId, token);

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    await _firestore.updateUserToken(userId, token);
  });
}

// Handle foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  _handleNotification(message);
});
```

### 9.3 PQC Integration

**Key Exchange**:
```dart
// Hybrid handshake in PqcService
Future<SharedSecret> performKeyExchange() async {
  // 1. Generate EC keys
  final ecKeyPair = _generateEcKeyPair();

  // 2. Generate Kyber keys
  final kyberKeyPair = await _generateKyberKeyPair();

  // 3. Send public keys to server
  final encapsulation = await _sendPublicKeys(
    ecKeyPair.publicKey,
    kyberKeyPair.publicKey,
  );

  // 4. Derive shared secret
  final sharedSecret = _deriveSharedSecret(
    ecKeyPair.privateKey,
    kyberKeyPair.privateKey,
    encapsulation,
  );

  return sharedSecret;
}
```

---

## 10. Performance Considerations

### 10.1 Optimization Techniques

**Provider Optimization**:
```dart
// Use Selector to optimize rebuilds
Selector<DomainProvider, String>(
  selector: (context, provider) => provider.name,
  builder: (context, name, child) {
    return Text(name); // Only rebuilds if name changes
  },
)
```

**Firestore Query Optimization**:
```dart
// Indexed queries for performance
Query query = _firestore
    .collection('transactions')
    .where('accountId', isEqualTo: accountId)
    .where('timestamp', isGreaterThan: startDate)
    .orderBy('timestamp', descending: true)
    .limit(50);
```

**Image Loading Optimization**:
```dart
// Cached image with placeholder
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => const LoadingWidget(),
  cacheManager: customCacheManager,
  memCacheHeight: 300,
  memCacheWidth: 300,
)
```

### 10.2 Performance Metrics

**Target Metrics**:
- App startup: < 3 seconds
- Screen navigation: < 500ms
- List scrolling: 60 FPS
- Firestore query: < 1 second
- PQC operation: < 100ms (mobile)

---

## References

- [Flutter Architecture](https://flutter.dev/docs/development/architecture)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Firebase Best Practices](https://firebase.google.com/docs/best-practices)
- [Dart Design Patterns](https://dart.dev/guides)

---

**Version**: 1.0
**Last Updated**: 18/04/2026
**Status**: Complete
