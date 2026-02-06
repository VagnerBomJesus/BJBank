import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/durations.dart';
import '../../../theme/border_radius.dart';

/// Page Indicator Widget
/// Animated dots showing current page in onboarding
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.activeColor,
  });

  final int pageCount;
  final int currentPage;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => _buildDot(index),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == currentPage;
    final color = activeColor ?? BJBankColors.primary;

    return AnimatedContainer(
      duration: BJBankDurations.normal,
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: BJBankSpacing.xxs),
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? color : BJBankColors.outline.withValues(alpha: 0.3),
        borderRadius: BJBankBorderRadius.fullRadius,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}
