import 'package:flutter/material.dart';
import '../theme/durations.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/pin_screen.dart';
import '../screens/transfer/transfer_screen.dart';
import '../screens/transfer/mbway_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/seed_screen.dart';
import '../screens/settings/help_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/inbox_screen.dart';
import '../screens/settings/documents_screen.dart';
import '../screens/settings/invite_friends_screen.dart';
import '../screens/settings/account_details_screen.dart';
import '../screens/settings/privacy_screen.dart';
import '../screens/settings/mbway_settings_screen.dart';
import '../screens/settings/mbway_phone_verification_screen.dart';
import '../screens/analysis/analysis_screen.dart';
import '../screens/deposit/deposit_screen.dart';
import '../screens/deposit/bank_selection_screen.dart';
import '../screens/deposit/linked_accounts_screen.dart';
import 'app_routes.dart';

/// BJBank App Router
/// Handles all route generation and navigation
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Initial routes
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.onboarding:
        return _buildFadeRoute(
          const OnboardingScreen(),
          settings,
        );

      // Auth routes
      case AppRoutes.login:
        return _buildFadeRoute(
          const LoginScreen(),
          settings,
        );

      case AppRoutes.register:
        return _buildSlideRoute(
          const RegisterScreen(),
          settings,
        );

      case AppRoutes.forgotPassword:
        return _buildSlideRoute(
          const ForgotPasswordScreen(),
          settings,
        );

      case AppRoutes.pinSetup:
        return _buildFadeRoute(
          const PinSetupScreen(),
          settings,
        );

      case AppRoutes.pinVerify:
        return _buildFadeRoute(
          const PinVerifyScreen(),
          settings,
        );

      // Main routes
      case AppRoutes.home:
        return _buildFadeRoute(
          const HomeScreen(),
          settings,
        );

      // Transfer routes
      case AppRoutes.transfer:
        return _buildSlideRoute(
          const TransferScreen(),
          settings,
        );

      case AppRoutes.mbway:
        return _buildSlideRoute(
          const MbWayScreen(),
          settings,
        );

      // Dev routes
      case AppRoutes.seedData:
        return _buildSlideRoute(
          const SeedScreen(),
          settings,
        );

      // Profile route
      case AppRoutes.profile:
        return _buildSlideRoute(
          const ProfileScreen(),
          settings,
        );

      // Settings sub-routes
      case AppRoutes.help:
        return _buildSlideRoute(
          const HelpScreen(),
          settings,
        );

      case AppRoutes.about:
        return _buildSlideRoute(
          const AboutScreen(),
          settings,
        );

      case AppRoutes.inbox:
        return _buildSlideRoute(
          const InboxScreen(),
          settings,
        );

      case AppRoutes.documents:
        return _buildSlideRoute(
          const DocumentsScreen(),
          settings,
        );

      case AppRoutes.inviteFriends:
        return _buildSlideRoute(
          const InviteFriendsScreen(),
          settings,
        );

      case AppRoutes.analysis:
        return _buildSlideRoute(
          const AnalysisScreen(),
          settings,
        );

      case AppRoutes.accountDetails:
        return _buildSlideRoute(
          const AccountDetailsScreen(),
          settings,
        );

      case AppRoutes.privacy:
        return _buildSlideRoute(
          const PrivacyScreen(),
          settings,
        );

      case AppRoutes.mbwaySettings:
        return _buildSlideRoute(
          const MbWaySettingsScreen(),
          settings,
        );

      case AppRoutes.mbwayPhoneVerification:
        final initialPhone = settings.arguments as String?;
        return _buildSlideRoute(
          MbWayPhoneVerificationScreen(initialPhone: initialPhone),
          settings,
        );

      // Deposit routes (Open Banking)
      case AppRoutes.deposit:
        return _buildSlideRoute(
          const DepositScreen(),
          settings,
        );

      case AppRoutes.bankSelection:
        return _buildSlideRoute(
          const BankSelectionScreen(),
          settings,
        );

      case AppRoutes.linkedAccounts:
        return _buildSlideRoute(
          const LinkedAccountsScreen(),
          settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Página não encontrada',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.name ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          settings: settings,
        );
    }
  }

  /// Build a fade transition route
  static PageRoute<T> _buildFadeRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: BJBankDurations.pageTransition,
      reverseTransitionDuration: BJBankDurations.pageTransition,
      settings: settings,
    );
  }

  /// Build a slide transition route (from right)
  static PageRoute<T> _buildSlideRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: BJBankDurations.slideIn,
      reverseTransitionDuration: BJBankDurations.slideIn,
      settings: settings,
    );
  }
}
