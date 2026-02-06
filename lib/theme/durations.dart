/// BJBank Design System Animation Durations
class BJBankDurations {
  BJBankDurations._();

  // Base durations
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration slower = Duration(milliseconds: 500);

  // Specific animations
  static const Duration splash = Duration(milliseconds: 2500);
  static const Duration splashLogo = Duration(milliseconds: 1000);
  static const Duration splashText = Duration(milliseconds: 500);
  static const Duration splashBadge = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration fadeIn = Duration(milliseconds: 200);
  static const Duration slideIn = Duration(milliseconds: 300);

  // Delays
  static const Duration splashTextDelay = Duration(milliseconds: 500);
  static const Duration splashBadgeDelay = Duration(milliseconds: 800);
  static const Duration splashNavigationDelay = Duration(milliseconds: 3500);
}
