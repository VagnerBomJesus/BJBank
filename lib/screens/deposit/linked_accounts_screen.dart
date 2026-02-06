import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/external_account_model.dart';
import '../../providers/deposit_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/deposit/linked_account_tile.dart';
import 'bank_selection_screen.dart';

/// Linked Accounts Screen
/// Shows all connected external bank accounts
class LinkedAccountsScreen extends StatelessWidget {
  const LinkedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Contas Conectadas'),
        backgroundColor: BJBankColors.surface,
        foregroundColor: BJBankColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToBankSelection(context),
            tooltip: 'Conectar novo banco',
          ),
        ],
      ),
      body: Consumer<DepositProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: BJBankColors.primary),
            );
          }

          if (provider.linkedAccounts.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh all account balances
              for (final account in provider.linkedAccounts) {
                await provider.refreshAccountBalance(account);
              }
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              itemCount: provider.linkedAccounts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: BJBankSpacing.sm),
              itemBuilder: (context, index) {
                final account = provider.linkedAccounts[index];
                return LinkedAccountTile(
                  account: account,
                  showActions: true,
                  onRefresh: () => provider.refreshAccountBalance(account),
                  onDisconnect: () => _showDisconnectDialog(context, account),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToBankSelection(context),
        icon: const Icon(Icons.add),
        label: const Text('Conectar Banco'),
        backgroundColor: BJBankColors.primary,
        foregroundColor: BJBankColors.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: BJBankColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                size: 48,
                color: BJBankColors.primary,
              ),
            ),
            const SizedBox(height: BJBankSpacing.lg),
            Text(
              'Nenhuma conta conectada',
              style: BJBankTypography.titleMedium.copyWith(
                color: BJBankColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: BJBankSpacing.sm),
            Text(
              'Conecte uma conta bancaria para fazer depositos no BJBank',
              textAlign: TextAlign.center,
              style: BJBankTypography.bodyMedium.copyWith(
                color: BJBankColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BJBankSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _navigateToBankSelection(context),
              icon: const Icon(Icons.add),
              label: const Text('Conectar Banco'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: BJBankSpacing.lg,
                  vertical: BJBankSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBankSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BankSelectionScreen()),
    );
  }

  void _showDisconnectDialog(
    BuildContext context,
    ExternalAccountModel account,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desconectar conta?'),
        content: Text(
          'Tem a certeza que deseja desconectar a conta ${account.maskedIban} do ${account.institutionName}?\n\n'
          'Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<DepositProvider>().disconnectAccount(account);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conta desconectada com sucesso'),
                      backgroundColor: BJBankColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao desconectar: $e'),
                      backgroundColor: BJBankColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: BJBankColors.error),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }
}
