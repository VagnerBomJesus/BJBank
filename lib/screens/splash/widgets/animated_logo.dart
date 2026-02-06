import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Animated BJBank Logo Widget
/// Used in splash screen with scale and fade animations
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    required this.scaleAnimation,
    required this.opacityAnimation,
  });

  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: opacityAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: BJBankColors.onPrimary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield,
                size: BJBankSpacing.iconXxl,
                color: BJBankColors.onPrimary,
              ),
            ),
            const SizedBox(height: BJBankSpacing.lg),
            // BJBank Text
            Text(
              'BJBank',
              style: BJBankTypography.displaySmall.copyWith(
                color: BJBankColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: BJBankSpacing.xs),
            // Tagline
            Text(
              'Quantum Security',
              style: BJBankTypography.bodyMedium.copyWith(
                color: BJBankColors.onPrimary.withOpacity(0.8),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
