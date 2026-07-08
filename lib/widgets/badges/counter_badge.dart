import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Badge Shape
enum BadgeShape {
  circle,           // Círculo
  roundedRectangle, // Rectângulo arredondado
  rectangle,        // Rectângulo
}

/// Badge Size
enum BadgeSize {
  small,    // 16px
  medium,   // 20px
  large,    // 28px
}

/// Counter Badge Widget
///
/// Exibe um badge com contador para items (faturas vencidas, alertas, etc).
/// Suporta múltiplas formas, tamanhos e cores.
///
/// Exemplo:
/// ```dart
/// CounterBadge(
///   count: 5,
///   color: Colors.red,
/// )
/// ```
class CounterBadge extends StatefulWidget {
  const CounterBadge({
    super.key,
    required this.count,
    this.color = BJBankColors.error,
    this.textColor = Colors.white,
    this.size = BadgeSize.medium,
    this.shape = BadgeShape.circle,
    this.maxCount = 99,
  });

  /// Número a exibir
  final int count;

  /// Cor de background
  final Color color;

  /// Cor do texto
  final Color textColor;

  /// Tamanho do badge
  final BadgeSize size;

  /// Formato do badge
  final BadgeShape shape;

  /// Máximo a exibir (ex: 99 → "99+")
  final int maxCount;

  @override
  State<CounterBadge> createState() => _CounterBadgeState();
}

class _CounterBadgeState extends State<CounterBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(CounterBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Anima quando count muda
    if (oldWidget.count != widget.count) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  /// Retorna tamanho em pixels
  double _getSizeInPixels() {
    switch (widget.size) {
      case BadgeSize.small:
        return 16;
      case BadgeSize.medium:
        return 20;
      case BadgeSize.large:
        return 28;
    }
  }

  /// Retorna font size
  double _getFontSize() {
    switch (widget.size) {
      case BadgeSize.small:
        return 10;
      case BadgeSize.medium:
        return 12;
      case BadgeSize.large:
        return 14;
    }
  }

  /// Retorna padding
  EdgeInsets _getPadding() {
    switch (widget.size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 3, vertical: 2);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 4, vertical: 2);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
    }
  }

  /// Retorna border radius
  BorderRadius _getBorderRadius(double size) {
    switch (widget.shape) {
      case BadgeShape.circle:
        return BorderRadius.circular(size / 2);
      case BadgeShape.roundedRectangle:
        return BorderRadius.circular(size / 3);
      case BadgeShape.rectangle:
        return BorderRadius.circular(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    final size = _getSizeInPixels();
    final displayCount = widget.count > widget.maxCount
        ? '${widget.maxCount}+'
        : '${widget.count}';

    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
        constraints: BoxConstraints(
          minWidth: widget.shape == BadgeShape.circle ? size : size - 4,
          minHeight: size,
        ),
        padding: _getPadding(),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: _getBorderRadius(size),
        ),
        child: Center(
          child: Text(
            displayCount,
            style: TextStyle(
              color: widget.textColor,
              fontSize: _getFontSize(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge com Label opcional
///
/// Exemplo:
/// ```dart
/// CounterBadgeWithLabel(
///   count: 5,
///   label: 'Vencidas',
/// )
/// ```
class CounterBadgeWithLabel extends StatelessWidget {
  const CounterBadgeWithLabel({
    super.key,
    required this.count,
    required this.label,
    this.color = BJBankColors.error,
    this.textColor = Colors.white,
    this.size = BadgeSize.medium,
  });

  final int count;
  final String label;
  final Color color;
  final Color textColor;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CounterBadge(
          count: count,
          color: color,
          textColor: textColor,
          size: size,
        ),
        const SizedBox(height: BJBankSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Inline Badge com contador e label
///
/// Exemplo:
/// ```dart
/// InlineCounterBadge(
///   count: 3,
///   label: 'Alertas',
/// )
/// ```
class InlineCounterBadge extends StatelessWidget {
  const InlineCounterBadge({
    super.key,
    required this.count,
    required this.label,
    this.color = BJBankColors.error,
    this.backgroundColor,
  });

  final int count;
  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.sm,
        vertical: BJBankSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(BJBankSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(BJBankSpacing.xs),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
