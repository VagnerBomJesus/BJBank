import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/deposit_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/deposit/linked_account_tile.dart';
import 'bank_selection_screen.dart';
import 'deposit_amount_screen.dart';
import 'linked_accounts_screen.dart';

/// Deposit Screen
/// Main screen for managing deposits via Open Banking
class DepositScreen extends StatelessWidget {
  const DepositScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Depositar'),
        backgroundColor: BJBankColors.surface,
        foregroundColor: BJBankColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showDepositHistory(context),
            tooltip: 'Historico de depositos',
          ),
        ],
      ),
      body: Consumer<DepositProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.linkedAccounts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: BJBankColors.primary),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              for (final account in provider.linkedAccounts) {
                await provider.refreshAccountBalance(account);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Demo mode banner
                  if (provider.isDemoMode) _buildDemoBanner(),

                  // Linked accounts section
                  _buildLinkedAccountsSection(context, provider),
                  const SizedBox(height: BJBankSpacing.lg),

                  // Recent deposits section
                  if (provider.recentDeposits.isNotEmpty) ...[
                    _buildRecentDepositsSection(context, provider),
                  ],

                  // Info card
                  _buildInfoCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLinkedAccountsSection(
    BuildContext context,
    DepositProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contas Conectadas',
              style: BJBankTypography.titleMedium.copyWith(
                color: BJBankColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (provider.linkedAccounts.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LinkedAccountsScreen(),
                  ),
                ),
                child: const Text('Ver todas'),
              ),
          ],
        ),
        const SizedBox(height: BJBankSpacing.sm),

        if (provider.activeAccounts.isEmpty)
          _buildNoAccountsCard(context)
        else
          Column(
            children: [
              // Show first 2 active accounts
              ...provider.activeAccounts.take(2).map((account) => Padding(
                    padding: const EdgeInsets.only(bottom: BJBankSpacing.sm),
                    child: LinkedAccountTile(
                      account: account,
                      showBalance: true,
                      onTap: () => _startDeposit(context, account.id),
                    ),
                  )),

              // Connect new bank button
              _buildConnectBankButton(context),
            ],
          ),
      ],
    );
  }

  Widget _buildNoAccountsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BJBankSpacing.lg),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BJBankColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: BJBankColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 32,
              color: BJBankColors.primary,
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          Text(
            'Conecte um banco para depositar',
            style: BJBankTypography.titleSmall.copyWith(
              color: BJBankColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: BJBankSpacing.xs),
          Text(
            'Use o Open Banking para transferir dinheiro de qualquer banco portugues',
            textAlign: TextAlign.center,
            style: BJBankTypography.bodySmall.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          ElevatedButton.icon(
            onPressed: () => _navigateToBankSelection(context),
            icon: const Icon(Icons.add),
            label: const Text('Conectar Banco'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: BJBankSpacing.lg,
                vertical: BJBankSpacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectBankButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToBankSelection(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BJBankSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: BJBankColors.primary,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: BJBankColors.primary,
              ),
              const SizedBox(width: BJBankSpacing.sm),
              Text(
                'Conectar Novo Banco',
                style: BJBankTypography.labelLarge.copyWith(
                  color: BJBankColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDepositsSection(
    BuildContext context,
    DepositProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Depositos Recentes',
              style: BJBankTypography.titleMedium.copyWith(
                color: BJBankColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => _showDepositHistory(context),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: BJBankSpacing.sm),

        Container(
          decoration: BoxDecoration(
            color: BJBankColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BJBankColors.outlineVariant),
          ),
          child: Column(
            children: provider.recentDeposits.map((deposit) {
              final isLast = deposit == provider.recentDeposits.last;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: deposit.isCompleted
                            ? BJBankColors.successLight
                            : deposit.isFailed
                                ? BJBankColors.errorLight
                                : BJBankColors.warningLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        deposit.isCompleted
                            ? Icons.check
                            : deposit.isFailed
                                ? Icons.close
                                : Icons.schedule,
                        color: deposit.isCompleted
                            ? BJBankColors.success
                            : deposit.isFailed
                                ? BJBankColors.error
                                : BJBankColors.warning,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      deposit.formattedAmount,
                      style: BJBankTypography.titleSmall.copyWith(
                        color: BJBankColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${deposit.externalBankName ?? 'Banco'} - ${deposit.statusDisplayName}',
                      style: BJBankTypography.bodySmall.copyWith(
                        color: BJBankColors.onSurfaceVariant,
                      ),
                    ),
                    trailing: Text(
                      _formatDate(deposit.createdAt),
                      style: BJBankTypography.bodySmall.copyWith(
                        color: BJBankColors.outline,
                      ),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: BJBankSpacing.lg),
      ],
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: BJBankSpacing.md),
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BJBankColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BJBankColors.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.science_outlined,
              color: BJBankColors.warningDark,
              size: 20,
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo de Demonstracao',
                  style: BJBankTypography.labelMedium.copyWith(
                    color: BJBankColors.warningDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'A usar dados simulados para pesquisa. Os bancos e transacoes sao ficticios.',
                  style: BJBankTypography.bodySmall.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.quantumLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: BJBankColors.quantum,
                size: 20,
              ),
              const SizedBox(width: BJBankSpacing.xs),
              Text(
                'Open Banking Seguro',
                style: BJBankTypography.labelMedium.copyWith(
                  color: BJBankColors.quantum,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: BJBankSpacing.xs),
          Text(
            'Os depositos sao processados via Open Banking (PSD2) com criptografia pos-quantica. '
            'As suas credenciais bancarias nunca sao partilhadas connosco.',
            style: BJBankTypography.bodySmall.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoje';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} dias';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _navigateToBankSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BankSelectionScreen()),
    );
  }

  void _startDeposit(BuildContext context, String externalAccountId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositAmountScreen(
          externalAccountId: externalAccountId,
        ),
      ),
    );
  }

  void _showDepositHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BJBankColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historico de Depositos',
                    style: BJBankTypography.titleMedium.copyWith(
                      color: BJBankColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Consumer<DepositProvider>(
                builder: (context, provider, _) {
                  if (provider.deposits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.history,
                            size: 48,
                            color: BJBankColors.outline,
                          ),
                          const SizedBox(height: BJBankSpacing.md),
                          Text(
                            'Sem depositos',
                            style: BJBankTypography.bodyMedium.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    itemCount: provider.deposits.length,
                    itemBuilder: (context, index) {
                      final deposit = provider.deposits[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: deposit.isCompleted
                                ? BJBankColors.successLight
                                : deposit.isFailed
                                    ? BJBankColors.errorLight
                                    : BJBankColors.warningLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            deposit.isCompleted
                                ? Icons.check
                                : deposit.isFailed
                                    ? Icons.close
                                    : Icons.schedule,
                            color: deposit.isCompleted
                                ? BJBankColors.success
                                : deposit.isFailed
                                    ? BJBankColors.error
                                    : BJBankColors.warning,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          deposit.formattedAmount,
                          style: BJBankTypography.titleSmall.copyWith(
                            color: BJBankColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${deposit.externalBankName ?? 'Banco'}\n${deposit.statusDisplayName}',
                          style: BJBankTypography.bodySmall.copyWith(
                            color: BJBankColors.onSurfaceVariant,
                          ),
                        ),
                        trailing: Text(
                          _formatDate(deposit.createdAt),
                          style: BJBankTypography.bodySmall.copyWith(
                            color: BJBankColors.outline,
                          ),
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
