import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/border_radius.dart';

/// Quantum Safe Badge Widget
/// Displays PQC security indicator
class QuantumSafeBadge extends StatelessWidget {
  const QuantumSafeBadge({
    super.key,
    this.compact = false,
    this.showLabel = true,
  });

  /// Use compact size for app bars and small spaces
  final bool compact;

  /// Show or hide the "Quantum Safe" label
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBadge();
    }
    return _buildFullBadge();
  }

  Widget _buildFullBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.sm,
        vertical: BJBankSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: BJBankColors.quantum.withOpacity(0.15),
        borderRadius: BJBankBorderRadius.fullRadius,
        border: Border.all(
          color: BJBankColors.quantum.withOpacity(0.3),
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
          if (showLabel) ...[
            const SizedBox(width: BJBankSpacing.xs),
            const Text(
              'Quantum Safe',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: BJBankColors.quantum,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactBadge() {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.xs),
      decoration: BoxDecoration(
        color: BJBankColors.quantum.withOpacity(0.15),
        borderRadius: BJBankBorderRadius.fullRadius,
      ),
      child: Icon(
        Icons.shield,
        size: BJBankSpacing.iconSm,
        color: BJBankColors.quantum,
      ),
    );
  }
}

/// Encrypted Indicator Badge
class EncryptedBadge extends StatelessWidget {
  const EncryptedBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? BJBankSpacing.xxs : BJBankSpacing.xs),
      decoration: BoxDecoration(
        color: BJBankColors.encrypted.withOpacity(0.15),
        borderRadius: BJBankBorderRadius.fullRadius,
      ),
      child: Icon(
        Icons.lock,
        size: compact ? 12 : BJBankSpacing.iconSm,
        color: BJBankColors.encrypted,
      ),
    );
  }
}

/// Verified Badge
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? BJBankSpacing.xxs : BJBankSpacing.xs),
      decoration: BoxDecoration(
        color: BJBankColors.verified.withOpacity(0.15),
        borderRadius: BJBankBorderRadius.fullRadius,
      ),
      child: Icon(
        Icons.verified_user,
        size: compact ? 12 : BJBankSpacing.iconSm,
        color: BJBankColors.verified,
      ),
    );
  }
}
