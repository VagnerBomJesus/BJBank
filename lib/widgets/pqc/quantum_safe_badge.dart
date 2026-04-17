import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/border_radius.dart';

/// Quantum Safe Badge Widget
///
/// Displays PQC (Post-Quantum Cryptography) security indicator.
/// Uses NIST FIPS 203/204 certified algorithms (Dilithium & Kyber).
///
/// Variants:
/// - Full: Icon + label "Quantum Safe"
/// - Compact: Icon only, minimal space
/// - Extended: Full label "Assinado com criptografia pós-quântica" for onboarding
///
/// Features:
/// - Tooltip explaining the quantum safe signature
/// - Pulse animation (optional, when PQC active)
/// - Dark theme support with alpha-based colors
/// - Accessibility labels for screen readers
///
/// Exemplo:
/// ```dart
/// // Compact version for app bars
/// QuantumSafeBadge(compact: true)
///
/// // Full version with label
/// QuantumSafeBadge()
///
/// // Extended version for educational screens
/// QuantumSafeBadge(extended: true)
/// ```
class QuantumSafeBadge extends StatefulWidget {
  const QuantumSafeBadge({
    super.key,
    this.compact = false,
    this.extended = false,
    this.showLabel = true,
    this.showPulse = false,
  });

  /// Use compact size for app bars and small spaces
  final bool compact;

  /// Show extended label for onboarding/educational purposes
  final bool extended;

  /// Show or hide the "Quantum Safe" label
  final bool showLabel;

  /// Show subtle pulse animation when PQC is active
  final bool showPulse;

  @override
  State<QuantumSafeBadge> createState() => _QuantumSafeBadgeState();
}

class _QuantumSafeBadgeState extends State<QuantumSafeBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(QuantumSafeBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.showPulse != widget.showPulse) {
      if (widget.showPulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Get tooltip text based on variant
  String _getTooltip() {
    if (widget.extended) {
      return 'Assinado com criptografia pós-quântica (NIST FIPS 203/204)';
    }
    return 'Protegido por criptografia pós-quântica';
  }

  /// Get label text based on variant
  String _getLabel() {
    if (widget.extended) {
      return 'Assinado com criptografia pós-quântica';
    }
    return 'Quantum Safe';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactBadge();
    }
    if (widget.extended) {
      return _buildExtendedBadge();
    }
    return _buildFullBadge();
  }

