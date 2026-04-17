import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/account_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/deposit_provider.dart';
import 'providers/card_provider.dart';
import 'providers/transfer_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/mbway_provider.dart';
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
        ChangeNotifierProxyProvider<AuthProvider, CardProvider>(
          create: (_) => CardProvider(),
          update: (_, authProvider, cardProvider) {
            if (authProvider.userId != null) {
              cardProvider?.initialize(authProvider.userId!);
            }
            return cardProvider ?? CardProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransferProvider>(
          create: (_) => TransferProvider(),
          update: (_, authProvider, transferProvider) {
            if (authProvider.userId != null) {
              transferProvider?.initialize(authProvider.userId!);
            }
            return transferProvider ?? TransferProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, BillProvider>(
          create: (_) => BillProvider(),
          update: (_, authProvider, billProvider) {
            if (authProvider.userId != null) {
              billProvider?.initialize(authProvider.userId!);
            }
            return billProvider ?? BillProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, MbWayProvider>(
          create: (_) => MbWayProvider(),
          update: (_, authProvider, mbwayProvider) {
            if (authProvider.userId != null) {
              mbwayProvider?.initialize(authProvider.userId!);
            }
            return mbwayProvider ?? MbWayProvider();
          },
        ),
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
