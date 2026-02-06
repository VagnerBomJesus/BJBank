import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Animated bubbles background effect
/// Creates floating water bubble effect
class AnimatedBubbles extends StatefulWidget {
  const AnimatedBubbles({
    super.key,
    this.bubbleCount = 15,
    this.color,
  });

  final int bubbleCount;
  final Color? color;

  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles>
    with TickerProviderStateMixin {
  late List<_Bubble> _bubbles;
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _initBubbles();
  }

  void _initBubbles() {
    final random = Random();
    _bubbles = [];
    _controllers = [];

    for (int i = 0; i < widget.bubbleCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 3000 + random.nextInt(4000)),
        vsync: this,
      );

      _controllers.add(controller);

      _bubbles.add(_Bubble(
        x: random.nextDouble(),
        startY: 1.0 + random.nextDouble() * 0.3,
        size: 20 + random.nextDouble() * 60,
        opacity: 0.1 + random.nextDouble() * 0.2,
        wobbleOffset: random.nextDouble() * 2 * pi,
        wobbleSpeed: 1 + random.nextDouble() * 2,
      ));

      // Start with random delay
      Future.delayed(Duration(milliseconds: random.nextInt(2000)), () {
        if (mounted) {
          controller.repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? BJBankColors.info;

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(_bubbles.length, (index) {
            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                final bubble = _bubbles[index];
                final progress = _controllers[index].value;

                // Bubble rises from bottom to top
                final y = bubble.startY - (progress * 1.5);

                // Horizontal wobble effect
                final wobble = sin(progress * bubble.wobbleSpeed * 2 * pi +
                        bubble.wobbleOffset) *
                    0.03;
                final x = bubble.x + wobble;

                // Fade out as it reaches top
                final fadeProgress = progress > 0.7 ? (1 - progress) / 0.3 : 1.0;

                return Positioned(
                  left: x * MediaQuery.of(context).size.width,
                  top: y * MediaQuery.of(context).size.height,
                  child: Opacity(
                    opacity: bubble.opacity * fadeProgress,
                    child: Container(
                      width: bubble.size,
                      height: bubble.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            baseColor.withValues(alpha: 0.3),
                            baseColor.withValues(alpha: 0.1),
                            baseColor.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        border: Border.all(
                          color: baseColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _Bubble {
  const _Bubble({
    required this.x,
    required this.startY,
    required this.size,
    required this.opacity,
    required this.wobbleOffset,
    required this.wobbleSpeed,
  });

  final double x;
  final double startY;
  final double size;
  final double opacity;
  final double wobbleOffset;
  final double wobbleSpeed;
}
