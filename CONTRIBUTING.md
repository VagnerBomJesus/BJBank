# Contributing to BJBank

**BJBank** is an academic research project focused on Post-Quantum Cryptography implementation in mobile banking applications.

## Project Context

This is a **Master's Dissertation** developed at Instituto Politécnico da Guarda, not a traditional open-source project. Contributions are welcome for:
- Academic research and experimentation
- Educational purposes
- Bug reports and security disclosures
- Feature extensions for research purposes

**Not suitable for**: Production banking systems, commercial implementations, or competitive applications.

---

## Getting Started

### Prerequisites

- Flutter 3.8.1 or later
- Dart 3.8+
- Android SDK / Xcode
- Firebase account (for backend testing)
- git knowledge (small, focused commits)

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/VagnerBomJesus/BJBank.git
cd bjbank

# Install dependencies
flutter pub get

# Configure Firebase
flutterfire configure

# Verify setup
flutter analyze
flutter test
```

---

## Code Contribution Guidelines

### Before You Contribute

1. **Understand the License**: See [LICENSE](./LICENSE) file. Non-academic commercial use is restricted.
2. **Check Issues**: Review open issues and pull requests to avoid duplicate work.
3. **Document Your Intent**: For significant changes, open an issue first to discuss the approach.
4. **Follow the Architecture**: Read [ARCHITECTURE.md](./docs/ARCHITECTURE.md) to understand system design.

### Development Standards

#### 1. Code Organization

**Follow the 6-layer architecture**:

```
UI Layer (Screens/Widgets)
    ↓
State Management (Providers)
    ↓
Business Logic (Services)
    ↓
Data Access (Firebase/Storage)
    ↓
Security (Cryptography)
    ↓
External Services (APIs)
```

**File placement**:
- UI components → `lib/screens/` or `lib/widgets/`
- State management → `lib/providers/` (extends ChangeNotifier)
- Business logic → `lib/services/`
- Data models → `lib/models/`
- Configuration → `lib/config/`
- Theme & routing → `lib/theme/`, `lib/routes/`

#### 2. Code Style

**Dart conventions**:
- Follow [Google Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` before commits
- Format code with `dart format lib/` and `dart format test/`
- Maximum line length: 80 characters for comments, 100 for code

**Example**:
```dart
class AccountProvider extends ChangeNotifier {
  // State variables
  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Methods follow business logic sequence
  Future<void> initialize(String userId) async {
    _startListening(userId);
  }

  Future<void> fetchAccounts(String userId) async {
    _isLoading = true;
    try {
      _accounts = await _service.getAccounts(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

#### 3. Null Safety

All code must be null-safe:
- Use `!` operator only when 100% certain
- Prefer `??` and `?.` operators
- Declare types explicitly (no `var` for public members)
- Use `late` sparingly with clear comments

```dart
// ✓ Good
String? getUserName(User user) {
  return user.profile?.name;
}

final value = maybeNull ?? defaultValue;

// ✗ Bad
String getUserName(User user) {
  return user.profile.name; // Can crash if profile is null
}
```

#### 4. Comments & Documentation

Add comments only where code intent is not self-evident:

```dart
// ✓ Good - explains why, not what
/// Kyber key encapsulation with 768-bit security level.
/// Uses NIST standard ML-KEM-768 for quantum-resistant KEM.
Future<KeyEncapsulation> encapsulateKey(List<int> publicKey) async {
  // Implement quantum-safe encapsulation
}

// ✗ Bad - obvious from code
/// Gets the account name
String getAccountName(Account account) {
  return account.name;
}
```

#### 5. Testing

Write tests for:
- Service classes (unit tests)
- Providers (state management tests)
- Complex UI components (widget tests)
- Cryptographic operations (security tests)

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/providers/account_provider_test.dart

# Watch mode
flutter test --watch
```

---

## Git Workflow

### Branch Strategy

- `main`: Production-ready code, tagged releases
- Feature branches: `feature/description` (for new features)
- Bug fixes: `fix/description` (for bug fixes)
- Documentation: `docs/description` (for documentation only)
- Research: `research/description` (for experimental features)

```bash
git checkout -b feature/new-feature
# Make changes
git add .
git commit -m "feat: Add new feature description"
git push origin feature/new-feature
```

