import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../providers/account_provider.dart';
import '../../services/firestore_service.dart';
import '../../routes/app_routes.dart';

/// MB WAY Settings Screen
/// Manage MB WAY settings: status, limits, phone, history
class MbWaySettingsScreen extends StatefulWidget {
  const MbWaySettingsScreen({super.key});

  @override
  State<MbWaySettingsScreen> createState() => _MbWaySettingsScreenState();
}

class _MbWaySettingsScreenState extends State<MbWaySettingsScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  Map<String, dynamic> _usageInfo = {};

  @override
  void initState() {
    super.initState();
    _loadUsageInfo();
  }

  Future<void> _loadUsageInfo() async {
    final accountProvider = context.read<AccountProvider>();
    final account = accountProvider.primaryAccount;
    if (account == null) return;

    final info = await _firestoreService.getMbWayUsageInfo(account.id);
    if (mounted) {
      setState(() => _usageInfo = info);
    }
  }

  Future<void> _handleToggleMbWay(bool enable) async {
    final accountProvider = context.read<AccountProvider>();
    final account = accountProvider.primaryAccount;
    if (account == null) return;

    if (enable) {
      // Navigate to phone verification
      final phone = await Navigator.pushNamed(
        context,
        AppRoutes.mbwayPhoneVerification,
      );

      if (phone != null && phone is String) {
        setState(() => _isLoading = true);
        try {
          await _firestoreService.linkMbWayVerified(account.id, phone);
          await accountProvider.refreshAccount();
          await _loadUsageInfo();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('MB WAY ativado com sucesso'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao ativar MB WAY: $e'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        setState(() => _isLoading = false);
      }
    } else {
      // Confirm disable
      final confirmed = await _showUnlinkConfirmation();
      if (confirmed == true) {
        setState(() => _isLoading = true);
        try {
          await _firestoreService.unlinkMbWay(account.id);
          await accountProvider.refreshAccount();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('MB WAY desassociado'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro: $e'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showUnlinkConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desassociar MB WAY'),
        content: const Text(
          'Tem a certeza que deseja desassociar o MB WAY?\n\n'
          'Nao podera enviar ou receber pagamentos MB WAY ate associar novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: BJBankColors.error,
            ),
            child: const Text('Desassociar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangePhone() async {
    final accountProvider = context.read<AccountProvider>();
    final account = accountProvider.primaryAccount;
    if (account == null) return;

    final phone = await Navigator.pushNamed(
      context,
      AppRoutes.mbwayPhoneVerification,
      arguments: account.mbWayPhone,
    );

    if (phone != null && phone is String) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.linkMbWayVerified(account.id, phone);
        await accountProvider.refreshAccount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telefone alterado com sucesso'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditLimitDialog({
    required String title,
    required double currentValue,
    required double minValue,
    required double maxValue,
    required Future<void> Function(double) onSave,
  }) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'EUR ',
                helperText: 'Min: EUR ${minValue.toStringAsFixed(0)} / Max: EUR ${maxValue.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= minValue && value <= maxValue) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      await onSave(result);
      await _loadUsageInfo();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEditDailyLimit() async {
    final accountProvider = context.read<AccountProvider>();
    final account = accountProvider.primaryAccount;
    if (account == null) return;

    await _showEditLimitDialog(
      title: 'Limite Diario',
      currentValue: _usageInfo['dailyLimit'] ?? 1000.0,
      minValue: 100.0,
      maxValue: 5000.0,
      onSave: (value) async {
        await _firestoreService.updateMbWayLimits(
          account.id,
          dailyLimit: value,
        );
        await accountProvider.refreshAccount();
      },
    );
  }

  Future<void> _handleEditTransactionLimit() async {
    final accountProvider = context.read<AccountProvider>();
    final account = accountProvider.primaryAccount;
    if (account == null) return;

    await _showEditLimitDialog(
      title: 'Limite por Transacao',
      currentValue: _usageInfo['perTransactionLimit'] ?? 500.0,
      minValue: 10.0,
      maxValue: 1000.0,
      onSave: (value) async {
        await _firestoreService.updateMbWayLimits(
          account.id,
          perTransactionLimit: value,
        );
        await accountProvider.refreshAccount();
      },
    );
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, AppRoutes.history, arguments: 'mbway');
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final account = accountProvider.primaryAccount;
    final isLinked = account?.mbWayLinked ?? false;

    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BJBankColors.mbwayRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'MB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Definicoes MB WAY'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              children: [
                // Status card
                _buildStatusCard(account, isLinked),

                if (isLinked) ...[
                  const SizedBox(height: BJBankSpacing.lg),

                  // Limits card
                  _buildLimitsCard(),

                  const SizedBox(height: BJBankSpacing.lg),

                  // Actions card
                  _buildActionsCard(),

                  const SizedBox(height: BJBankSpacing.xl),

                  // Unlink button
                  OutlinedButton.icon(
                    onPressed: () => _handleToggleMbWay(false),
                    icon: Icon(Icons.link_off, color: BJBankColors.error),
                    label: Text(
                      'Desassociar MB WAY',
                      style: TextStyle(color: BJBankColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: BJBankColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStatusCard(dynamic account, bool isLinked) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLinked ? Icons.check_circle : Icons.cancel,
                  color: isLinked ? BJBankColors.success : BJBankColors.error,
                ),
                const SizedBox(width: BJBankSpacing.sm),
                Text(
                  'Estado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'MB WAY ${isLinked ? 'Ativo' : 'Inativo'}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: isLinked && account?.mbWayPhone != null
                  ? Text(account!.formattedMbWayPhone ?? account.mbWayPhone)
                  : const Text('Associe o seu numero de telemovel'),
              value: isLinked,
              onChanged: _handleToggleMbWay,
            ),
            if (isLinked && account?.mbWayLinkedAt != null) ...[
              const Divider(),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: BJBankColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: BJBankSpacing.sm),
                  Text(
                    'Associado em ${DateFormat('dd/MM/yyyy').format(account!.mbWayLinkedAt!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: BJBankColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitsCard() {
    final dailyLimit = _usageInfo['dailyLimit'] ?? 1000.0;
    final perTxLimit = _usageInfo['perTransactionLimit'] ?? 500.0;
    final dailyUsed = _usageInfo['dailyUsed'] ?? 0.0;
    final remaining = _usageInfo['remaining'] ?? dailyLimit;
    final usagePercent = dailyLimit > 0 ? (dailyUsed / dailyLimit) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: BJBankColors.primary),
                const SizedBox(width: BJBankSpacing.sm),
                Text(
                  'Limites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.md),

            // Daily limit
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Limite Diario'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EUR ${dailyLimit.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: BJBankSpacing.xs),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _handleEditDailyLimit,
            ),

            const Divider(height: 1),

            // Per transaction limit
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Limite por Transacao'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EUR ${perTxLimit.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: BJBankSpacing.xs),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _handleEditTransactionLimit,
            ),

            const Divider(),

            // Usage today
            const SizedBox(height: BJBankSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usado Hoje',
                  style: TextStyle(color: BJBankColors.onSurfaceVariant),
                ),
                Text(
                  'EUR ${dailyUsed.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Disponivel',
                  style: TextStyle(color: BJBankColors.onSurfaceVariant),
                ),
                Text(
                  'EUR ${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: BJBankColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.sm),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usagePercent.clamp(0.0, 1.0),
                backgroundColor: BJBankColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  usagePercent > 0.9
                      ? BJBankColors.error
                      : usagePercent > 0.7
                          ? BJBankColors.warning
                          : BJBankColors.primary,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.phone_outlined, color: BJBankColors.primary),
            title: const Text('Alterar Telefone'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleChangePhone,
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: Icon(Icons.history, color: BJBankColors.primary),
            title: const Text('Historico MB WAY'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToHistory,
          ),
        ],
      ),
    );
  }
}
