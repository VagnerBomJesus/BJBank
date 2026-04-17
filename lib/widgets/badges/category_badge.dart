import 'package:flutter/material.dart';
import '../../theme/spacing.dart';

/// Transaction Category Enum
///
/// Represents different transaction categories with associated colors and icons.
enum TransactionCategory {
  utilities,        // Utilities - Laranja
  insurance,        // Insurance - Azul
  subscription,     // Subscription - Roxo
  rent,             // Rent - Castanho
  education,        // Education - Verde
  healthcare,       // Healthcare - Rosa
  transport,        // Transport - Vermelho
  entertainment,    // Entertainment - Amarelo
  telecom,          // Telecom - Ciano
  other,            // Other - Cinzento
}

/// Category Badge Widget
///
/// Displays transaction category with color, icon, and optional label.
/// Used in bills, transactions, and expense tracking screens.
///
/// Features:
/// - 10 category types with semantic colors
/// - Compact (icon only) and full (icon + label) variants
/// - Portuguese category labels
/// - Dark theme support
/// - Accessibility labels
///
/// Exemplo:
/// ```dart
/// // Compact version for lists
/// CategoryBadge(category: TransactionCategory.utilities, compact: true)
///
/// // Full version with label
/// CategoryBadge(category: TransactionCategory.utilities)
/// ```
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.compact = false,
    this.showLabel = true,
  });

  /// Transaction category
  final TransactionCategory category;

  /// Use compact size (icon only)
  final bool compact;

  /// Show category label
  final bool showLabel;

  /// Get color for category
  Color _getColor() {
    switch (category) {
      case TransactionCategory.utilities:
        return Colors.orange; // #FF9800
      case TransactionCategory.insurance:
        return Colors.blue; // #2196F3
      case TransactionCategory.subscription:
        return Colors.purple; // #9C27B0
      case TransactionCategory.rent:
        return Colors.brown; // #795548
      case TransactionCategory.education:
        return Colors.green; // #4CAF50
      case TransactionCategory.healthcare:
        return Colors.pink; // #E91E63
      case TransactionCategory.transport:
        return Colors.red; // #F44336
      case TransactionCategory.entertainment:
        return Colors.amber; // #FFC107
      case TransactionCategory.telecom:
        return Colors.cyan; // #00BCD4
      case TransactionCategory.other:
        return Colors.grey; // #9E9E9E
    }
  }

  /// Get icon for category
  IconData _getIcon() {
    switch (category) {
      case TransactionCategory.utilities:
        return Icons.flash_on_outlined;
      case TransactionCategory.insurance:
        return Icons.shield_outlined;
      case TransactionCategory.subscription:
        return Icons.subscriptions_outlined;
      case TransactionCategory.rent:
        return Icons.home_outlined;
      case TransactionCategory.education:
        return Icons.school_outlined;
      case TransactionCategory.healthcare:
        return Icons.local_hospital_outlined;
      case TransactionCategory.transport:
        return Icons.directions_car_outlined;
      case TransactionCategory.entertainment:
        return Icons.theaters_outlined;
      case TransactionCategory.telecom:
        return Icons.phone_outlined;
      case TransactionCategory.other:
        return Icons.category_outlined;
    }
  }

  /// Get label in Portuguese
  String _getLabel() {
    switch (category) {
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.insurance:
        return 'Seguros';
      case TransactionCategory.subscription:
        return 'Subscrição';
      case TransactionCategory.rent:
        return 'Aluguel';
      case TransactionCategory.education:
        return 'Educação';
      case TransactionCategory.healthcare:
        return 'Saúde';
      case TransactionCategory.transport:
        return 'Transporte';
      case TransactionCategory.entertainment:
        return 'Diversão';
      case TransactionCategory.telecom:
        return 'Telecom';
      case TransactionCategory.other:
        return 'Outro';
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
        label: _getLabel(),
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
            size: 16,
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
      message: _getLabel(),
      child: Semantics(
        label: _getLabel(),
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

/// Category Badge Indicator (dot + label)
///
/// Simplified version showing just a colored dot and label.
///
/// Exemplo:
/// ```dart
/// CategoryBadgeIndicator(category: TransactionCategory.utilities)
/// ```
class CategoryBadgeIndicator extends StatelessWidget {
  const CategoryBadgeIndicator({
    super.key,
    required this.category,
  });

  final TransactionCategory category;

  /// Get color for category
  Color _getColor() {
    switch (category) {
      case TransactionCategory.utilities:
        return Colors.orange;
      case TransactionCategory.insurance:
        return Colors.blue;
      case TransactionCategory.subscription:
        return Colors.purple;
      case TransactionCategory.rent:
        return Colors.brown;
      case TransactionCategory.education:
        return Colors.green;
      case TransactionCategory.healthcare:
        return Colors.pink;
      case TransactionCategory.transport:
        return Colors.red;
      case TransactionCategory.entertainment:
        return Colors.amber;
      case TransactionCategory.telecom:
        return Colors.cyan;
      case TransactionCategory.other:
        return Colors.grey;
    }
  }

  /// Get label in Portuguese
  String _getLabel() {
    switch (category) {
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.insurance:
        return 'Seguros';
      case TransactionCategory.subscription:
        return 'Subscrição';
      case TransactionCategory.rent:
        return 'Aluguel';
      case TransactionCategory.education:
        return 'Educação';
      case TransactionCategory.healthcare:
        return 'Saúde';
      case TransactionCategory.transport:
        return 'Transporte';
      case TransactionCategory.entertainment:
        return 'Diversão';
      case TransactionCategory.telecom:
        return 'Telecom';
      case TransactionCategory.other:
        return 'Outro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: BJBankSpacing.xs),
        Text(
          _getLabel(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Category Chip Badge
///
/// Chip-style badge for category selection or filtering.
///
/// Exemplo:
/// ```dart
/// CategoryChipBadge(
///   category: TransactionCategory.utilities,
///   onTap: () => print('Selected utilities'),
/// )
/// ```
class CategoryChipBadge extends StatelessWidget {
  const CategoryChipBadge({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  final TransactionCategory category;
  final bool selected;
  final VoidCallback? onTap;

  /// Get color for category
  Color _getColor() {
    switch (category) {
      case TransactionCategory.utilities:
        return Colors.orange;
      case TransactionCategory.insurance:
        return Colors.blue;
      case TransactionCategory.subscription:
        return Colors.purple;
      case TransactionCategory.rent:
        return Colors.brown;
      case TransactionCategory.education:
        return Colors.green;
      case TransactionCategory.healthcare:
        return Colors.pink;
      case TransactionCategory.transport:
        return Colors.red;
      case TransactionCategory.entertainment:
        return Colors.amber;
      case TransactionCategory.telecom:
        return Colors.cyan;
      case TransactionCategory.other:
        return Colors.grey;
    }
  }

  /// Get icon for category
  IconData _getIcon() {
    switch (category) {
      case TransactionCategory.utilities:
        return Icons.flash_on_outlined;
      case TransactionCategory.insurance:
        return Icons.shield_outlined;
      case TransactionCategory.subscription:
        return Icons.subscriptions_outlined;
      case TransactionCategory.rent:
        return Icons.home_outlined;
      case TransactionCategory.education:
        return Icons.school_outlined;
      case TransactionCategory.healthcare:
        return Icons.local_hospital_outlined;
      case TransactionCategory.transport:
        return Icons.directions_car_outlined;
      case TransactionCategory.entertainment:
        return Icons.theaters_outlined;
      case TransactionCategory.telecom:
        return Icons.phone_outlined;
      case TransactionCategory.other:
        return Icons.category_outlined;
    }
  }

  /// Get label in Portuguese
  String _getLabel() {
    switch (category) {
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.insurance:
        return 'Seguros';
      case TransactionCategory.subscription:
        return 'Subscrição';
      case TransactionCategory.rent:
        return 'Aluguel';
      case TransactionCategory.education:
        return 'Educação';
      case TransactionCategory.healthcare:
        return 'Saúde';
      case TransactionCategory.transport:
        return 'Transporte';
      case TransactionCategory.entertainment:
        return 'Diversão';
      case TransactionCategory.telecom:
        return 'Telecom';
      case TransactionCategory.other:
        return 'Outro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.sm,
          vertical: BJBankSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: color,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(BJBankSpacing.md),
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: BJBankSpacing.xs),
              Icon(
                Icons.check,
                size: 14,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
