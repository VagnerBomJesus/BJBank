import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/account_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/deposit_provider.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

/// BJBank App Widget
/// Root widget of the application
class BJBankApp extends StatelessWidget {
  const BJBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => DepositProvider()),
      ],
      child: MaterialApp(
        title: 'BJBank',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
