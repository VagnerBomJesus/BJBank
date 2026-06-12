import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_strings.dart';

/// Quick Actions Widget
/// Modern card-style action buttons
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    this.onMbWayTap,
    this.onTransferTap,
    this.onPayTap,
    this.onQrCodeTap,
  });

  final VoidCallback? onMbWayTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onPayTap;
  final VoidCallback? onQrCodeTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.homeQuickActions,
            style: BJBankTypography.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  imageAsset: 'assets/mbway.png',
                  label: AppStrings.homeMbWay,
                  color: BJBankColors.mbwayRed,
                  onTap: onMbWayTap,
                ),
              ),
              const SizedBox(width: BJBankSpacing.sm),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.arrow_upward_rounded,
                  label: AppStrings.homeTransfer,
                  color: BJBankColors.success,
                  onTap: onTransferTap,
                ),
              ),
              const SizedBox(width: BJBankSpacing.sm),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  label: AppStrings.homeQrCode,
                  color: BJBankColors.warning,
                  onTap: onQrCodeTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.color,
    this.onTap,
  }) : assert(icon != null || imageAsset != null,
            'icon ou imageAsset obrigatorio');

  final IconData? icon;
  final String? imageAsset;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimalist soft circle (UI-kit style)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: imageAsset != null
                    ? Padding(
                        padding: const EdgeInsets.all(BJBankSpacing.sm),
                        child: Image.asset(
                          imageAsset!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 24,
                        color: color,
                      ),
              ),
              const SizedBox(height: BJBankSpacing.xs),
              Text(
                label,
                style: BJBankTypography.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
