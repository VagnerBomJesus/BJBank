# 🏦 BJBank - Post-Quantum Cryptography in Mobile Banking

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)](https://firebase.google.com)
[![NIST PQC](https://img.shields.io/badge/NIST-PQC%20Standard-green)](https://csrc.nist.gov/projects/post-quantum-cryptography)
[![License](https://img.shields.io/badge/License-Academic%20Research-blue)]()
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)]()

---

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Features Implementadas](#features-implementadas)
- [Arquitetura](#arquitetura)
- [Criptografia Pós-Quântica](#criptografia-pós-quântica)
- [Stack Tecnológico](#stack-tecnológico)
- [Instalação](#instalação)
- [Uso](#uso)
- [Documentação](#documentação)
- [Contribuição](#contribuição)
- [Licença](#licença)

---

## 🎯 Sobre o Projeto

**BJBank** é uma aplicação bancária móvel completa desenvolvida em Flutter com foco em **Criptografia Pós-Quântica (PQC)**.

### 🎓 Contexto Académico

| Campo | Valor |
|-------|-------|
| **Tipo** | Dissertação de Mestrado |
| **Título** | Criptografia Pós-Quântica em Aplicações Móveis |
| **Autor** | Vagner Bom Jesus |
| **Orientador** | Professor Rui A. P. Perdigão |
| **Instituição** | Instituto Politécnico da Guarda |
| **Data Conclusão** | 18/04/2026 |

### 🎯 Objetivos

1. ✅ Implementar sistema bancário completo em Flutter
2. ✅ Integrar criptografia pós-quântica (Kyber + Elliptic Curve)
3. ✅ Demonstrar segurança híbrida (clássica + quântica)
4. ✅ Avaliar performance e overhead PQC
5. ✅ Criar guias de implementação para produção

---

## ✨ Features Implementadas

### **Phase 1: Core Banking** ✅ 100%
- 🔐 Autenticação (email/password/PIN)
- 👤 Gestão de perfil
- 📊 Dashboard em tempo real
- 💳 Múltiplas contas
- 📝 Histórico transações com filtros
- 🔒 PQC Cryptography (Hybrid Handshake)

### **Phase 2: Financial Management** ✅ 100%
- 💳 Gestão avançada de cartões (5 tipos)
- 💸 Transferências (instantâneas + agendadas)
- 📄 Gestão de faturas
- 📱 Pagamentos MB WAY
- ✅ OTP verification

### **Phase 3: Advanced Financial** ✅ 100%
- 💰 Gestão de empréstimos
- 📈 Portfolio de investimentos
- 🎯 Metas de poupança
- 💼 Orçamentos por categoria

### **Phase 4: Advanced Features** ✅ 100%
- 🚫 Bloqueio/desbloqueio de cartões
- 🔔 Push Notifications (FCM)
- 📲 Pagamentos por QR Code
- 🏷️ Sistema de Badges (13 tipos)

### **Total: 50+ Features Implementadas**

---

## 🏗️ Arquitetura

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

## 🔐 Criptografia Pós-Quântica

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

### Algoritmos Utilizados

| Componente | Algoritmo | NIST Standard | Nota |
|-----------|-----------|---------------|------|
| **Key Encapsulation** | Kyber | Aprovado | Principal |
| **Signature** | Falcon (fallback) | NIST PQC | Assinaturas |
| **Classic Fallback** | ECDH secp256r1 | FIPS 186-4 | Compatibilidade |
| **Hash** | SHA-256 | FIPS 180-4 | Integridade |
| **MAC** | HMAC-SHA256 | FIPS 198-1 | Autenticação |

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

## 🛠️ Stack Tecnológico

### Frontend
- **Flutter** 3.8.1 - Framework UI
- **Dart** 3.8+ - Linguagem
- **Material Design 3** - Design System
- **Provider** 6.x - State Management

### Backend
- **Firebase** - Backend as Service
  - Authentication
  - Cloud Firestore (DB Real-time)
  - Cloud Messaging (Push Notifications)
  - Cloud Storage

### Segurança
- **libOQS** - Open Quantum Safe library
- **Kyber** - Key Encapsulation (NIST approved)
- **Elliptic Curve** - secp256r1 (FIPS 186-4)
- **HMAC-SHA256** - Message Authentication

### Bibliotecas Principais
- `oqs` - PQC bindings
- `qr_flutter` - QR generation
- `mobile_scanner` - QR scanning
- `intl` - Internationalization
- `uuid` - UUID generation

---

## 📁 Estrutura do Projeto

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

## 🚀 Instalação

### Pré-requisitos
- Flutter 3.8.1+
- Dart 3.8+
- Android SDK / Xcode
- Firebase account
- libOQS library (optional for production)

### Setup

1. **Clone o repositório**
```bash
git clone https://github.com/vagnerbom/bjbank.git
cd bjbank
```

2. **Instale dependências**
```bash
flutter pub get
```

3. **Configure Firebase**
```bash
# Android
flutterfire configure --platforms=android

# iOS
flutterfire configure --platforms=ios
```

4. **Execute em desenvolvimento**
```bash
flutter run
```

---

## 📚 Documentação

### Documentos Principais
- **[IMPLEMENTATION_OVERVIEW.md](./IMPLEMENTATION_OVERVIEW.md)** - Inventário técnico completo
- **[COMMIT_FEATURES.md](./COMMIT_FEATURES.md)** - Histórico de implementação
- **[ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - Arquitetura detalhada
- **[DEPLOYMENT.md](./docs/DEPLOYMENT.md)** - Guia de deployment

### Architecture Decision Records (ADRs)
- **[ADR-001: PQC Implementation Mode](./docs/adr/ADR-001-pqc-implementation.md)** - Decisão: Hybrid Handshake
- **[ADR-002: State Management](./docs/adr/ADR-002-state-management.md)** - Decisão: Provider pattern
- **[ADR-003: Security Strategy](./docs/adr/ADR-003-security-strategy.md)** - Decisão: Layered security

---

## 🧪 Testes

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

## 📊 Estatísticas

| Métrica | Valor |
|---------|-------|
| **Arquivos Dart** | 113 |
| **Linhas de Código** | ~19,900 |
| **Modelos** | 14 |
| **Providers** | 12 |
| **Serviços** | 20 |
| **Screens** | 33+ |
| **Widgets** | 9+ |
| **Features** | 50+ |
| **Commits** | 28 |
| **Compilation Errors** | 0 |

---

## 🔒 Segurança

### Camadas de Segurança
1. **Transport** - HTTPS/TLS
2. **Authentication** - Firebase Auth + PIN
3. **Encryption** - PQC Hybrid (Kyber + EC)
4. **Storage** - Secure Flutter storage
5. **Data** - HMAC-SHA256 validation

### Boas Práticas Implementadas
- ✅ No hardcoded secrets
- ✅ Secure token storage
- ✅ PIN-based local authentication
- ✅ Real-time Firestore rules
- ✅ GDPR compliance ready
- ✅ Type-safe operations

---

## 📝 Licença

Este projeto é desenvolvido para fins académicos de investigação.

**Autor**: Vagner Bom Jesus
**Instituição**: Instituto Politécnico da Guarda
**Ano**: 2026

---

## 🤝 Contribuição

Este é um projeto académico de pesquisa. Para fins de extensão ou pesquisa futura, consulte os autores.

### Referências
- [NIST PQC Standardization](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [libOQS Documentation](https://liboqs.org/)
- [Flutter Best Practices](https://flutter.dev/docs)
- [Firebase Security](https://firebase.google.com/docs/security)

---

## 📧 Contacto

**Autor**: Vagner Bom Jesus
**Email**: vagneripg@gmail.com
**Orientador**: Prof. Rui A. P. Perdigão

---

**Status Final**: ✅ Production Ready - 100% Completo (RF01-RF13)
**Data**: 18/04/2026
**Desenvolvido com**: Flutter & Post-Quantum Cryptography
