import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../models/onboarding_page_model.dart';

/// Onboarding Page Content Widget
/// Displays image/icon, title, and description with animations
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.page,
    required this.isActive,
  });

  final OnboardingPageModel page;
  final bool isActive;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _imageScale;
  late Animation<double> _imageFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _descSlide;
  late Animation<double> _descFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _imageScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _imageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _descSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _descFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or Placeholder
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _imageScale.value,
                child: Opacity(
                  opacity: _imageFade.value,
                  child: child,
                ),
              );
            },
            child: _buildImageOrPlaceholder(),
          ),

          const SizedBox(height: BJBankSpacing.xxl),

          // Title with slide animation
          SlideTransition(
            position: _titleSlide,
            child: FadeTransition(
              opacity: _titleFade,
              child: Text(
                widget.page.title,
                style: BJBankTypography.headlineMedium.copyWith(
                  color: BJBankColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.md),

          // Description with slide animation
          SlideTransition(
            position: _descSlide,
            child: FadeTransition(
              opacity: _descFade,
              child: Text(
                widget.page.description,
                style: BJBankTypography.bodyLarge.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOrPlaceholder() {
    // Try to load image, fallback to placeholder with icon
    return FutureBuilder<bool>(
      future: _checkImageExists(),
      builder: (context, snapshot) {
        final imageExists = snapshot.data ?? false;

        if (imageExists) {
          return Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: BJBankColors.primary.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                widget.page.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
              ),
            ),
          );
        }

        return _buildPlaceholder();
      },
    );
  }

  Future<bool> _checkImageExists() async {
    try {
      await DefaultAssetBundle.of(context).load(widget.page.imagePath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BJBankColors.primary.withValues(alpha: 0.9),
            BJBankColors.primary,
            BJBankColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: BJBankColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Icon(
        widget.page.icon ?? Icons.image_rounded,
        size: 80,
        color: Colors.white,
      ),
    );
  }
}
