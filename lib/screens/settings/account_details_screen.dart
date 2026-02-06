import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';

/// Account Details Screen
/// Shows complete bank account information
class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final authProvider = context.watch<AuthProvider>();
    final account = accountProvider.primaryAccount;
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Conta'),
      ),
      body: account == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              children: [
                // Account status card
                _buildStatusCard(context, account.status.name),

                const SizedBox(height: BJBankSpacing.lg),

                // Account info section
                _buildSectionHeader(context, 'Informação da Conta'),
                const SizedBox(height: BJBankSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.person_outline,
                          'Titular',
                          user?.name ?? '-',
                        ),
                        const Divider(height: BJBankSpacing.lg),
                        _buildCopyableRow(
                          context,
                          Icons.account_balance_outlined,
                          'IBAN',
                          account.formattedIban,
                        ),
                        const Divider(height: BJBankSpacing.lg),
                        _buildCopyableRow(
                          context,
                          Icons.numbers_outlined,
                          'Nº Conta',
                          account.accountNumber,
                        ),
                        const Divider(height: BJBankSpacing.lg),
                        _buildInfoRow(
                          context,
                          Icons.credit_card_outlined,
                          'Tipo de Conta',
                          account.typeDisplayName,
                        ),
                        const Divider(height: BJBankSpacing.lg),
                        _buildInfoRow(
                          context,
                          Icons.business_outlined,
                          'Código do Banco',
                          account.bankCode,
                        ),
                        const Divider(height: BJBankSpacing.lg),
                        _buildInfoRow(
                          context,
                          Icons.euro_outlined,
                          'Moeda',
                          account.currency,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: BJBankSpacing.lg),

                // Balance section
                _buildSectionHeader(context, 'Saldos'),
                const SizedBox(height: BJBankSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: Column(
                      children: [
                        _buildBalanceRow(
                          context,
                          'Saldo Contabilístico',
                          account.formattedBalance,
                          BJBankColors.primary,
                        ),
                        const Divider(height: BJBankSpacing.lg),
                        _buildBalanceRow(
                          context,
                          'Saldo Disponível',
                          account.formattedAvailableBalance,
                          BJBankColors.success,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: BJBankSpacing.lg),

                // MB WAY section
                _buildSectionHeader(context, 'MB WAY'),
                const SizedBox(height: BJBankSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.phone_android,
                          'Estado',
                          account.mbWayLinked ? 'Associado' : 'Não associado',
                          valueColor: account.mbWayLinked
                              ? BJBankColors.success
                              : BJBankColors.onSurfaceVariant,
                        ),
                        if (account.mbWayLinked && account.mbWayPhone != null) ...[
                          const Divider(height: BJBankSpacing.lg),
                          _buildInfoRow(
                            context,
                            Icons.smartphone,
                            'Telefone MB WAY',
                            account.mbWayPhone!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: BJBankSpacing.lg),

                // Dates section
                _buildSectionHeader(context, 'Datas'),
                const SizedBox(height: BJBankSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.calendar_today_outlined,
                          'Data de Abertura',
                          _formatDate(account.createdAt),
                        ),
                        const Divider(height: BJBankSpacing.lg),
                        _buildInfoRow(
                          context,
                          Icons.update_outlined,
                          'Última Atualização',
                          _formatDate(account.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: BJBankSpacing.xxl),
              ],
            ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String status) {
    final isActive = status == 'active';
    return Card(
      color: isActive
          ? BJBankColors.success.withValues(alpha: 0.1)
          : BJBankColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(BJBankSpacing.sm),
              decoration: BoxDecoration(
                color: isActive
                    ? BJBankColors.success.withValues(alpha: 0.2)
                    : BJBankColors.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.check_circle : Icons.warning,
                color: isActive ? BJBankColors.success : BJBankColors.warning,
              ),
            ),
            const SizedBox(width: BJBankSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado da Conta',
                    style: TextStyle(
                      color: BJBankColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive ? 'Ativa' : status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isActive ? BJBankColors.success : BJBankColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: BJBankColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BJBankColors.onSurfaceVariant),
        const SizedBox(width: BJBankSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BJBankColors.onSurfaceVariant),
        const SizedBox(width: BJBankSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.copy, size: 20, color: BJBankColors.primary),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value.replaceAll(' ', '')));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copiado'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Copiar',
        ),
      ],
    );
  }

  Widget _buildBalanceRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 20, color: BJBankColors.onSurfaceVariant),
        const SizedBox(width: BJBankSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