### Commit Messages

**Use conventional commits format**:

```
type(scope): description

ADDITIONS:
- What was added

CHANGES:
- What was modified

FIXES:
- What was fixed (if applicable)

BREAKING CHANGES:
- Any breaking changes (if applicable)
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code restructuring
- `test`: Test additions/updates
- `build`: Build configuration
- `ci`: CI/CD configuration
- `perf`: Performance improvements
- `security`: Security improvements

**Example commits**:

```bash
# Small, focused feature
git commit -m "feat(card): Add contactless payment support

ADDITIONS:
- ContactlessBadge widget to display contactless status
- contactlessEnabled property to CardModel
- toggleContactless method in CardProvider

CHANGES:
- Updated CardDetails screen to show contactless status
- Enhanced card display with feature indicators"

# Bug fix
git commit -m "fix(auth): Resolve PIN validation timeout issue

FIXES:
- PIN verification now respects configured timeout (30s)
- Prevents false timeout errors on slow connections
- Added retry mechanism for failed PIN checks

TESTS:
- Added unit tests for PIN timeout scenarios"

# Documentation
git commit -m "docs(architecture): Add provider dependency diagram

ADDITIONS:
- Provider hierarchy visualization in ARCHITECTURE.md
- Sequence diagram for authentication flow
- Initialization lifecycle documentation

CHANGES:
- Reorganized architecture section for clarity"
```

**Commit rules**:
- One logical change per commit
- Write descriptive messages (why, not just what)
- Keep commits small enough to understand in one sitting
- Test before committing (`flutter test && flutter analyze`)
- No Co-Authored-By attributions (single author per commit)

### Pull Request Process

1. **Before submitting PR**:
   ```bash
   flutter analyze
   flutter test
   flutter format lib/ test/
   git status  # Verify only intended changes
   ```

2. **PR Title Format**: Same as commit message
   ```
   feat(scope): Descriptive title
   ```

3. **PR Description**:
   ```markdown
   ## Description
   Brief explanation of changes

   ## Type
   - [ ] New Feature
   - [ ] Bug Fix
   - [ ] Documentation
   - [ ] Architecture Change
   - [ ] Security Enhancement

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added (where needed)
   - [ ] Tests added/updated
   - [ ] Documentation updated
   - [ ] No new warnings from analyzer

   ## Testing
   Describe how changes were tested

   ## Related Issues
   Closes #123
   ```

---

## Architecture & Design Decisions

### Understanding the System

Before making architectural changes, review these documents:

1. **[ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - System design and components
2. **[ADR-001: Post-Quantum Cryptography](./docs/adr/ADR-001-PQC-IMPLEMENTATION.md)** - PQC implementation details
3. **[ADR-002: State Management](./docs/adr/ADR-002-STATE-MANAGEMENT.md)** - Provider pattern rationale
4. **[ADR-003: Security Strategy](./docs/adr/ADR-003-SECURITY-STRATEGY.md)** - Security architecture

### Adding New Features

**Use this checklist**:

1. **Model Layer** (`lib/models/`)
   - Create data model class
   - Implement `toMap()` and `fromMap()` for serialization
   - Add `copyWith()` for immutability

2. **Service Layer** (`lib/services/`)
   - Create service class for business logic
   - Implement Firebase integration (if needed)
   - Add error handling and validation

3. **Provider Layer** (`lib/providers/`)
   - Create ChangeNotifier provider
   - Implement `initialize()` for setup
   - Add real-time listeners (if applicable)
   - Test with mock data first

4. **UI Layer** (`lib/screens/` or `lib/widgets/`)
   - Create screen or widget
   - Use Consumer for state management
   - Add error and loading states
   - Follow Material Design 3

5. **Documentation** (`docs/`)
   - Update ARCHITECTURE.md with new components
   - Update IMPLEMENTATION_OVERVIEW.md with feature list
   - Add ADR if major decision was made
   - Update README.md feature list

**Example structure for new feature "Recurring Transfers"**:

```
lib/models/recurring_transfer_model.dart
lib/services/recurring_transfer_service.dart
lib/providers/recurring_transfer_provider.dart
lib/screens/recurring_transfer_screen.dart
lib/widgets/recurring_transfer_form.dart
test/providers/recurring_transfer_provider_test.dart
test/services/recurring_transfer_service_test.dart
```

### Adding New Providers

When adding a provider, follow this template:

```dart
import 'package:flutter/foundation.dart';
import 'package:bjbank/models/your_model.dart';
import 'package:bjbank/services/your_service.dart';

