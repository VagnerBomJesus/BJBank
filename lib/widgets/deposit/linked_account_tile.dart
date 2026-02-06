import 'package:flutter/material.dart';
import '../../models/external_account_model.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Linked Account Tile Widget
/// Displays a connected external bank account
class LinkedAccountTile extends StatelessWidget {
  const LinkedAccountTile({
    super.key,
    required this.account,
    this.onTap,
    this.onRefresh,
    this.onDisconnect,
    this.isSelected = false,
    this.showBalance = true,
    this.showActions = false,
  });

  final ExternalAccountModel account;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onDisconnect;
  final bool isSelected;
  final bool showBalance;
  final bool showActions;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Bank logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: BJBankColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: account.institutionLogo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              account.institutionLogo!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                            ),
                          )
                        : _buildFallbackIcon(),
                  ),
                  const SizedBox(width: BJBankSpacing.sm),

                  // Account info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.institutionName,
                          style: BJBankTypography.titleSmall.copyWith(
                            color: BJBankColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.maskedIban,
                          style: BJBankTypography.bodySmall.copyWith(
                            color: BJBankColors.onSurfaceVariant,
                            fontFamily: BJBankTypography.fontFamilyMono,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Balance or selection indicator
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
                  else if (showBalance && account.formattedLastBalance != null)
                    Text(
                      account.formattedLastBalance!,
                      style: BJBankTypography.valueMedium.copyWith(
                        color: BJBankColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),

              // Expiry warning
              if (account.isExpiringSoon || account.isExpired) ...[
                const SizedBox(height: BJBankSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BJBankSpacing.xs,
                    vertical: BJBankSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: account.isExpired
                        ? BJBankColors.errorLight
                        : BJBankColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        account.isExpired
                            ? Icons.error_outline
                            : Icons.warning_amber,
                        size: 14,
                        color: account.isExpired
                            ? BJBankColors.error
                            : BJBankColors.warningDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        account.isExpired
                            ? 'Conexao expirada'
                            : 'Expira em ${account.daysUntilExpiry} dias',
                        style: BJBankTypography.labelSmall.copyWith(
                          color: account.isExpired
                              ? BJBankColors.error
                              : BJBankColors.warningDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Actions
              if (showActions) ...[
                const SizedBox(height: BJBankSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: BJBankSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onRefresh != null)
                      TextButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Atualizar'),
                        style: TextButton.styleFrom(
                          foregroundColor: BJBankColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: BJBankSpacing.sm,
                          ),
                        ),
                      ),
                    if (onDisconnect != null)
                      TextButton.icon(
                        onPressed: onDisconnect,
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Desconectar'),
                        style: TextButton.styleFrom(
                          foregroundColor: BJBankColors.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: BJBankSpacing.sm,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
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
        size: 20,
      ),
    );
  }
}
