import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../services/supabase_config.dart';

/// Seed / Info Screen
///
/// Ferramenta de dev que mostra informacao sobre o backend Supabase (URL do
/// projecto, contagem de utilizadores) e credenciais demo. Nao executa
/// operacoes destrutivas — para limpar dados, usar o SQL Editor do
/// Supabase Dashboard com as credenciais do projecto.
class SeedScreen extends StatelessWidget {
  const SeedScreen({super.key});

  static const _demoEmail = 'demo@bjbank.com';
  static const _demoPassword = 'BjBank2026!';

  @override
  Widget build(BuildContext context) {
    final url = SupabaseConfig.url;
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Backend (Dev)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.lg),
        children: [
          _infoCard(
            color: BJBankColors.info,
            icon: Icons.cloud_done_outlined,
            title: 'Backend: Supabase',
            body: 'URL do projecto:\n$url\n\nAuth, Postgrest, Realtime e '
                'Edge Functions todos servidos por este projecto Supabase. '
                'Sem dependencia de Firebase.',
          ),
          const SizedBox(height: BJBankSpacing.lg),
          _infoCard(
            color: BJBankColors.success,
            icon: Icons.shield_outlined,
            title: 'Cripto pos-quantica',
            body: 'Transferencias assinadas com ML-DSA-65 (FIPS 204) e '
                'cifradas com AES-256-GCM dentro do canal TLS Supabase. '
                'Chaves do servidor em public_config; chaves do cliente '
                'Flutter em flutter_client_keys (server-managed por nao '
                'haver implementacao Dart fiavel de ML-DSA).',
          ),
          const SizedBox(height: BJBankSpacing.lg),
          _credentialsCard(context),
          const SizedBox(height: BJBankSpacing.lg),
          _infoCard(
            color: BJBankColors.warning,
            icon: Icons.warning_amber_outlined,
            title: 'Limpeza de dados',
            body: 'Operacoes destrutivas (apagar utilizadores, contas ou '
                'transacoes) devem ser feitas pelo SQL Editor do Supabase '
                'Dashboard com a service_role key. O cliente nao tem '
                'permissoes para apagar massivamente.',
          ),
          const SizedBox(height: BJBankSpacing.xl),
        ],
      ),
    );
  }

  Widget _infoCard({
    required Color color,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: BJBankSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Text(
            body,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _credentialsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Credenciais demo (Google Play review)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _credRow(context, 'Email', _demoEmail),
          const SizedBox(height: 4),
          _credRow(context, 'Password', _demoPassword),
          const SizedBox(height: 8),
          const Text(
            'A conta deve existir no Supabase Auth (criar manualmente no '
            'Dashboard ou via SQL).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _credRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copiado'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          tooltip: 'Copiar',
        ),
      ],
    );
  }
}