class YourProvider extends ChangeNotifier {
  final YourService _service = YourService();

  List<YourModel> _items = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<YourModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize provider and start listening to data
  Future<void> initialize(String userId) async {
    _startListening(userId);
  }

  /// Private method to start real-time listening
  void _startListening(String userId) {
    _subscription = _service.streamItems(userId).listen(
      (items) {
        _items = items;
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

Then add to `lib/app.dart` MultiProvider:

```dart
ChangeNotifierProxyProvider<AuthProvider, YourProvider>(
  create: (_) => YourProvider(),
  update: (_, authProvider, yourProvider) {
    if (authProvider.userId != null) {
      yourProvider?.initialize(authProvider.userId!);
    }
    return yourProvider ?? YourProvider();
  },
),
```

---

## Security Considerations

### For Cryptographic Changes

1. **Review NIST Guidelines**:
   - Current: Kyber (ML-KEM-768) + ECDH (secp256r1)
   - Reference: https://csrc.nist.gov/projects/post-quantum-cryptography

2. **Update Documentation**:
   - Explain algorithm choice in ADR
   - Document performance impact
   - Include threat model updates

3. **Performance Testing**:
   ```bash
   # Use pqc_benchmark_screen.dart for cryptographic benchmarks
   ```

4. **Security Review**:
   - No hardcoded secrets or keys
   - Secure key storage only
   - HTTPS/TLS for all network communication
   - Input validation at system boundaries

### For Data Model Changes

When modifying Firestore data models:

1. **Update Firestore Security Rules**:
   - Reference: https://firebase.google.com/docs/rules?hl=pt-br
   - Ensure user isolation
   - Add appropriate read/write permissions

2. **Version Your Models**:
   - Add migration logic if breaking changes
   - Support backwards compatibility
   - Document schema evolution

3. **Update Documentation**:
   - Add to ARCHITECTURE.md data model section
   - Update DEPLOYMENT.md Firestore setup
   - Include schema diagram in ADR if major change

---

## Documentation Updates

### Files to Update for Feature Additions

1. **README.md** - Feature list, statistics
2. **IMPLEMENTATION_OVERVIEW.md** - Detailed feature breakdown
3. **CHANGELOG.md** - Version history
4. **ARCHITECTURE.md** - New components, diagrams
5. **docs/DEPLOYMENT.md** - If Firebase config changes
6. **ADR files** - If architectural decision was made

### Documentation Standards

- Write in English for international audience
- Use clear, concise language
- Include code examples for complex features
- Add diagrams for system changes (use ASCII art or text descriptions)
- No non-professional formatting (emojis, excessive styling)
- Keep tables for structured information
- Link to relevant external documentation

### Diagram Standards

When adding architecture diagrams:

**ASCII Art Format**:
```
┌─────────────────────┐
│   Component Name    │
│                     │
│ - Responsibility 1  │
│ - Responsibility 2  │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  Another Component  │
└─────────────────────┘
```

**Description Format**:
```
Flow: User Action → Provider Method → Service → Firebase
      (UI Interaction) (State Change) (Business Logic) (Data Persistence)
```

---

## Testing Requirements

### Unit Tests

Test all service classes and providers:

```dart
test('CardProvider initializes correctly', () async {
  final mockService = MockCardService();
  final provider = CardProvider(cardService: mockService);

  await provider.initialize('user123');

  expect(provider.cards, isNotEmpty);
  expect(provider.isLoading, isFalse);
  expect(provider.error, isNull);
});
```

Run with:
```bash
flutter test test/providers/card_provider_test.dart
```

### Widget Tests

Test UI components with providers:

```dart
testWidgets('CardListWidget displays cards', (tester) async {
  final provider = CardProvider();

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: CardListWidget()),
    ),
  );

  expect(find.byType(CardListWidget), findsOneWidget);
});
```

### Running All Tests

```bash
# Run all tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

---

## Reporting Issues

### Bug Reports

Include:
- Detailed steps to reproduce
- Expected vs. actual behavior
- Flutter/Dart version
- Platform (Android/iOS/Windows)
- Error message or crash log
- Screenshots if UI-related

**Title format**: `bug(scope): Brief description`

### Security Vulnerabilities

**Do not open public issues for security vulnerabilities**.

Instead, email:
- **Author**: vagneripg@gmail.com
- **Subject**: "[BJBank Security] Vulnerability Report"

Include:
- Vulnerability description
- Affected component
- Proof of concept (if applicable)
- Suggested fix (if you have one)

### Feature Requests

Include:
- Use case and motivation
- Proposed API/UX
- Implementation approach (if you have ideas)
- Related academic research (if applicable)

**Title format**: `feat(scope): Feature description`

---

## Research Extensions

This project is designed for academic research and experimentation.

### Extending for Research

Common extensions:

1. **Alternative PQC Algorithms**:
   - Switch from Kyber to Lattice-based alternatives
   - Experiment with hash-based signatures
   - Compare performance vs. security trade-offs

2. **Hybrid Protocols**:
   - Test different EC curves (P-256, Curve25519, etc.)
   - Implement alternative key derivation functions
   - Measure network overhead of different handshakes

3. **Performance Analysis**:
   - Benchmark PQC operations on different devices
   - Measure battery impact of crypto operations
   - Profile memory usage with large key sizes

4. **Security Analysis**:
   - Side-channel analysis of crypto implementations
   - Formal verification of security properties
   - Threat modeling exercises

### Research Contribution Process

1. Create a research branch: `research/your-experiment`
2. Document approach in research/README.md or ADR
3. Add benchmark results and analysis
4. Submit pull request with findings
5. Include academic references

---

## Contact & Communication

### Getting Help

- **Project Questions**: Open an issue
- **Architecture Discussions**: Create a discussion thread
- **Security Concerns**: Email vagneripg@gmail.com
- **Research Collaboration**: Contact Prof. Rui A. P. Perdigão

### Project Maintainers

| Role | Name | Email | Institution |
|------|------|-------|-------------|
| **Author** | Vagner Bom Jesus | vagneripg@gmail.com | Instituto Politécnico da Guarda |
| **Advisor** | Prof. Rui A. P. Perdigão | - | Instituto Politécnico da Guarda |

### Citation

If you use this project in academic work, please cite:

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

## Code of Conduct

### Be Respectful

- Treat all contributors with respect
- Provide constructive feedback
- Assume good intentions
- Be open to learning from others

### Be Professional

- Use English in public discussions
- Keep conversations focused and on-topic
- No harassment, discrimination, or inappropriate language
- Address conflicts privately with maintainers

### Academic Integrity

- Give credit for others' work
- Cite sources and references
- Disclose conflicts of interest
- Follow institutional guidelines

---

## Acknowledgments

This project is supported by:

- **Flutter** and **Dart** community
- **Firebase** for backend infrastructure
- **Open Quantum Safe Organization** (libOQS)
- **NIST** Post-Quantum Cryptography Standardization Project
- Instituto Politécnico da Guarda research community

---

## Resources

### Official Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Guide](https://dart.dev/guides)
- [Firebase Documentation](https://firebase.google.com/docs)
- [NIST PQC](https://csrc.nist.gov/projects/post-quantum-cryptography)

### Project Documentation

- [README.md](./README.md) - Project overview
- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - System architecture
- [DEPLOYMENT.md](./docs/DEPLOYMENT.md) - Deployment guide
- [CHANGELOG.md](./CHANGELOG.md) - Version history
- [LICENSE](./LICENSE) - License terms

### Learning Resources

- [Provider Package](https://pub.dev/packages/provider)
- [Firebase Security Rules](https://firebase.google.com/docs/rules?hl=pt-br)
- [libOQS Documentation](https://liboqs.org/)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-top-10/)

---

**Last Updated**: 18 April 2026
**Project Status**: Academic Research - Master's Dissertation
**License**: Academic Research License (see [LICENSE](./LICENSE))
