import 'package:flutter/material.dart';
import '../../models/nordigen_models.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Bank Card Widget
/// Displays a bank option for selection
class BankCard extends StatelessWidget {
  const BankCard({
    super.key,
    required this.institution,
    required this.onTap,
    this.isSelected = false,
  });

  final NordigenInstitution institution;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(BJBankSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? BJBankColors.primaryLight
                : BJBankColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? BJBankColors.primary
                  : BJBankColors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Bank logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BJBankColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: institution.logo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          institution.logo!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                        ),
                      )
                    : _buildFallbackIcon(),
              ),
              const SizedBox(width: BJBankSpacing.md),

              // Bank info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      institution.name,
                      style: BJBankTypography.titleSmall.copyWith(
                        color: BJBankColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BJBankSpacing.xxs),
                    Text(
                      institution.bic,
                      style: BJBankTypography.bodySmall.copyWith(
                        color: BJBankColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: BJBankColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: BJBankColors.onPrimary,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: BJBankColors.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return const Center(
      child: Icon(
        Icons.account_balance,
        color: BJBankColors.primary,
        size: 24,
      ),
    );
  }
}
