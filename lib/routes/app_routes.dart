/// BJBank Route Names
class AppRoutes {
  AppRoutes._();

  // Initial routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String pinSetup = '/pin-setup';
  static const String pinVerify = '/pin-verify';

  // Main routes
  static const String home = '/home';
  static const String history = '/history';
  static const String cards = '/cards';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // Settings sub-routes
  static const String help = '/help';
  static const String about = '/about';
  static const String inbox = '/inbox';
  static const String documents = '/documents';
  static const String inviteFriends = '/invite-friends';
  static const String analysis = '/analysis';
  static const String accountDetails = '/account-details';
  static const String privacy = '/privacy';
  static const String mbwaySettings = '/settings/mbway';
  static const String mbwayPhoneVerification = '/settings/mbway/verify-phone';

  // Dev routes
  static const String seedData = '/seed-data';

  // Transfer routes
  static const String transfer = '/transfer';
  static const String mbway = '/mbway';
  static const String pay = '/pay';
  static const String qrCode = '/qr-code';

  // Deposit routes (Open Banking)
  static const String deposit = '/deposit';
  static const String bankSelection = '/deposit/bank-selection';
  static const String bankAuth = '/deposit/bank-auth';
  static const String linkedAccounts = '/deposit/linked-accounts';
  static const String depositAmount = '/deposit/amount';
  static const String depositConfirmation = '/deposit/confirmation';
  static const String depositReceipt = '/deposit/receipt';
}