  /// Build full version with label and icon
  Widget _buildFullBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: _getTooltip(),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Semantics(
          label: 'Quantum Safe - ${_getTooltip()}',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BJBankSpacing.sm,
              vertical: BJBankSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: BJBankColors.quantum.withValues(
                alpha: isDark ? 0.2 : 0.15,
              ),
              borderRadius: BJBankBorderRadius.fullRadius,
              border: Border.all(
                color: BJBankColors.quantum.withValues(
                  alpha: isDark ? 0.5 : 0.3,
                ),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield,
                  size: BJBankSpacing.iconSm,
                  color: BJBankColors.quantum,
                ),
                if (widget.showLabel) ...[
                  const SizedBox(width: BJBankSpacing.xs),
                  Text(
                    _getLabel(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BJBankColors.quantum,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact version - icon only
  Widget _buildCompactBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: _getTooltip(),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Semantics(
          label: 'Quantum Safe',
          button: true,
          child: Container(
            padding: const EdgeInsets.all(BJBankSpacing.xs),
            decoration: BoxDecoration(
              color: BJBankColors.quantum.withValues(
                alpha: isDark ? 0.2 : 0.15,
              ),
              borderRadius: BJBankBorderRadius.fullRadius,
            ),
            child: Icon(
              Icons.shield,
              size: BJBankSpacing.iconSm,
              color: BJBankColors.quantum,
            ),
          ),
        ),
      ),
    );
  }

  /// Build extended version - full label for onboarding
  Widget _buildExtendedBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: _getTooltip(),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Semantics(
          label: 'Quantum Safe - ${_getTooltip()}',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BJBankSpacing.md,
              vertical: BJBankSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: BJBankColors.quantum.withValues(
                alpha: isDark ? 0.2 : 0.15,
              ),
              borderRadius: BJBankBorderRadius.fullRadius,
              border: Border.all(
                color: BJBankColors.quantum.withValues(
                  alpha: isDark ? 0.5 : 0.3,
                ),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield,
                  size: 24,
                  color: BJBankColors.quantum,
                ),
                const SizedBox(height: BJBankSpacing.xs),
                SizedBox(
                  width: 160,
                  child: Text(
                    _getLabel(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: BJBankColors.quantum,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Encrypted Indicator Badge
///
/// Shows data is encrypted locally using post-quantum cryptography.
/// Displayed on sensitive transactions and data containers.
///
/// Features:
/// - Compact and full variants
/// - Tooltip explaining encryption
/// - Dark theme support
/// - Accessibility labels
///
/// Exemplo:
/// ```dart
/// // Compact for transaction list
/// EncryptedBadge(compact: true)
///
/// // Full version
/// EncryptedBadge()
/// ```
class EncryptedBadge extends StatelessWidget {
  const EncryptedBadge({
    super.key,
    this.compact = false,
    this.showLabel = false,
  });

  /// Use compact size for small spaces
  final bool compact;

  /// Show "Encriptado" label alongside icon
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconSize = compact ? 12.0 : BJBankSpacing.iconSm;

    return Tooltip(
      message: 'Encriptado localmente com criptografia pós-quântica',
      child: Semantics(
        label: 'Encriptado',
        child: Container(
          padding: EdgeInsets.all(
            compact ? BJBankSpacing.xxs : BJBankSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: BJBankColors.encrypted.withValues(
              alpha: isDark ? 0.2 : 0.15,
            ),
            borderRadius: BJBankBorderRadius.fullRadius,
          ),
          child: showLabel
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: iconSize,
                      color: BJBankColors.encrypted,
                    ),
                    const SizedBox(width: BJBankSpacing.xs),
                    const Text(
                      'Encriptado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: BJBankColors.encrypted,
                      ),
                    ),
                  ],
                )
              : Icon(
                  Icons.lock,
                  size: iconSize,
                  color: BJBankColors.encrypted,
                ),
        ),
      ),
    );
  }
}

/// Verified Badge
///
/// Indicates account or transaction has been verified through PQC methods.
/// Shows trust and authenticity status.
///
/// Features:
/// - Compact and full variants
/// - Tooltip explaining verification
/// - Dark theme support
/// - Accessibility labels
///
/// Exemplo:
/// ```dart
/// // Compact for icons
/// VerifiedBadge(compact: true)
///
/// // Full version with label
/// VerifiedBadge()
/// ```
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    this.compact = false,
    this.showLabel = false,
  });

  /// Use compact size for small spaces
  final bool compact;

  /// Show "Verificado" label alongside icon
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconSize = compact ? 12.0 : BJBankSpacing.iconSm;

    return Tooltip(
      message: 'Conta verificada com criptografia pós-quântica',
      child: Semantics(
        label: 'Verificado',
        child: Container(
          padding: EdgeInsets.all(
            compact ? BJBankSpacing.xxs : BJBankSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: BJBankColors.verified.withValues(
              alpha: isDark ? 0.2 : 0.15,
            ),
            borderRadius: BJBankBorderRadius.fullRadius,
          ),
          child: showLabel
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: iconSize,
                      color: BJBankColors.verified,
                    ),
                    const SizedBox(width: BJBankSpacing.xs),
                    const Text(
                      'Verificado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: BJBankColors.verified,
                      ),
                    ),
                  ],
                )
              : Icon(
                  Icons.verified_user,
                  size: iconSize,
                  color: BJBankColors.verified,
                ),
        ),
      ),
    );
  }
}
