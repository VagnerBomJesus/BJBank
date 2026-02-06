import 'package:flutter/material.dart';
import '../theme/app_strings.dart';

/// Onboarding Page Data Model
class OnboardingPageModel {
  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.imagePath,
    this.icon,
  });

  final String title;
  final String description;
  final String imagePath;
  final IconData? icon; // Fallback icon when image is not available

  /// Check if image asset exists, otherwise use placeholder
  bool get hasImage => imagePath.isNotEmpty;
}

/// Pre-defined onboarding pages (Portuguese/European version)
class OnboardingData {
  OnboardingData._();

  static const List<OnboardingPageModel> pages = [
    // Page 1: Welcome
    OnboardingPageModel(
      title: AppStrings.onboarding1Title,
      description: AppStrings.onboarding1Description,
      imagePath: AppStrings.onboarding1Image,
      icon: Icons.account_balance_rounded,
    ),
    // Page 2: Quantum Security
    OnboardingPageModel(
      title: AppStrings.onboarding2Title,
      description: AppStrings.onboarding2Description,
      imagePath: AppStrings.onboarding2Image,
      icon: Icons.shield_rounded,
    ),
    // Page 3: Easy Transactions
    OnboardingPageModel(
      title: AppStrings.onboarding3Title,
      description: AppStrings.onboarding3Description,
      imagePath: AppStrings.onboarding3Image,
      icon: Icons.payments_rounded,
    ),
    // Page 4: Get Started
    OnboardingPageModel(
      title: AppStrings.onboarding4Title,
      description: AppStrings.onboarding4Description,
      imagePath: AppStrings.onboarding4Image,
      icon: Icons.rocket_launch_rounded,
    ),
  ];
}
