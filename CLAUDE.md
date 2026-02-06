# BJBank

A Flutter mobile banking application for Post-Quantum Cryptography research.

## Tech Stack

- **Framework**: Flutter (Dart SDK ^3.8.1)
- **Platforms**: iOS, Android, Windows
- **Linting**: flutter_lints ^5.0.0

## Project Structure

```
lib/           # Dart source code
  main.dart    # App entry point
test/          # Widget and unit tests
android/       # Android platform files
ios/           # iOS platform files
```

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Build release
flutter build apk        # Android
flutter build ios        # iOS
flutter build windows    # Windows
```

## Development Notes

- Uses Material Design (`uses-material-design: true`)
- Default theme uses `Colors.deepPurple` as seed color
- Hot reload supported for rapid development
- Focus on Post-Quantum Cryptography (PQC) implementation
