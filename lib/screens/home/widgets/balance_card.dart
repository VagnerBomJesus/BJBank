import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../theme/border_radius.dart';

/// Balance Card Widget
/// UI-kit inspired dark navy card: dotted world-map texture, contactless
/// glyph and a translucent blue glow — keeping the BJBank PQC badge, IBAN
/// and EUR balance.
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
            gradient: BJBankColors.cardNavyGradient,
            borderRadius: BorderRadius.circular(BJBankBorderRadius.xl),
            boxShadow: [
              BoxShadow(
                color: BJBankColors.cardNavyDeep.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: BJBankColors.accentBlue.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BJBankBorderRadius.xl),
            child: Stack(
              children: [
                // Translucent blue glow on the right (UI-kit signature)
                Positioned(
                  right: -70,
                  top: -10,
                  bottom: -40,
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          BJBankColors.accentBlue.withValues(alpha: 0.45),
                          BJBankColors.accentBlue.withValues(alpha: 0.0),
                        ],
                        stops: const [0.2, 1.0],
                      ),
                    ),
                  ),
                ),

                // Faint dotted "world map" texture
                Positioned.fill(
                  child: CustomPaint(painter: _MapDotsPainter()),
                ),

                // Card content
                Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(),
                      const Spacer(flex: 2),
                      _buildBalance(),
                      const Spacer(flex: 3),
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

  Widget _buildTopRow() {
    return Row(
      children: [
        // BJBank logo mini
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: BJBankColors.onPrimary.withValues(alpha: 0.12),
            borderRadius: BJBankBorderRadius.smRadius,
          ),
          child: const Icon(
            Icons.shield,
            size: 18,
            color: BJBankColors.onPrimary,
          ),
        ),
        const SizedBox(width: BJBankSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BJBank',
              style: BJBankTypography.labelLarge.copyWith(
                color: BJBankColors.onPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Conta à Ordem',
              style: BJBankTypography.labelSmall.copyWith(
                color: BJBankColors.onPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Contactless / NFC icon
        Icon(
          Icons.contactless_outlined,
          size: 28,
          color: BJBankColors.onPrimary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: BJBankSpacing.xs),
        // Visibility toggle
        GestureDetector(
          onTap: onToggleVisibility,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: BJBankColors.onPrimary.withValues(alpha: 0.10),
              borderRadius: BJBankBorderRadius.smRadius,
            ),
            child: Icon(
              isBalanceVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: BJBankColors.onPrimary.withValues(alpha: 0.8),
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
            color: BJBankColors.onPrimary.withValues(alpha: 0.6),
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
                color: BJBankColors.onPrimary.withValues(alpha: 0.85),
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
                  color: BJBankColors.onPrimary,
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
                            color:
                                BJBankColors.chipGoldDark.withValues(alpha: 0.3),
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
                  color: BJBankColors.onPrimary.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isBalanceVisible
                    ? _formatIbanFull(iban)
                    : '•••• •••• •••• •••• •••• •',
                style: BJBankTypography.labelSmall.copyWith(
                  color: BJBankColors.onPrimary.withValues(alpha: 0.9),
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
            color: BJBankColors.onPrimary.withValues(alpha: 0.12),
            borderRadius: BJBankBorderRadius.fullRadius,
            border: Border.all(
              color: BJBankColors.quantum.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 12,
                color: BJBankColors.quantum.withValues(alpha: 0.95),
              ),
              const SizedBox(width: BJBankSpacing.xxs),
              Text(
                'Quantum Safe',
                style: BJBankTypography.labelSmall.copyWith(
                  color: BJBankColors.onPrimary.withValues(alpha: 0.95),
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

/// Paints a faint grid of dots evoking a world-map texture on the card.
class _MapDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BJBankColors.onPrimary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const double spacing = 11.0;
    const double radius = 1.0;
    final rng = math.Random(42);

    for (double y = 8; y < size.height; y += spacing) {
      for (double x = 8; x < size.width; x += spacing) {
        // Skip ~40% of dots for an organic, map-like scatter.
        if (rng.nextDouble() < 0.4) continue;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapDotsPainter oldDelegate) => false;
}
