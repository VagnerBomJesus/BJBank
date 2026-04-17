import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Security Badge for Home Screen
///
/// Displays PQC security indicator for transactions and operations.
/// Compact circular badge suitable for app bars and transaction lists.
///
/// Features:
/// - Customizable size
/// - Multiple icon variants (shield, lock, verified)
/// - Fade + scale entry animation
/// - Tooltip explaining PQC protection
/// - Dark theme support
/// - Accessibility labels
///
/// Exemplo:
/// ```dart
/// // Default size (16px)
/// SecurityBadge()
///
/// // Custom size
/// SecurityBadge(size: 20)
///
/// // Different icon variant
/// SecurityBadge(iconType: SecurityIconType.lock)
/// ```
enum SecurityIconType {
  shield,    // Default - general protection
  lock,      // Encryption
  verified,  // Verification
}

class SecurityBadge extends StatefulWidget {
  const SecurityBadge({
    super.key,
    this.size = 16,
    this.iconType = SecurityIconType.shield,
  });

  /// Size of the badge
  final double size;

  /// Icon type to display
  final SecurityIconType iconType;

  @override
  State<SecurityBadge> createState() => _SecurityBadgeState();
}

class _SecurityBadgeState extends State<SecurityBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  /// Get icon based on type
  IconData _getIcon() {
    switch (widget.iconType) {
      case SecurityIconType.shield:
        return Icons.shield;
      case SecurityIconType.lock:
        return Icons.lock;
      case SecurityIconType.verified:
        return Icons.verified_user;
    }
  }

  /// Get tooltip text based on icon type
  String _getTooltip() {
    switch (widget.iconType) {
      case SecurityIconType.shield:
        return 'Protegido por PQC';
      case SecurityIconType.lock:
        return 'Encriptado com PQC';
      case SecurityIconType.verified:
        return 'Verificado com PQC';
    }
  }

  /// Get semantic label based on icon type
  String _getLabel() {
    switch (widget.iconType) {
      case SecurityIconType.shield:
        return 'Protegido';
      case SecurityIconType.lock:
        return 'Encriptado';
      case SecurityIconType.verified:
        return 'Verificado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Tooltip(
          message: _getTooltip(),
          child: Semantics(
            label: _getLabel(),
            button: true,
            child: Container(
              width: widget.size + (BJBankSpacing.xxs * 2),
              height: widget.size + (BJBankSpacing.xxs * 2),
              decoration: BoxDecoration(
                color: BJBankColors.quantum.withValues(
                  alpha: isDark ? 0.2 : 0.15,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: widget.size,
                color: BJBankColors.quantum,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Encrypted Transaction Badge
///
/// Compact lock icon indicating transaction is encrypted with PQC.
/// Used inline with transaction items and list entries.
///
/// Features:
/// - Minimal size for list integration
/// - Scale animation on appearance
/// - Tooltip with explanation
/// - Dark theme support
/// - Accessibility label
///
/// Exemplo:
/// ```dart
/// EncryptedTransactionBadge()
/// ```
class EncryptedTransactionBadge extends StatefulWidget {
  const EncryptedTransactionBadge({super.key});

  @override
  State<EncryptedTransactionBadge> createState() =>
      _EncryptedTransactionBadgeState();
}

class _EncryptedTransactionBadgeState extends State<EncryptedTransactionBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Tooltip(
        message: 'Transação encriptada com criptografia pós-quântica',
        child: Semantics(
          label: 'Encriptado',
          child: Icon(
            Icons.lock,
            size: 12,
            color: isDark
                ? BJBankColors.encrypted.withValues(alpha: 0.8)
                : BJBankColors.encrypted,
          ),
        ),
      ),
    );
  }
}
