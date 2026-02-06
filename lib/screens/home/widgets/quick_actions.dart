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
    this.onDepositTap,
  });

  final VoidCallback? onMbWayTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onPayTap;
  final VoidCallback? onQrCodeTap;
  final VoidCallback? onDepositTap;

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
              color: BJBankColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.phone_android_rounded,
                  label: AppStrings.homeMbWay,
                  color: BJBankColors.primary,
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
                  icon: Icons.add_circle_outline_rounded,
                  label: AppStrings.homeDeposit,
                  color: BJBankColors.tertiary,
                  onTap: onDepositTap,
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
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: BJBankSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: BJBankSpacing.sm),
              Text(
                label,
                style: BJBankTypography.labelSmall.copyWith(
                  color: BJBankColors.onSurface,
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
