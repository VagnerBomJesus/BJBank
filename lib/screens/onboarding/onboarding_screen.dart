import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/durations.dart';
import '../../theme/app_strings.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../models/onboarding_page_model.dart';
import '../../widgets/animated_bubbles.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_indicator.dart';

/// Onboarding Screen
/// Introduces the app features with swipeable pages and animations
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScale;
  late Animation<double> _buttonFade;

  bool get _isLastPage => _currentPage == OnboardingData.pages.length - 1;

  @override
  void initState() {
    super.initState();

    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimController,
        curve: Curves.easeOutBack,
      ),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimController,
        curve: Curves.easeOut,
      ),
    );

    // Delay button animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buttonAnimController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: BJBankDurations.pageTransition,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: BJBankDurations.pageTransition,
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    await StorageService.setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated Bubbles Background - always primary color
          const AnimatedBubbles(
            bubbleCount: 12,
            color: BJBankColors.primary,
          ),

          // Decorative gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    BJBankColors.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: AnimatedOpacity(
                      opacity: _isLastPage ? 0.0 : 1.0,
                      duration: BJBankDurations.fast,
                      child: TextButton(
                        onPressed: _isLastPage ? null : _skipOnboarding,
                        child: Text(
                          AppStrings.onboardingSkip,
                          style: TextStyle(
                            color: BJBankColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Page Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: OnboardingData.pages.length,
                    itemBuilder: (context, index) {
                      return OnboardingPage(
                        page: OnboardingData.pages[index],
                        isActive: index == _currentPage,
                      );
                    },
                  ),
                ),

                // Page Indicator - always primary color
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: BJBankSpacing.lg,
                  ),
                  child: PageIndicator(
                    pageCount: OnboardingData.pages.length,
                    currentPage: _currentPage,
                    activeColor: BJBankColors.primary,
                  ),
                ),

                // Navigation Buttons
                AnimatedBuilder(
                  animation: _buttonAnimController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonScale.value,
                      child: Opacity(
                        opacity: _buttonFade.value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BJBankSpacing.lg,
                      vertical: BJBankSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        // Back Button
                        AnimatedOpacity(
                          opacity: _currentPage > 0 ? 1.0 : 0.0,
                          duration: BJBankDurations.fast,
                          child: AnimatedScale(
                            scale: _currentPage > 0 ? 1.0 : 0.8,
                            duration: BJBankDurations.fast,
                            child: IconButton(
                              onPressed: _currentPage > 0 ? _previousPage : null,
                              icon: const Icon(Icons.arrow_back_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: BJBankColors.surfaceVariant,
                                foregroundColor: BJBankColors.onSurfaceVariant,
                                minimumSize: const Size(48, 48),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Next / Get Started Button - always primary color
                        FilledButton(
                          onPressed: _nextPage,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(160, 52),
                            backgroundColor: BJBankColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: BJBankDurations.fast,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.3),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  _isLastPage
                                      ? AppStrings.onboardingStart
                                      : AppStrings.onboardingNext,
                                  key: ValueKey(_isLastPage),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: BJBankSpacing.sm),
                              AnimatedSwitcher(
                                duration: BJBankDurations.fast,
                                transitionBuilder: (child, animation) {
                                  return RotationTransition(
                                    turns: Tween<double>(begin: 0.5, end: 1.0)
                                        .animate(animation),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Icon(
                                  _isLastPage
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  key: ValueKey('icon_$_isLastPage'),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: BJBankSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
