import 'package:flutter/material.dart';
import '../../theme/spacing.dart';

/// Priority Level Enum
///
/// Represents priority levels for tasks, goals, and alerts.
enum PriorityLevel {
  low,      // Low - Verde #4CAF50
  medium,   // Medium - Laranja #FF9800
  high,     // High - Vermelho #F44336
  critical, // Critical - Vermelho intenso #B71C1C
}

/// Priority Badge Widget
///
/// Displays priority level for tasks, goals, reminders, and alerts.
/// Used in savings goals, bill alerts, and task management.
///
/// Features:
/// - 4 priority levels with semantic colors
/// - Compact (icon only) and full (icon + label) variants
/// - Portuguese priority labels
/// - Dark theme support
/// - Accessibility labels
///
/// Exemplo:
/// ```dart
/// // Compact version for inline display
/// PriorityBadge(level: PriorityLevel.high, compact: true)
///
/// // Full version with label
/// PriorityBadge(level: PriorityLevel.critical)
/// ```
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.level,
    this.compact = false,
    this.showLabel = true,
  });

  /// Priority level
  final PriorityLevel level;

  /// Use compact size (icon only)
  final bool compact;

  /// Show priority label
  final bool showLabel;

  /// Get color for priority level
  Color _getColor() {
    switch (level) {
      case PriorityLevel.low:
        return Colors.green; // #4CAF50
      case PriorityLevel.medium:
        return Colors.orange; // #FF9800
      case PriorityLevel.high:
        return Colors.red; // #F44336
      case PriorityLevel.critical:
        return const Color(0xFFB71C1C); // #B71C1C - Dark red
    }
  }

  /// Get icon for priority level
  IconData _getIcon() {
    switch (level) {
      case PriorityLevel.low:
        return Icons.arrow_downward_outlined;
      case PriorityLevel.medium:
        return Icons.arrow_forward_outlined;
      case PriorityLevel.high:
        return Icons.arrow_upward_outlined;
      case PriorityLevel.critical:
        return Icons.priority_high;
    }
  }

  /// Get label in Portuguese
  String _getLabel() {
    switch (level) {
      case PriorityLevel.low:
        return 'Baixa';
      case PriorityLevel.medium:
        return 'Média';
      case PriorityLevel.high:
        return 'Alta';
      case PriorityLevel.critical:
        return 'Crítica';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  /// Build compact version - icon only
  Widget _buildCompact(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColor();

    return Tooltip(
      message: _getLabel(),
      child: Semantics(
        label: '${_getLabel()} Prioridade',
        button: true,
        child: Container(
          padding: const EdgeInsets.all(BJBankSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: isDark ? 0.2 : 0.15,
            ),
            borderRadius: BorderRadius.circular(BJBankSpacing.sm),
          ),
          child: Icon(
            _getIcon(),
            size: 14,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Build full version - icon + label
  Widget _buildFull(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColor();

    return Tooltip(
      message: 'Prioridade ${_getLabel()}',
      child: Semantics(
        label: '${_getLabel()} Prioridade',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BJBankSpacing.sm,
            vertical: BJBankSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: isDark ? 0.2 : 0.15,
            ),
            border: Border.all(
              color: color.withValues(
                alpha: isDark ? 0.5 : 0.3,
              ),
            ),
            borderRadius: BorderRadius.circular(BJBankSpacing.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(),
                size: 14,
                color: color,
              ),
              if (showLabel) ...[
                const SizedBox(width: BJBankSpacing.xs),
                Text(
                  _getLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Priority Indicator (star-based)
///
/// Visual representation using star icons for priority levels.
/// Up to 4 stars for critical priority, down to 1 for low.
///
/// Exemplo:
/// ```dart
/// PriorityIndicator(level: PriorityLevel.high)
/// ```
class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({
    super.key,
    required this.level,
  });

  final PriorityLevel level;

  /// Get color for priority level
  Color _getColor() {
    switch (level) {
      case PriorityLevel.low:
        return Colors.green;
      case PriorityLevel.medium:
        return Colors.orange;
      case PriorityLevel.high:
        return Colors.red;
      case PriorityLevel.critical:
        return const Color(0xFFB71C1C);
    }
  }

  /// Get number of stars
  int _getStarCount() {
    switch (level) {
      case PriorityLevel.low:
        return 1;
      case PriorityLevel.medium:
        return 2;
      case PriorityLevel.high:
        return 3;
      case PriorityLevel.critical:
        return 4;
    }
  }

  /// Get label in Portuguese
  String _getLabel() {
    switch (level) {
      case PriorityLevel.low:
        return 'Baixa';
      case PriorityLevel.medium:
        return 'Média';
      case PriorityLevel.high:
        return 'Alta';
      case PriorityLevel.critical:
        return 'Crítica';
    }
  }

  @override
  Widget build(BuildContext context) {
    final starCount = _getStarCount();
    final color = _getColor();

    return Tooltip(
      message: 'Prioridade ${_getLabel()}',
      child: Semantics(
        label: '${_getLabel()} Prioridade',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(
              starCount,
              (index) => Icon(
                Icons.star,
                size: 14,
                color: color,
              ),
            ),
            ...List.generate(
              4 - starCount,
              (index) => Icon(
                Icons.star_outline,
                size: 14,
                color: color.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Priority Pill Badge
///
/// Pill-shaped badge with priority level and optional label.
///
/// Exemplo:
/// ```dart
/// PriorityPillBadge(level: PriorityLevel.critical)
/// ```
class PriorityPillBadge extends StatelessWidget {
  const PriorityPillBadge({
    super.key,
    required this.level,
    this.label,
  });

  final PriorityLevel level;
  final String? label;

  /// Get color for priority level
  Color _getColor() {
    switch (level) {
      case PriorityLevel.low:
        return Colors.green;
      case PriorityLevel.medium:
        return Colors.orange;
      case PriorityLevel.high:
        return Colors.red;
      case PriorityLevel.critical:
        return const Color(0xFFB71C1C);
    }
  }

  /// Get icon for priority level
  IconData _getIcon() {
    switch (level) {
      case PriorityLevel.low:
        return Icons.arrow_downward_outlined;
      case PriorityLevel.medium:
        return Icons.arrow_forward_outlined;
      case PriorityLevel.high:
        return Icons.arrow_upward_outlined;
      case PriorityLevel.critical:
        return Icons.priority_high;
    }
  }

  /// Get label in Portuguese
  String _getLabel() {
    switch (level) {
      case PriorityLevel.low:
        return 'Baixa';
      case PriorityLevel.medium:
        return 'Média';
      case PriorityLevel.high:
        return 'Alta';
      case PriorityLevel.critical:
        return 'Crítica';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColor();
    final displayLabel = label ?? _getLabel();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.sm,
        vertical: BJBankSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: isDark ? 0.2 : 0.15,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: isDark ? 0.5 : 0.3,
          ),
        ),
        borderRadius: BorderRadius.circular(BJBankSpacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 13,
            color: color,
          ),
          const SizedBox(width: BJBankSpacing.xs),
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Priority Alert Badge
///
/// High-emphasis badge for critical priority notifications.
/// With pulse animation to draw attention.
///
/// Exemplo:
/// ```dart
/// PriorityAlertBadge(level: PriorityLevel.critical)
/// ```
class PriorityAlertBadge extends StatefulWidget {
  const PriorityAlertBadge({
    super.key,
    required this.level,
  });

  final PriorityLevel level;

  @override
  State<PriorityAlertBadge> createState() => _PriorityAlertBadgeState();
}

class _PriorityAlertBadgeState extends State<PriorityAlertBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Only pulse for high/critical priorities
    if (widget.level == PriorityLevel.high ||
        widget.level == PriorityLevel.critical) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Get color for priority level
  Color _getColor() {
    switch (widget.level) {
      case PriorityLevel.low:
        return Colors.green;
      case PriorityLevel.medium:
        return Colors.orange;
      case PriorityLevel.high:
        return Colors.red;
      case PriorityLevel.critical:
        return const Color(0xFFB71C1C);
    }
  }

  /// Get icon for priority level
  IconData _getIcon() {
    switch (widget.level) {
      case PriorityLevel.low:
        return Icons.info_outlined;
      case PriorityLevel.medium:
        return Icons.warning_outlined;
      case PriorityLevel.high:
        return Icons.warning;
      case PriorityLevel.critical:
        return Icons.emergency;
    }
  }

  /// Get label in Portuguese
  String _getLabel() {
    switch (widget.level) {
      case PriorityLevel.low:
        return 'Baixa';
      case PriorityLevel.medium:
        return 'Média';
      case PriorityLevel.high:
        return 'Alta';
      case PriorityLevel.critical:
        return 'Crítica';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.sm,
          vertical: BJBankSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(
            color: color,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(BJBankSpacing.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              size: 14,
              color: color,
            ),
            const SizedBox(width: BJBankSpacing.xs),
            Text(
              _getLabel(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
