# BJBank - Post-Quantum Cryptography in Mobile Banking

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)](https://docs.flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)](https://firebase.google.com/docs)
[![NIST PQC](https://img.shields.io/badge/NIST-PQC%20Standard-green)](https://csrc.nist.gov/projects/post-quantum-cryptography)
[![License](https://img.shields.io/badge/License-Academic%20Research-blue)](./LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)]()

<div align="center">
  <img src="https://github.com/VagnerBomJesus/BJBank/blob/main/assets/logo_bjbank.png?raw=true" alt="BJBank Logo" width="200"/>
</div>

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Architecture](#architecture)
- [Post-Quantum Cryptography](#post-quantum-cryptography)
- [Technology Stack](#technology-stack)
- [Installation](#installation)
- [Testing](#testing)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## About

**BJBank** is a complete banking mobile application developed in Flutter focusing on **Post-Quantum Cryptography (PQC)**.

### Academic Context

| Field | Value |
|-------|-------|
| **Type** | Master's Dissertation |
| **Title** | Post-Quantum Cryptography in Mobile Applications |
| **Author** | Vagner Bom Jesus |
| **Advisor** | Prof. Rui A. P. Perdigão |
| **Institution** | Instituto Politécnico da Guarda |
| **Completion Date** | 18/04/2026 |

### Objectives

1. Complete banking system implementation in Flutter
2. Post-quantum cryptography integration (Kyber + Elliptic Curve)
3. Hybrid security demonstration (classical + quantum)
4. PQC performance and overhead evaluation
5. Production implementation guides creation

---

## Features

### Phase 1: Core Banking [100%]
- Authentication (Email/Password/PIN)
- User Profile Management
- Real-time Dashboard
- Multiple Accounts Support
- Transaction History with Filters
- Post-Quantum Cryptography (Hybrid Handshake)

### Phase 2: Financial Management [100%]
- Advanced Card Management (5 types)
- Transfers (Instant + Scheduled)
- Bill Management
- MB WAY Payments
- OTP Verification

### Phase 3: Advanced Financial [100%]
- Loan Management
- Investment Portfolio
- Savings Goals
- Budget Management by Category

### Phase 4: Advanced Features [100%]
- Card Blocking/Unblocking
- Push Notifications (FCM)
- QR Code Payments
- Badge System (13 transaction types)

**Total: 50+ Features Implemented**

---

## Architecture

```
┌─────────────────────────────────────────┐
│         Flutter Frontend (UI)           │
│  • Material Design 3                    │
│  • Dark Theme                           │
│  • Real-time Updates                    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│     State Management (Provider)         │
│  • 12 Providers                         │
│  • ChangeNotifier Pattern               │
│  • Consumer & ProxyProvider             │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│        Services Layer                   │
│  • 20 Services                          │
│  • Business Logic                       │
│  • External Integrations                │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│     Firebase Backend                    │
│  • Authentication                       │
│  • Firestore (Real-time DB)             │
│  • Cloud Messaging (FCM)                │
│  • Storage                              │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│    Security & Cryptography              │
│  • PQC (Kyber + EC hybrid)              │
│  • HMAC-SHA256                          │
│  • Secure Storage                       │
│  • libOQS (native)                      │
└─────────────────────────────────────────┘
```

---

## Post-Quantum Cryptography

### Hybrid Handshake Implementation

```
Client                          Server
  │                              │
  ├─ Generate EC Keys ───────────┤
  │  (secp256r1)                 │
  │                              │
  ├─ Generate Kyber Keys ────────┤
  │  (NIST standard)             │
  │                              │
  ├─ Send (EC_pub + Kyber_pub)──┤
  │                              │
  │                              │
  │  Generate shared secret      │
  │  KEM(kyber) || ECDH(ec)      │
  │                              │
  ├─ Establish secure channel ───┤
  │  (All subsequent comms)      │
  │                              │
```

### Algorithms Used

| Component | Algorithm | NIST Standard | Purpose |
|-----------|-----------|---------------|---------|
| **Key Encapsulation** | Kyber | FIPS 203 | Primary KEM |
| **Signature** | Falcon (fallback) | NIST PQC | Digital signatures |
| **Classic Fallback** | ECDH secp256r1 | FIPS 186-4 | Hybrid compatibility |
| **Hash** | SHA-256 | FIPS 180-4 | Integrity verification |
| **MAC** | HMAC-SHA256 | FIPS 198-1 | Message authentication |

### Performance Metrics

```
Operation          | Time (ms) | Size (bytes)
-----------------------|-----------|----------
EC Key Gen         | 5-10      | 65
Kyber Key Gen      | 15-25     | 1632
Shared Secret      | 8-12      | 32
Signature (Falcon) | 20-30     | 666
Verification       | 10-15     | -
```

---

## Technology Stack

### Frontend
- **Flutter** 3.8.1 - Mobile UI framework
- **Dart** 3.8+ - Programming language
- **Material Design 3** - Design system
- **Provider** 6.x - State management

### Backend Services
- **Firebase** - Backend as a service
  - Authentication
  - Cloud Firestore (Real-time database)
  - Cloud Messaging (Push notifications)
  - Cloud Storage

### Security & Cryptography
- **libOQS** - Open Quantum Safe library
- **Kyber** - Key Encapsulation Mechanism
- **Elliptic Curve** - secp256r1 (FIPS 186-4)
- **HMAC-SHA256** - Message authentication

### Key Dependencies
- `oqs` - Post-quantum cryptography bindings
- `qr_flutter` - QR code generation
- `mobile_scanner` - QR code scanning
- `intl` - Internationalization
- `uuid` - UUID generation

---

## Project Structure

```
lib/
├── main.dart                      # Entry point
├── app.dart                       # App configuration
├── models/                        # Data models (14)
├── providers/                     # State management (12)
├── services/                      # Business logic (20)
├── screens/                       # UI screens (33+)
├── widgets/                       # Custom widgets (9+)
├── routes/                        # Navigation
├── theme/                         # Design system
└── config/                        # Configuration

test/                              # Tests
android/                           # Android native
ios/                               # iOS native
```

---

## Installation

### Prerequisites
- Flutter 3.8.1+
- Dart 3.8+
- Android SDK / Xcode
- Firebase account
- libOQS library (optional for production)

### Setup

1. Clone the repository
```bash
git clone https://github.com/VagnerBomJesus/BJBank.git
cd bjbank
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
```bash
# Android
flutterfire configure --platforms=android

# iOS
flutterfire configure --platforms=ios
```

4. Run in development
```bash
flutter run
```

---

## Documentation

### Key Documents
- **[IMPLEMENTATION_OVERVIEW.md](./IMPLEMENTATION_OVERVIEW.md)** - Complete technical inventory
- **[COMMIT_FEATURES.md](./COMMIT_FEATURES.md)** - Implementation history
- **[ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - Detailed system architecture
- **[DEPLOYMENT.md](./docs/DEPLOYMENT.md)** - Deployment guide

### Architecture Decision Records (ADRs)
- **[ADR-001: Post-Quantum Cryptography Implementation](./ADR-001-PQC-IMPLEMENTATION.md)** - Hybrid Kyber + ECDH handshake
- **[ADR-002: State Management Architecture](./ADR-002-STATE-MANAGEMENT.md)** - Provider pattern with ChangeNotifier
- **[ADR-003: Security Strategy](./docs/adr/ADR-003-SECURITY-STRATEGY.md)** - Multi-layer security architecture

---

## Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test --verbose
```

### Build Release
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## Statistics

| Metric | Value |
|--------|-------|
| **Dart Files** | 113 |
| **Lines of Code** | ~19,900 |
| **Models** | 14 |
| **Providers** | 12 |
| **Services** | 20 |
| **Screens** | 33+ |
| **Widgets** | 9+ |
| **Features** | 50+ |
| **Commits** | 37 |
| **Compilation Errors** | 0 |

---

## Security

### Security Layers
1. **Transport** - HTTPS/TLS
2. **Authentication** - Firebase Auth + PIN
3. **Encryption** - PQC Hybrid (Kyber + EC)
4. **Storage** - Secure Flutter storage
5. **Data** - HMAC-SHA256 validation

### Best Practices Implemented
- No hardcoded secrets
- Secure token storage
- PIN-based local authentication
- Real-time Firestore security rules
- GDPR compliance ready
- Type-safe operations
- Multi-layer encryption

---

## License

This project is developed for academic research purposes as a Master's Dissertation at Instituto Politécnico da Guarda.

**Author**: Vagner Bom Jesus
**Institution**: Instituto Politécnico da Guarda
**Year**: 2026
**License**: Academic Research

See [LICENSE](./LICENSE) file for details.

---

## Contributing

This is an academic research project. For extension or future research inquiries, please contact the authors.

### References
- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [Open Quantum Safe Organization](https://openquantumsafe.org/)
- [libOQS Library](https://github.com/open-quantum-safe/liboqs)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Security Best Practices](https://firebase.google.com/docs/security)

---

## Contact

**Author**: Vagner Bom Jesus
**Email**: vagneripg@gmail.com
**Advisor**: Prof. Rui A. P. Perdigão
**Institution**: Instituto Politécnico da Guarda

---

**Project Status**: Production Ready (100% Complete - RF01-RF13)
**Completion Date**: 18/04/2026
**Built with**: Flutter 3.8.1 & Post-Quantum Cryptography
