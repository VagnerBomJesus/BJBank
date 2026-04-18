# Contributing to BJBank

**BJBank** is an academic research project focused on Post-Quantum Cryptography implementation in mobile banking applications. This document provides comprehensive guidelines for contributing.

---

## Table of Contents

- [Project Context](#project-context)
- [Getting Started](#getting-started)
- [Architecture Overview](#architecture-overview)
- [Use Case Diagrams](#use-case-diagrams)
- [Data Flow Diagrams](#data-flow-diagrams)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Contributing Checklist](#contributing-checklist)
- [Security Considerations](#security-considerations)
- [Testing Strategy](#testing-strategy)
- [Documentation](#documentation)
- [Git Workflow](#git-workflow)
- [Support & Communication](#support--communication)

---

## Project Context

### Academic Nature

This is a **Master's Dissertation** project developed at Instituto Politécnico da Guarda, not a traditional open-source project.

**Suitable for**:
- Academic research and experimentation
- Educational purposes and learning
- Bug reports and security disclosures
- Feature extensions for research

**NOT suitable for**:
- Production banking systems
- Commercial implementations
- Competing applications
- Non-educational use

### Project Goals

1. Implement complete banking system with 50+ features
2. Integrate post-quantum cryptography (Kyber + ECDH)
3. Demonstrate hybrid security approach
4. Evaluate PQC performance on mobile
5. Create production implementation guides

---

## Getting Started

### Prerequisites

```
- Flutter 3.8.1+
- Dart 3.8+
- Android SDK 30+ / Xcode 12+
- Firebase account (configured)
- git with SSH keys configured
- Basic knowledge of Flutter/Dart
- Understanding of cryptography concepts (for PQC work)
```

### Development Environment Setup

```bash
# 1. Clone repository
git clone https://github.com/VagnerBomJesus/BJBank.git
cd bjbank

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
flutterfire configure --platforms=android,ios

# 4. Verify setup
flutter analyze          # Should have 0 errors
flutter test --coverage  # Run all tests
flutter run             # Should build and run

# 5. Format code
dart format lib/ test/
```

### Verify Installation

```bash
# Check Flutter version
flutter --version      # Should be 3.8.1+

# Check Dart version
dart --version         # Should be 3.8+

# Check dependencies
flutter pub get --dry-run

# Run code analysis
flutter analyze        # Should show no errors

# Run sample test
flutter test test/unit/  # Should pass
```

---

## Architecture Overview

### System Architecture Diagram

```
┌──────────────────────────────────────────────────────┐
│                  Mobile Application                   │
├──────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────────────────────────────────┐    │
│  │         Layer 1: UI/Widgets (33+ screens)   │    │
│  │  ┌───────────────────────────────────────┐  │    │
│  │  │ Auth Screens                          │  │    │
│  │  │ Dashboard, Accounts, Cards            │  │    │
│  │  │ Transfers, Bills, Loans, Investments  │  │    │
│  │  │ Savings Goals, Budgets, Settings      │  │    │
│  │  └───────────────────────────────────────┘  │    │
│  │                     ↓                        │    │
│  ├─────────────────────────────────────────────┤    │
│  │  Layer 2: State (Provider - 12 providers)    │    │
│  │  ┌───────────────────────────────────────┐  │    │
│  │  │ AuthProvider (Root)                   │  │    │
│  │  │ ├─ AccountProvider                    │  │    │
│  │  │ ├─ CardProvider                       │  │    │
│  │  │ ├─ TransferProvider                   │  │    │
│  │  │ ├─ BillProvider                       │  │    │
│  │  │ ├─ LoanProvider                       │  │    │
│  │  │ ├─ InvestmentProvider                 │  │    │
│  │  │ ├─ SavingsGoalProvider                │  │    │
│  │  │ ├─ BudgetProvider                     │  │    │
│  │  │ ├─ NotificationProvider               │  │    │
│  │  │ └─ SettingsProvider                   │  │    │
│  │  └───────────────────────────────────────┘  │    │
│  │                     ↓                        │    │
│  ├─────────────────────────────────────────────┤    │
│  │  Layer 3: Services (20 services)             │    │
│  │  ┌───────────────────────────────────────┐  │    │
│  │  │ AuthService → FirebaseAuth             │  │    │
│  │  │ FirestoreService → Database Ops        │  │    │
│  │  │ PqcService → Cryptography              │  │    │
│  │  │ CryptoService → Encryption             │  │    │
│  │  │ MessageService → FCM Push              │  │    │
│  │  │ + 15 more domain services              │  │    │
│  │  └───────────────────────────────────────┘  │    │
│  │                     ↓                        │    │
│  ├─────────────────────────────────────────────┤    │
│  │  Layer 4: Data (Firebase + Secure Storage)   │    │
│  │  ┌───────────────────────────────────────┐  │    │
│  │  │ Cloud Firestore (Real-time DB)        │  │    │
│  │  │ Secure Storage (Encrypted secrets)    │  │    │
│  │  │ Cloud Storage (Files)                 │  │    │
│  │  │ SharedPreferences (Config)            │  │    │
│  │  └───────────────────────────────────────┘  │    │
│  │                     ↓                        │    │
│  ├─────────────────────────────────────────────┤    │
│  │  Layer 5: Security & Crypto                  │    │
│  │  ┌───────────────────────────────────────┐  │    │
│  │  │ Kyber KEM (ML-KEM-768)                │  │    │
│  │  │ ECDH (secp256r1)                      │  │    │
│  │  │ HMAC-SHA256                           │  │    │
│  │  │ AES-256-GCM                           │  │    │
│  │  │ TLS 1.3 + Certificate Pinning         │  │    │
│  │  └───────────────────────────────────────┘  │    │
│  │                     ↓                        │    │
│  ├─────────────────────────────────────────────┤    │
│  │  Layer 6: External Services                  │    │
│  │  ┌───────────────────────────────────────┐  │    │
│  │  │ Firebase Cloud Services                │  │    │
│  │  │ MB WAY API Integration                │  │    │
│  │  │ QR Code Services                      │  │    │
│  │  │ HTTPS/TLS Communication               │  │    │
│  │  └───────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────┘    │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### Key Classes Diagram

```
Class Hierarchy: Models → Providers → Services

Models (14 total):
  ├─ User
  ├─ Account
  ├─ Card
  ├─ Transaction
  ├─ Transfer
  ├─ Bill
  ├─ Loan
  ├─ Investment
  ├─ SavingsGoal
  ├─ Budget
  ├─ Notification
  ├─ MbWayPayment
  ├─ PortfolioAsset
  └─ SystemConfig

Services (20 total):
  ├─ AuthService → Firebase Auth
  ├─ FirestoreService → CRUD ops
  ├─ PqcService → Kyber + ECDH
  ├─ CryptoService → Encryption
  ├─ MessageService → FCM
  └─ Domain Services:
      ├─ AccountService
      ├─ CardService
      ├─ TransferService
      ├─ BillService
      ├─ LoanService
      ├─ InvestmentService
      ├─ SavingsGoalService
      ├─ BudgetService
      └─ ... (+ 11 more)

Providers (12 total):
  └─ AuthProvider (Root)
      ├─ AccountProvider
      ├─ CardProvider
      ├─ TransferProvider
      ├─ BillProvider
      ├─ LoanProvider
      ├─ InvestmentProvider
      ├─ SavingsGoalProvider
      ├─ BudgetProvider
      ├─ MbWayProvider
      ├─ NotificationProvider
      └─ SettingsProvider
```

---

## Use Case Diagrams

### Authentication Use Case

```
Actor: User

    ┌─────────────────────────┐
    │    Start Application    │
    └────────┬────────────────┘
             │
             ├─→ Check cached session
             │        │
             │        ├─ Valid? → Resume app
             │        └─ Expired? ↓
             │
    ┌────────▼─────────────────┐
    │   Show Login Screen       │
    └────────┬────────────────┘
             │
             ├─→ Option: Enter Email/Password
             │     │
             │     └─→ Firebase Auth
             │           ├─ Success → Generate Session
             │           └─ Error → Show error
             │
             ├─→ Option: Enter PIN
             │     │
             │     └─→ PIN validation (PBKDF2)
             │           ├─ Correct → Proceed
             │           └─ Wrong → Retry
             │
             └─→ Option: Use Biometric
                   │
                   └─→ Fingerprint/Face Recognition
                         ├─ Match → Verify against PIN hash
                         ├─ Success → Generate session
                         └─ Failure → Retry
```

### Transfer Use Case

```
Actor: Authenticated User

    ┌──────────────────────────┐
    │ User selects "Transfer"  │
    └────────┬─────────────────┘
             │
    ┌────────▼──────────────────┐
    │  Show Transfer Screen     │
    └────────┬─────────────────┘
             │
    ┌────────▼──────────────────────┐
    │  User enters transfer data:   │
    │  - Recipient IBAN (34 chars)  │
    │  - Amount (EUR, USD, GBP)     │
    │  - Description (optional)     │
    └────────┬──────────────────────┘
             │
    ┌────────▼──────────────────────┐
    │  Validate IBAN format         │
    │  ├─ Valid? → Continue         │
    │  └─ Invalid? → Show error     │
    └────────┬──────────────────────┘
             │
    ┌────────▼──────────────────────┐
    │  Calculate transfer fee       │
    │  ├─ Instant transfer? 0.5%    │
    │  ├─ Scheduled transfer? Free  │
    │  └─ International? 1.0%       │
    └────────┬──────────────────────┘
             │
    ┌────────▼──────────────────────┐
    │  Show confirmation screen:    │
    │  ├─ Recipient IBAN            │
    │  ├─ Amount + fee              │
    │  ├─ Total debit               │
    │  └─ Confirm button            │
    └────────┬──────────────────────┘
             │
    ┌────────▼──────────────────────┐
    │  User confirms transfer       │
    └────────┬──────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Create Transaction record:        │
    │  ├─ Save to Firestore              │
    │  ├─ Generate receipt               │
    │  ├─ Create notification            │
    │  └─ Sign with HMAC-SHA256          │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Success:                          │
    │  ├─ Update account balance         │
    │  ├─ Show receipt                   │
    │  ├─ Offer PDF download             │
    │  └─ Show transaction history       │
    └────────────────────────────────────┘
```

### PQC Handshake Use Case

```
Actor: Mobile App Client
Partner: Backend Server

    ┌────────────────────────────────────┐
    │   Initiate Secure Connection       │
    └────────┬─────────────────────────┘
             │
    Phase 1: Client Key Generation
    ┌────────▼──────────────────────────┐
    │  Generate EC keypair (secp256r1)  │
    │  └─ 32-byte private key           │
    │  └─ 65-byte public key            │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Generate Kyber keypair (ML-KEM) │
    │  └─ 2400-byte private key         │
    │  └─ 1184-byte public key          │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Send to Server:                  │
    │  (EC_public || Kyber_public)      │
    │  Total: 1249 bytes                │
    └────────┬──────────────────────────┘
             │
    Phase 2: Server Shared Secret
    ┌────────▼──────────────────────────┐
    │  Server receives keys             │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Kyber Encapsulation:             │
    │  ├─ Generate ephemeral secret     │
    │  └─ Encapsulate with client key   │
    │  └─ 1088-byte ciphertext          │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  ECDH Computation:                │
    │  └─ Compute shared secret         │
    │  └─ 32-byte result                │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Combine shared secrets:          │
    │  secret = SHA256(Kyber || ECDH)  │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Send Kyber ciphertext to Client  │
    │  Total: 1088 bytes                │
    └────────┬──────────────────────────┘
             │
    Phase 3: Client Shared Secret
    ┌────────▼──────────────────────────┐
    │  Client receives ciphertext       │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Kyber Decapsulation:             │
    │  └─ Use private key to decrypt    │
    │  └─ Recover server's secret       │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  ECDH Computation:                │
    │  └─ Use server's public key       │
    │  └─ Compute same shared secret    │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  Combine secrets (same as server) │
    │  secret = SHA256(Kyber || ECDH)  │
    └────────┬──────────────────────────┘
             │
    Phase 4: Secure Channel
    ┌────────▼──────────────────────────┐
    │  Derive session keys:             │
    │  ├─ enc_key = HKDF(secret)        │
    │  └─ mac_key = HKDF(secret)        │
    └────────┬──────────────────────────┘
             │
    ┌────────▼──────────────────────────┐
    │  All communications encrypted:    │
    │  ├─ Encrypt: AES-256-GCM          │
    │  ├─ Authenticate: HMAC-SHA256     │
    │  └─ Session established!          │
    └────────────────────────────────────┘
```

---

## Data Flow Diagrams

### Request/Response Flow

```
┌─────────────────────────────┐
│   User taps button          │
└────────┬────────────────────┘
         │
┌────────▼────────────────────┐
│   Screen Widget             │
│   onPressed: () {           │
│     Provider.method()       │
│   }                         │
└────────┬────────────────────┘
         │
┌────────▼────────────────────────┐
│   Provider (ChangeNotifier)      │
│   void method() {                │
│     _isLoading = true;           │
│     notifyListeners();           │
│     _service.operation()         │
│   }                              │
└────────┬─────────────────────────┘
         │
┌────────▼────────────────────────┐
│   Service                        │
│   Future<Result> operation() {   │
│     return firebase.call()       │
│   }                              │
└────────┬─────────────────────────┘
         │
┌────────▼─────────────────────────┐
│   Firebase API                    │
│   ├─ Firestore query              │
│   ├─ Auth request                 │
│   └─ Cloud Storage operation      │
└────────┬──────────────────────────┘
         │
         ↓ Response
         │
┌────────▼──────────────────────────┐
│   Service receives response       │
│   ├─ Parse data                   │
│   ├─ Validate with HMAC           │
│   └─ Return to provider           │
└────────┬───────────────────────────┘
         │
┌────────▼───────────────────────────┐
│   Provider updates state           │
│   ├─ _data = response              │
│   ├─ _isLoading = false            │
│   └─ notifyListeners()             │
└────────┬────────────────────────────┘
         │
┌────────▼────────────────────────────┐
│   Consumer<Provider> rebuilds       │
│   ├─ Check provider.isLoading       │
│   ├─ Check provider.error           │
│   └─ Build with provider.data       │
└────────┬─────────────────────────────┘
         │
┌────────▼──────────────────────────┐
│   UI Updates                      │
│   └─ Display new data             │
└───────────────────────────────────┘
```

### Authentication Flow

```
App Start
  │
  ├─→ Check cached session
  │   ├─ Valid? → Resume with user data
  │   └─ Expired? ↓
  │
  ├─→ AuthProvider.initialize()
  │   ├─ Check Firebase token
  │   ├─ Validate session
  │   └─ Load user profile
  │       ├─ Success → Set userId
  │       └─ Fail → Show login
  │
  ├─→ ProxyProviders activate
  │   ├─ AccountProvider.initialize(userId)
  │   ├─ CardProvider.initialize(userId)
  │   ├─ TransferProvider.initialize(userId)
  │   └─ ... (all providers)
  │
  ├─→ Real-time listeners start
  │   ├─ Firestore.snapshots()
  │   ├─ FCM tokens refresh
  │   └─ Listen for updates
  │
  └─→ Dashboard screen displayed
```

### Database Operation Flow

```
UI Layer (Screen)
        │
        ├─ User action
        └─ Call Provider.method()
                │
Provider Layer
        │
        ├─ Set isLoading = true
        ├─ notifyListeners()
        └─ Call Service.operation()
                │
Service Layer
        │
        ├─ Validate input
        ├─ Call Firebase/Storage
        └─ Handle errors
                │
Data Layer
        │
        ├─ Firestore:
        │   ├─ Query documents
        │   ├─ Apply security rules
        │   └─ Return data
        │
        ├─ Secure Storage:
        │   ├─ Encrypt with local key
        │   ├─ Store in Keychain/KeyStore
        │   └─ Return decrypted data
        │
        └─ Cloud Storage:
            ├─ Upload/Download files
            └─ Apply access control
                    │
Return to Service
        │
        ├─ Parse response
        ├─ Sign with HMAC
        └─ Return to Provider
                │
Provider processes response
        │
        ├─ Update state
        ├─ Set isLoading = false
        ├─ notifyListeners()
        └─ Consumer rebuilds
                │
UI Updates with new data
```

---

## Development Workflow

### Feature Development Checklist

#### 1. Planning Phase

- [ ] Understand feature requirements
- [ ] Review architecture for similar patterns
- [ ] Design data model (if needed)
- [ ] Sketch UI mockup
- [ ] Plan API endpoints/Firebase collections
- [ ] Identify security considerations

#### 2. Implementation Phase

**Model Layer** (`lib/models/`)
- [ ] Create model class with all fields
- [ ] Implement `toMap()` for serialization
- [ ] Implement `fromMap()` for deserialization
- [ ] Add `copyWith()` for immutability
- [ ] Implement `toString()` for debugging
- [ ] Add validation methods if needed

```dart
class Feature {
  final String id;
  final String name;
  final DateTime createdAt;

  Feature({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  // Serialization
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  // Deserialization
  factory Feature.fromMap(Map<String, dynamic> map) => Feature(
    id: map['id'] as String,
    name: map['name'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );

  // Immutability
  Feature copyWith({String? name, DateTime? createdAt}) => Feature(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  String toString() => 'Feature($id, $name)';
}
```

**Service Layer** (`lib/services/`)
- [ ] Create service class
- [ ] Implement Firebase CRUD operations
- [ ] Add error handling and validation
- [ ] Implement real-time listeners (if needed)
- [ ] Add security checks (signature, HMAC)
- [ ] Write unit tests

```dart
class FeatureService {
  Future<List<Feature>> getFeatures(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('features')
          .get();

      return snapshot.docs
          .map((doc) => Feature.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw FeatureException('Failed to fetch features: $e');
    }
  }

  Stream<List<Feature>> streamFeatures(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('features')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Feature.fromMap(doc.data()))
            .toList());
  }

  Future<void> createFeature(String userId, Feature feature) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('features')
          .doc(feature.id)
          .set(feature.toMap());
    } catch (e) {
      throw FeatureException('Failed to create feature: $e');
    }
  }
}
```

**Provider Layer** (`lib/providers/`)
- [ ] Create provider extending ChangeNotifier
- [ ] Implement state variables (items, loading, error)
- [ ] Add getters for state
- [ ] Implement initialize() method
- [ ] Implement real-time listening
- [ ] Proper cleanup in dispose()
- [ ] Write provider tests

```dart
class FeatureProvider extends ChangeNotifier {
  final FeatureService _service = FeatureService();

  List<Feature> _features = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  // Getters
  List<Feature> get features => _features;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialization
  Future<void> initialize(String userId) async {
    _startListening(userId);
  }

  // Real-time listening
  void _startListening(String userId) {
    _subscription = _service.streamFeatures(userId).listen(
      (features) {
        _features = features;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // Fetch operation
  Future<void> fetchFeatures(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _features = await _service.getFeatures(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // Create operation
  Future<void> createFeature(String userId, Feature feature) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createFeature(userId, feature);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // Cleanup
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

**UI Layer** (`lib/screens/`)
- [ ] Create screen widget
- [ ] Use Consumer for state management
- [ ] Implement loading state UI
- [ ] Implement error state UI
- [ ] Handle empty state
- [ ] Follow Material Design 3
- [ ] Write widget tests

```dart
class FeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: Consumer<FeatureProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.features.isEmpty) {
            return const Center(child: Text('No features'));
          }

          return ListView(
            children: provider.features
                .map((feature) => ListTile(
                  title: Text(feature.name),
                  subtitle: Text(feature.createdAt.toString()),
                ))
                .toList(),
          );
        },
      ),
    );
  }
}
```

#### 3. Testing Phase

**Unit Tests** (`test/unit/`)
- [ ] Test model serialization/deserialization
- [ ] Test service methods with mocks
- [ ] Test provider state changes
- [ ] Test error handling
- [ ] Test edge cases

**Widget Tests** (`test/widget/`)
- [ ] Test screen displays correctly
- [ ] Test user interactions
- [ ] Test loading/error/empty states
- [ ] Test navigation

**Integration Tests** (`test/integration/`)
- [ ] Test full flow with Firebase
- [ ] Test real Firestore operations
- [ ] Test authentication flow

#### 4. Documentation Phase

- [ ] Add to README features list
- [ ] Update ARCHITECTURE.md
- [ ] Add/update use case diagram
- [ ] Update data flow diagram
- [ ] Add inline code documentation
- [ ] Update CHANGELOG.md

#### 5. Code Review Phase

- [ ] Run `flutter analyze` (0 errors)
- [ ] Run `flutter test` (all pass)
- [ ] Format code: `dart format lib/`
- [ ] Check code coverage
- [ ] Self-review checklist
- [ ] Address review comments

---

## Code Standards

### Dart/Flutter Conventions

```dart
// ✓ Good
class FeatureProvider extends ChangeNotifier {
  final FeatureService _service = FeatureService();

  List<Feature> _features = [];
  bool _isLoading = false;
  String? _error;

  List<Feature> get features => _features;

  Future<void> initialize(String userId) async {
    _startListening(userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ✗ Bad
class featureProvider extends ChangeNotifier {
  var service = new FeatureService();  // Wrong name, wrong instantiation
  features = [];  // No type, no privacy

  Future initialize(userId) {  // Missing async, missing return type
    startListening(userId);  // Missing underscore (private method)
  }
  // Missing dispose!
}
```

### Null Safety

```dart
// ✓ Good
String? getUserName(User user) {
  return user.profile?.name;
}

final name = user?.name ?? 'Unknown';
final items = _items ?? [];

// ✗ Bad
String getUserName(User user) {
  return user.profile.name;  // Can crash if profile is null
}

// Force unwrap only when 100% certain
final name = user.name!;  // Dangerous!
```

### Error Handling

```dart
// ✓ Good
try {
  final data = await service.fetchData();
  _data = data;
} on FirebaseException catch (e) {
  _error = 'Database error: ${e.message}';
} on SocketException catch (e) {
  _error = 'Network error: ${e.message}';
} catch (e) {
  _error = 'Unknown error: $e';
}

// ✗ Bad
try {
  _data = await service.fetchData();
} catch (e) {
  // Silent failure, no logging!
}
```

### Comments & Documentation

```dart
// ✓ Good - explains WHY, not WHAT
/// Derives session key using HKDF-SHA256.
///
/// This extracts entropy from the shared secret and derives
/// independent keys for encryption and HMAC operations,
/// following RFC 5869 for key derivation.
Future<Uint8List> deriveSessionKey(Uint8List secret) async {
  // ...
}

// ✗ Bad - obvious from code
/// Gets the user name
String getName(User user) {
  return user.name;
}
```

### File Organization

```
One concept per file:
✓ feature_model.dart
✓ feature_service.dart
✓ feature_provider.dart
✓ feature_screen.dart

✗ feature_all.dart (everything in one file)
```

---

## Contributing Checklist

### Before Committing

```bash
# Code Quality
✓ flutter analyze                # 0 errors/warnings
✓ dart format lib/ test/         # Code formatted
✓ flutter test                   # All tests pass
✓ git status                     # Only intended changes

# Documentation
✓ Updated README.md (if feature)
✓ Updated ARCHITECTURE.md (if major)
✓ Updated CHANGELOG.md (always)
✓ Added code comments (where needed)
✓ Added tests for new code

# Security
✓ No hardcoded secrets
✓ No sensitive data logged
✓ Proper error handling
✓ Input validation
✓ No force unwraps
```

### Commit Message Format

```
type(scope): description

ADDITIONS:
- What was added

CHANGES:
- What was modified

FIXES:
- What was fixed (if applicable)
```

**Types**: `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `perf`, `security`

### Pull Request Template

```markdown
## Description
Brief explanation of changes

## Type
- [ ] New Feature
- [ ] Bug Fix
- [ ] Documentation
- [ ] Security Enhancement
- [ ] Refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] No new compilation errors
- [ ] Tests passing (flutter test)
- [ ] Documentation updated
- [ ] Comments added where needed
```

---

## Security Considerations

### Cryptographic Operations

When working with PQC (Post-Quantum Cryptography):

1. **Review NIST Standards**:
   - Kyber (FIPS 203): https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf
   - Performance metrics: Measure on actual devices
   - Security properties: Understand threat model

2. **Implementation Security**:
   - Use constant-time comparisons for HMAC
   - Securely erase sensitive data
   - Prevent side-channel attacks
   - Test edge cases (empty input, max size)

### Data Protection

- **Never hardcode**: API keys, secrets, tokens
- **Use environment variables**: For configuration
- **Secure storage**: Only for credentials
- **Encryption**: All PII in transit and at rest
- **Validation**: All user input at boundaries

### Firestore Security Rules

```
// ✓ Good - Field-level access control
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}

// ✗ Bad - Allows public access
match /users/{userId} {
  allow read, write: if true;
}
```

### Reporting Security Issues

**Do NOT open public issues for vulnerabilities.**

Instead, email: **vagneripg@gmail.com**

Subject: `[BJBank Security] Vulnerability Report`

Include:
- Vulnerability description
- Affected component
- Steps to reproduce
- Suggested fix (if you have one)

---

## Testing Strategy

### Test Pyramid

```
        /\
       /  \  Unit Tests (70%)
      /    \ - Models
     /      \ - Services
    /        \ - Providers
   /          \
  /____________\

   /\
  /  \        Widget Tests (20%)
 /    \       - Screens
/______\      - Widgets

    /\
   /  \      Integration Tests (10%)
  /____\     - Full flows
           - Real Firebase
```

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/unit/providers/account_provider_test.dart

# Coverage
flutter test --coverage

# Watch mode
flutter test --watch

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Test Example

```dart
void main() {
  group('FeatureProvider', () {
    late FeatureProvider provider;
    late MockFeatureService mockService;

    setUp(() {
      mockService = MockFeatureService();
      provider = FeatureProvider(service: mockService);
    });

    tearDown(() {
      provider.dispose();
    });

    test('initializes with empty features', () {
      expect(provider.features, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('fetches features successfully', () async {
      final expected = [Feature(id: '1', name: 'Test')];
      when(mockService.getFeatures('user123'))
          .thenAnswer((_) async => expected);

      await provider.fetchFeatures('user123');

      expect(provider.features, equals(expected));
      expect(provider.error, isNull);
    });

    test('handles errors gracefully', () async {
      when(mockService.getFeatures('user123'))
          .thenThrow(Exception('Network error'));

      await provider.fetchFeatures('user123');

      expect(provider.features, isEmpty);
      expect(provider.error, contains('Network error'));
    });
  });
}
```

---

## Documentation

### What to Document

1. **Complex Algorithms**: Especially PQC operations
2. **Data Models**: Field definitions, validation rules
3. **Service Methods**: Parameters, return values, exceptions
4. **Architecture Decisions**: Use ADRs

### Document Structure

```markdown
## Feature Name

### Overview
Brief description

### Use Case Diagram
ASCII diagram showing interactions

### Data Flow Diagram
ASCII diagram showing data movement

### API Reference
Methods, parameters, returns

### Security Considerations
Any security implications

### Example Usage
Code examples
```

---

## Git Workflow

### Branch Strategy

```
main (production-ready)
  │
  ├─ feature/new-feature
  │   │
  │   └─ feature/new-feature:latest (for review)
  │
  ├─ fix/bug-description
  │
  ├─ docs/documentation-update
  │
  └─ research/experimental-feature
```

### Commit Guidelines

```bash
# Small, focused commits
git commit -m "feat(transfer): Add IBAN validation

ADDITIONS:
- IBAN regex validation pattern
- Country code detection
- Checksum verification

CHANGES:
- Updated TransferScreen with validation error display"

# Each commit should be reviewable in one sitting
# One logical change per commit
# Test before committing
```

---

## Support & Communication

### Getting Help

| Topic | Channel |
|-------|---------|
| **Architecture Questions** | Open an issue |
| **Security Issues** | Email vagneripg@gmail.com |
| **Feature Discussions** | Create discussion thread |
| **Research Collaboration** | Contact Prof. Rui A. P. Perdigão |
| **General Questions** | Project discussions |

### Project Maintainers

| Role | Name | Email |
|------|------|-------|
| **Author** | Vagner Bom Jesus | vagneripg@gmail.com |
| **Advisor** | Prof. Rui A. P. Perdigão | - |

### Citation

If you use this project in academic work:

```bibtex
@mastersthesis{bom2026bjbank,
  author = {Vagner Bom Jesus},
  title = {Post-Quantum Cryptography in Mobile Banking Applications},
  school = {Instituto Politécnico da Guarda},
  year = {2026},
  advisor = {Prof. Rui A. P. Perdigão}
}
```

---

## Resources

### Documentation
- [README.md](./README.md) - Project overview
- [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) - System architecture
- [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md) - Deployment guide
- [docs/FIREBASE-BEST-PRACTICES.md](./docs/FIREBASE-BEST-PRACTICES.md) - Firebase config
- [CHANGELOG.md](./CHANGELOG.md) - Version history

### Architecture Decision Records (ADRs)
- [ADR-001: Post-Quantum Cryptography](./docs/adr/ADR-001-PQC-IMPLEMENTATION.md)
- [ADR-002: State Management](./docs/adr/ADR-002-STATE-MANAGEMENT.md)
- [ADR-003: Security Strategy](./docs/adr/ADR-003-SECURITY-STRATEGY.md)

### Learning Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Guide](https://dart.dev/guides)
- [Firebase Documentation](https://firebase.google.com/docs)
- [NIST PQC Standardization](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [libOQS Documentation](https://liboqs.org/)

---

**Last Updated**: 18 April 2026
**Project Status**: Production-Ready
**License**: Academic Research License (see [LICENSE](./LICENSE))

For more information, visit the [project repository](https://github.com/VagnerBomJesus/BJBank).
