import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../routes/app_routes.dart';

/// Settings Screen
/// App configuration, security, and account management
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final user = authProvider.user;

    final topPadding = MediaQuery.of(context).padding.top;

    return ListView(
      padding: EdgeInsets.only(
        top: topPadding + BJBankSpacing.md,
        bottom: BJBankSpacing.md,
      ),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BJBankSpacing.lg,
            0,
            BJBankSpacing.lg,
            BJBankSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Definições',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: BJBankColors.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gerir a tua conta e preferências',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: BJBankSpacing.sm),

        // 1. Profile Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(BJBankSpacing.md),
              leading: _buildProfileAvatar(user?.photoUrl, user?.initials),
              title: Text(
                user?.name ?? 'Utilizador',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(user?.email ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.profile);
              },
            ),
          ),
        ),

        const SizedBox(height: BJBankSpacing.lg),

        // 2. Conta section
        _buildSectionHeader(context, 'Conta'),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
          child: Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.account_balance_outlined, color: BJBankColors.primary),
                  title: const Text('Detalhes da Conta'),
                  subtitle: const Text('IBAN, saldos e informações'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.accountDetails),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: BJBankColors.mbwayRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: const Text('MB WAY'),
                  subtitle: const Text('Definições e limites'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.mbwaySettings),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.analytics_outlined, color: BJBankColors.primary),
                  title: const Text('Análise Pessoal'),
                  subtitle: const Text('Resumo financeiro e gráficos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.analysis),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Documentos e Extratos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.documents),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Alterar palavra-passe'),
                  subtitle: const Text('Alterar a sua palavra-passe atual'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Repor palavra-passe'),
                  subtitle: const Text('Enviar email de recuperação'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _handleResetPassword(context, user?.email),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: BJBankSpacing.lg),

        // 3. Segurança section (PIN, Biometria)
        _buildSectionHeader(context, 'Segurança'),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
          child: Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text('Proteção por PIN'),
                  subtitle: Text(
                    settingsProvider.pinEnabled
                        ? 'Ativada'
                        : 'Desativada',
                  ),
                  value: settingsProvider.pinEnabled,
                  onChanged: (value) => _handlePinToggle(context, value, settingsProvider),
                ),
                if (settingsProvider.pinEnabled) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('Alterar PIN'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePinDialog(context),
                  ),
                ],
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Biometria'),
                  subtitle: Text(
                    settingsProvider.biometricsEnabled
                        ? 'Ativada'
                        : 'Desativada',
                  ),
                  value: settingsProvider.biometricsEnabled,
                  onChanged: (value) async {
                    final result = await settingsProvider.setBiometricsEnabled(value);
                    if (!result && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Não foi possível ativar a biometria'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: BJBankSpacing.lg),

        // 4. Geral section
        _buildSectionHeader(context, 'Geral'),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
          child: Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: const Text('Caixa de Entrada'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.inbox),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacidade e Dados'),
                  subtitle: const Text('Gerir dados e eliminar conta'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Convidar Amigos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.inviteFriends),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: BJBankSpacing.lg),

        // 5. Informações section
        _buildSectionHeader(context, 'Informações'),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
          child: Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.help_outline, color: BJBankColors.primary),
                  title: const Text('Ajuda'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.help),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre Nós'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.about),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versão'),
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(color: BJBankColors.onSurfaceVariant),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.security, color: BJBankColors.quantum),
                  title: const Text('Criptografia PQC'),
                  subtitle: const Text('CRYSTALS-Dilithium Nível 3'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BJBankSpacing.sm,
                      vertical: BJBankSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: BJBankColors.quantum.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ativo',
                      style: TextStyle(
                        fontSize: 12,
                        color: BJBankColors.quantum,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: BJBankSpacing.xl),

        // 6. Logout button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Terminar Sessão',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: BJBankSpacing.xxl),
      ],
    );
  }

  Widget _buildProfileAvatar(String? photoUrl, String? initials) {
    ImageProvider? imageProvider;
    if (photoUrl != null && photoUrl.startsWith('data:image')) {
      final base64Data = photoUrl.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64Data));
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: BJBankColors.primaryContainer,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              initials ?? '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BJBankColors.onPrimaryContainer,
              ),
            )
          : null,
    );
  }

  Future<void> _handlePinToggle(
    BuildContext context,
    bool value,
    SettingsProvider settingsProvider,
  ) async {
    if (value) {
      // Check if PIN already exists
      final hasPinSet = await SecureStorageService.isPinSet();
      if (hasPinSet) {
        await settingsProvider.setPinEnabled(true);
      } else {
        // Navigate to PIN setup, then enable on return
        if (!context.mounted) return;
        final result = await Navigator.of(context).pushNamed(AppRoutes.pinSetup);
        if (result == true) {
          await settingsProvider.setPinEnabled(true);
        }
      }
    } else {
      // Confirm disable
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desativar PIN'),
          content: const Text(
            'Tem a certeza que deseja desativar a proteção por PIN? O seu PIN será removido.',
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
              child: const Text('Desativar'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await settingsProvider.setPinEnabled(false);
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BJBankSpacing.lg,
        0,
        BJBankSpacing.lg,
        BJBankSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: BJBankColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN atual',
                counterText: '',
              ),
            ),
            const SizedBox(height: BJBankSpacing.md),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Novo PIN',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (oldPinController.text.length == 6 &&
                  newPinController.text.length == 6) {
                final success = await SecureStorageService.changePin(
                  oldPinController.text,
                  newPinController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'PIN alterado com sucesso'
                            : 'PIN atual incorreto',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar Palavra-passe'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Palavra-passe atual',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: BJBankSpacing.md),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova palavra-passe',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: BJBankSpacing.md),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova palavra-passe',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  if (value != newPasswordController.text) {
                    return 'As palavras-passe não coincidem';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final result = await AuthService.changePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? 'Palavra-passe alterada com sucesso'
                          : result.errorMessage ?? 'Erro ao alterar palavra-passe',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleResetPassword(BuildContext context, String? email) async {
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email não disponível'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Repor Palavra-passe'),
        content: Text(
          'Será enviado um email de recuperação para:\n$email',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await AuthService.sendPasswordReset(email);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Email de recuperação enviado com sucesso'
                : result.errorMessage ?? 'Erro ao enviar email',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar Sessão'),
        content: const Text('Tem a certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              context.read<AccountProvider>().clear();
              await context.read<AuthProvider>().logout();
              await SecureStorageService.clearAll();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (_) => false,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
