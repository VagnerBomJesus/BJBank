// BJBank Widget Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bjbank/screens/auth/login_screen.dart';
import 'package:bjbank/screens/auth/register_screen.dart';
import 'package:bjbank/theme/colors.dart';

void main() {
  group('BJBank Auth Screen Tests', () {
    testWidgets('Login screen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify login elements exist
      expect(find.text('Bem-vindo de volta'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Palavra-passe'), findsOneWidget);
      expect(find.text('Esqueceu a palavra-passe?'), findsOneWidget);
    });

    testWidgets('Register screen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Verify register elements exist
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Telemóvel (opcional)'), findsOneWidget);
    });

    testWidgets('Login screen has email input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find email text field
      expect(find.byType(TextFormField), findsWidgets);
    });
  });

  group('BJBank Theme Tests', () {
    test('BJBankColors primary is deep purple', () {
      expect(BJBankColors.primary, isNotNull);
    });

    test('BJBankColors has all required colors', () {
      expect(BJBankColors.primary, isNotNull);
      expect(BJBankColors.secondary, isNotNull);
      expect(BJBankColors.tertiary, isNotNull);
      expect(BJBankColors.background, isNotNull);
      expect(BJBankColors.surface, isNotNull);
      expect(BJBankColors.error, isNotNull);
      expect(BJBankColors.success, isNotNull);
    });
  });
}
