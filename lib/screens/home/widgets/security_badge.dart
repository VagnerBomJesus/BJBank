import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Security Badge for Home Screen
/// Compact version for app bar and transaction items
class SecurityBadge extends StatelessWidget {
  const SecurityBadge({
    super.key,
    this.size = 16,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.xxs),
      decoration: BoxDecoration(
        color: BJBankColors.quantum.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.shield,
        size: size,
        color: BJBankColors.quantum,
      ),
    );
  }
}

/// Encrypted Transaction Badge
class EncryptedTransactionBadge extends StatelessWidget {
  const EncryptedTransactionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.lock,
      size: 12,
      color: BJBankColors.encrypted,
    );
  }
}
