import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/durations.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../theme/app_strings.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';

/// Splash Screen
/// White background, blue-turquoise organic shapes (top-right & bottom-left),
/// centered BJ logo with fade+scale animation and animated loading
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingFadeAnimation;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Loading fade-in (aparece após um pequeno delay)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeOut),
    );

    // Pulse animation for the loading dots
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Show loading after a small delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadingController.forward();
    });

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(BJBankDurations.splashNavigationDelay);

    if (!mounted) return;

    final hasSeenOnboarding = await StorageService.hasSeenOnboarding();
    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    final isLoggedIn = AuthService.isLoggedIn;
    if (!isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    final hasPinSet = await SecureStorageService.isPinSet();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      hasPinSet ? AppRoutes.pinVerify : AppRoutes.pinSetup,
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Top-right decorative shapes ──
          const Positioned(
            top: -50,
            right: -50,
            child: _DecorativeShapes(isTop: true),
          ),

          // ── Bottom-left decorative shapes (mirrored) ──
          const Positioned(
            bottom: -50,
            left: -50,
            child: _DecorativeShapes(isTop: false),
          ),

          // ── Centered logo + info + loading ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo from assets (sem animação)
                Image.asset(
                  AppStrings.logoAsset,
                  width: 440,
                  height: 440,
                ),

                const SizedBox(height: BJBankSpacing.xs),

                // Tagline
                Text(
                  AppStrings.appTagline,
                  style: BJBankTypography.bodyMedium.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: BJBankSpacing.xxl),

                // Animated loading indicator
                FadeTransition(
                  opacity: _loadingFadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedLoadingDots(
                        controller: _pulseController,
                      ),
                      const SizedBox(height: BJBankSpacing.sm),
                      Text(
                        AppStrings.splashLoading,
                        style: BJBankTypography.bodySmall.copyWith(
                          color: BJBankColors.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated loading dots with staggered bounce effect
class _AnimatedLoadingDots extends StatelessWidget {
  const _AnimatedLoadingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Stagger each dot by 0.2
            final delay = index * 0.2;
            final value = (controller.value + delay) % 1.0;
            // Sine wave for smooth bounce
            final bounce = math.sin(value * math.pi);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -bounce * 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        BJBankColors.info.withValues(alpha: 0.6 + bounce * 0.4),
                        BJBankColors.quantum
                            .withValues(alpha: 0.6 + bounce * 0.4),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Decorative organic shapes with blue-turquoise gradient
/// [isTop] = true: top-right corner, false: bottom-left (mirrored)
class _DecorativeShapes extends StatelessWidget {
  const _DecorativeShapes({required this.isTop});

  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        children: [
          // Large circle
          Positioned(
            top: isTop ? 60 : null,
            bottom: isTop ? null : 60,
            right: isTop ? 30 : null,
            left: isTop ? null : 30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BJBankColors.info.withValues(alpha: 0.85),
                    BJBankColors.quantum.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // Elongated pill shape
          Positioned(
            top: isTop ? 20 : null,
            bottom: isTop ? null : 20,
            right: isTop ? 90 : null,
            left: isTop ? null : 90,
            child: Transform.rotate(
              angle: isTop ? -0.5 : 0.5,
              child: Container(
                width: 130,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      BJBankColors.quantum.withValues(alpha: 0.8),
                      BJBankColors.info.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Small circle
          Positioned(
            top: isTop ? 10 : null,
            bottom: isTop ? null : 10,
            right: isTop ? 10 : null,
            left: isTop ? null : 10,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    BJBankColors.info.withValues(alpha: 0.85),
                    BJBankColors.quantum.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // Extra fluid blob
          Positioned(
            top: isTop ? 90 : null,
            bottom: isTop ? null : 90,
            right: isTop ? 120 : null,
            left: isTop ? null : 120,
            child: Transform.rotate(
              angle: isTop ? 0.3 : -0.3,
              child: Container(
                width: 70,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      BJBankColors.info.withValues(alpha: 0.6),
                      BJBankColors.quantum.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
