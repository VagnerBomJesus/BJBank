import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../theme/border_radius.dart';

/// Balance Card Widget
/// Redesigned as a realistic bank card with PQC security badge
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.accountNumber,
    required this.iban,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
  });

  final double balance;
  final String accountNumber;
  final String iban;
  final bool isBalanceVisible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
      child: AspectRatio(
        aspectRatio: 1.586, // Credit card ratio
        child: Container(
          decoration: BoxDecoration(
            gradient: BJBankColors.cardGradient,
            borderRadius: BJBankBorderRadius.lgRadius,
            boxShadow: [
              BoxShadow(
                color: BJBankColors.primary.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: BJBankColors.primaryDark.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BJBankBorderRadius.lgRadius,
            child: Stack(
              children: [
                // Decorative circles overlay
                _buildDecorativeOverlay(),

                // Card content
                Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Logo + Account type + Visibility toggle
                      _buildTopRow(),

                      const Spacer(flex: 2),

                      // Balance
                      _buildBalance(),

                      const Spacer(flex: 3),

                      // Bottom row: IBAN + Chip + PQC Badge
                      _buildBottomRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeOverlay() {
    return Stack(
      children: [
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -30,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 80,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        // BJBank logo mini
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BJBankBorderRadius.smRadius,
          ),
          child: const Icon(
            Icons.shield,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: BJBankSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BJBank',
              style: BJBankTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Conta à Ordem',
              style: BJBankTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Contactless / NFC icon
        Icon(
          Icons.contactless_outlined,
          size: 28,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(width: BJBankSpacing.xs),
        // Visibility toggle
        GestureDetector(
          onTap: onToggleVisibility,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BJBankBorderRadius.smRadius,
            ),
            child: Icon(
              isBalanceVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withValues(alpha: 0.8),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saldo Disponível',
          style: BJBankTypography.labelMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: BJBankSpacing.xxs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '€',
              style: BJBankTypography.headlineMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: BJBankSpacing.xs),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isBalanceVisible ? _formatBalance(balance) : '••••••',
                key: ValueKey(isBalanceVisible),
                style: BJBankTypography.balanceLarge.copyWith(
                  color: Colors.white,
                  fontSize: 34,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Chip icon
        Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BJBankColors.chipGold.withValues(alpha: 0.9),
                BJBankColors.chipGoldLight.withValues(alpha: 0.9),
                BJBankColors.chipGold.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 20,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: BJBankColors.chipGoldDark.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: BJBankColors.chipGoldDark.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: Container()),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: BJBankSpacing.md),

        // IBAN
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IBAN',
                style: BJBankTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isBalanceVisible ? _formatIbanFull(iban) : '•••• •••• •••• •••• •••• •',
                style: BJBankTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontFamily: BJBankTypography.fontFamilyMono,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: BJBankSpacing.xs),

        // PQC Badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BJBankSpacing.sm,
            vertical: BJBankSpacing.xxs + 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BJBankBorderRadius.fullRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 12,
                color: BJBankColors.quantum.withValues(alpha: 0.9),
              ),
              const SizedBox(width: BJBankSpacing.xxs),
              Text(
                'Quantum Safe',
                style: BJBankTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatBalance(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$integerPart,${parts[1]}';
  }

  String _formatIbanFull(String iban) {
    // Format IBAN in groups of 4: PT50 xxxx xxxx xxxx xxxx xxxx x
    final cleaned = iban.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }
}
