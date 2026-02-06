import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../routes/app_routes.dart';

/// Privacy & Data Screen
/// Manage privacy settings, data, and account deletion
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidade e Dados'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          // Data info section
          _buildSectionHeader(context, 'Os Seus Dados'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: BJBankColors.primary),
                  title: const Text('Dados Pessoais'),
                  subtitle: const Text('Nome, email, telefone'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: const Text('Dados Bancários'),
                  subtitle: const Text('IBAN, número de conta'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.accountDetails),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Histórico de Transações'),
                  subtitle: const Text('Aceda via o separador Histórico'),
                  trailing: Icon(Icons.info_outline, color: BJBankColors.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Security data section
          _buildSectionHeader(context, 'Segurança'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.key_outlined, color: BJBankColors.quantum),
                  title: const Text('Chaves PQC'),
                  subtitle: Text(
                    user?.hasPqcKeys == true
                        ? 'CRYSTALS-Dilithium configurado'
                        : 'Não configuradas',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BJBankSpacing.sm,
                      vertical: BJBankSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: (user?.hasPqcKeys == true
                              ? BJBankColors.success
                              : BJBankColors.warning)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.hasPqcKeys == true ? 'Ativo' : 'Inativo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user?.hasPqcKeys == true
                            ? BJBankColors.success
                            : BJBankColors.warning,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Email Verificado'),
                  trailing: Icon(
                    user?.emailVerified == true
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: user?.emailVerified == true
                        ? BJBankColors.success
                        : BJBankColors.error,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Data export section
          _buildSectionHeader(context, 'Exportar Dados'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: ListTile(
              leading: Icon(Icons.download_outlined, color: BJBankColors.primary),
              title: const Text('Descarregar os meus dados'),
              subtitle: const Text('Exportar todos os seus dados em formato JSON'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExportDialog(context),
            ),
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // Danger zone
          _buildSectionHeader(context, 'Zona de Perigo'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            color: BJBankColors.error.withValues(alpha: 0.05),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.logout, color: BJBankColors.error),
                  title: Text(
                    'Terminar Todas as Sessões',
                    style: TextStyle(color: BJBankColors.error),
                  ),
                  subtitle: const Text('Sair de todos os dispositivos'),
                  onTap: () => _showLogoutAllDialog(context),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: BJBankColors.error.withValues(alpha: 0.2),
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: BJBankColors.error),
                  title: Text(
                    'Eliminar Conta',
                    style: TextStyle(color: BJBankColors.error),
                  ),
                  subtitle: const Text('Esta ação é irreversível'),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.xxl),
        ],
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

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar Dados'),
        content: const Text(
          'Os seus dados serão exportados em formato JSON. '
          'Este processo pode demorar alguns segundos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar Todas as Sessões'),
        content: const Text(
          'Será desconectado de todos os dispositivos, '
          'incluindo este. Terá de iniciar sessão novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _logoutAll(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: BJBankColors.error,
            ),
            child: const Text('Terminar Sessões'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutAll(BuildContext context) async {
    context.read<AccountProvider>().clear();
    await context.read<AuthProvider>().logout();
    await SecureStorageService.clearAll();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: BJBankColors.error),
            const SizedBox(width: BJBankSpacing.sm),
            const Text('Eliminar Conta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta ação é irreversível. Todos os seus dados serão eliminados permanentemente:',
              style: TextStyle(color: BJBankColors.onSurfaceVariant),
            ),
            const SizedBox(height: BJBankSpacing.md),
            const Text('• Dados pessoais'),
            const Text('• Histórico de transações'),
            const Text('• Chaves de criptografia'),
            const Text('• Configurações'),
            const SizedBox(height: BJBankSpacing.lg),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirme a sua palavra-passe',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            onPressed: () async {
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Introduza a sua palavra-passe'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await _deleteAccount(context, passwordController.text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: BJBankColors.error,
            ),
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Eliminar Conta'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, String password) async {
    setState(() => _isDeleting = true);

    try {
      final result = await AuthService.deleteAccount(password);

      if (!context.mounted) return;

      if (result.success) {
        context.read<AccountProvider>().clear();
        await SecureStorageService.clearAll();

        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (_) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta eliminada com sucesso'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Erro ao eliminar conta'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
