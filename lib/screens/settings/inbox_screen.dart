import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pqc_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Inbox / Notifications Screen
///
/// Shows activity notifications derived from recent transactions,
/// PQC key security status, and system messages.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caixa de Entrada'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Atividade'),
            Tab(text: 'Segurança'),
            Tab(text: 'Sistema'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActivityTab(),
          _SecurityTab(),
          const _SystemTab(),
        ],
      ),
    );
  }
}

// ── Activity Tab ─────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final transactions = accountProvider.transactions;

    if (accountProvider.isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return _buildEmpty(
        context,
        Icons.notifications_none_outlined,
        'Sem atividade',
        'As suas transações e movimentos aparecerão aqui.',
      );
    }

    final recent = transactions.take(20).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      itemCount: recent.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _buildNotificationTile(context, recent[i]),
    );
  }

  Widget _buildNotificationTile(BuildContext context, Transaction tx) {
    final isIncoming = tx.isIncome;
    final color = isIncoming ? BJBankColors.success : BJBankColors.error;
    final icon = isIncoming
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: BJBankSpacing.xs,
        horizontal: BJBankSpacing.sm,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        isIncoming
            ? 'Recebeu ${tx.formattedAmount}'
            : 'Pagamento ${tx.formattedAmount}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tx.description, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                tx.formattedDate,
                style: TextStyle(
                  fontSize: 11,
                  color: BJBankColors.onSurfaceVariant,
                ),
              ),
              if (tx.signature != null) ...[
                const SizedBox(width: 6),
                _PqcBadge(),
              ],
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

// ── Security Tab ──────────────────────────────────────────────────────────────

class _SecurityTab extends StatefulWidget {
  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  bool? _hasKeys;
  String? _keyAlgorithm;
  DateTime? _keyCreatedAt;

  @override
  void initState() {
    super.initState();
    _loadKeyStatus();
  }

  Future<void> _loadKeyStatus() async {
    final keyPair = await PqcService().getKeyPair();
    if (mounted) {
      setState(() {
        _hasKeys = keyPair != null;
        _keyAlgorithm = keyPair?.algorithm.name;
        _keyCreatedAt = keyPair?.createdAt;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return ListView(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      children: [
        _buildSecurityCard(
          context,
          icon: Icons.key_outlined,
          iconColor: _hasKeys == true ? BJBankColors.success : BJBankColors.warning,
          title: 'Chave PQC',
          subtitle: _hasKeys == null
              ? 'A verificar…'
              : _hasKeys!
                  ? 'Ativa — ${_keyAlgorithm?.toUpperCase() ?? ''}'
                  : 'Sem chave gerada',
          detail: _keyCreatedAt != null
              ? 'Gerada a ${_formatDate(_keyCreatedAt!)}'
              : null,
          badge: _hasKeys == true ? 'SEGURO' : 'ATENÇÃO',
          badgeColor: _hasKeys == true ? BJBankColors.success : BJBankColors.warning,
        ),
        const SizedBox(height: BJBankSpacing.sm),
        _buildSecurityCard(
          context,
          icon: Icons.verified_outlined,
          iconColor: BJBankColors.quantum,
          title: 'Conformidade NIST',
          subtitle: 'CRYSTALS-Dilithium (FIPS 204) + CRYSTALS-Kyber (FIPS 203)',
          detail: 'Algoritmos padronizados em agosto de 2024',
          badge: 'FIPS 203/204',
          badgeColor: BJBankColors.quantum,
        ),
        const SizedBox(height: BJBankSpacing.sm),
        _buildSecurityCard(
          context,
          icon: Icons.lock_outline,
          iconColor: BJBankColors.primary,
          title: 'Sessão Ativa',
          subtitle: authProvider.user?.email ?? 'Utilizador desconhecido',
          detail: 'Autenticação Firebase com tokens JWT',
          badge: 'ATIVA',
          badgeColor: BJBankColors.success,
        ),
        const SizedBox(height: BJBankSpacing.sm),
        _buildSecurityCard(
          context,
          icon: Icons.storage_outlined,
          iconColor: Colors.teal,
          title: 'Armazenamento Seguro',
          subtitle: 'Keychain (iOS) / Keystore (Android)',
          detail: 'Chaves privadas encriptadas pelo sistema operativo',
          badge: 'ATIVO',
          badgeColor: BJBankColors.success,
        ),
        const SizedBox(height: BJBankSpacing.md),
        Card(
          color: BJBankColors.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(BJBankSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: BJBankColors.primary),
                const SizedBox(width: BJBankSpacing.sm),
                Expanded(
                  child: Text(
                    'As operações criptográficas são realizadas localmente no dispositivo. '
                    'As chaves privadas nunca saem do armazenamento seguro.',
                    style: TextStyle(fontSize: 12, color: BJBankColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? detail,
    required String badge,
    required Color badgeColor,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(BJBankSpacing.md),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13)),
            if (detail != null) ...[
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 11,
                  color: BJBankColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        isThreeLine: detail != null,
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── System Tab ────────────────────────────────────────────────────────────────

class _SystemTab extends StatelessWidget {
  const _SystemTab();

  static final _messages = [
    _SystemMessage(
      icon: Icons.system_update_outlined,
      iconColor: Colors.blue,
      title: 'BJBank v1.0.1',
      body: 'Versão atual. Inclui benchmarking PQC, handshake híbrido TLS+Kyber e ecrã de extratos.',
      date: DateTime(2026, 2, 18),
      tag: 'ATUALIZAÇÃO',
      tagColor: Colors.blue,
    ),
    _SystemMessage(
      icon: Icons.science_outlined,
      iconColor: Colors.teal,
      title: 'Benchmark PQC disponível',
      body: 'Aceda a Definições → Segurança → Benchmark PQC para comparar Dilithium/Kyber vs RSA/ECDSA com dados de referência NIST.',
      date: DateTime(2026, 2, 18),
      tag: 'NOVIDADE',
      tagColor: Colors.teal,
    ),
    _SystemMessage(
      icon: Icons.security_outlined,
      iconColor: Colors.green,
      title: 'Chaves PQC ativas',
      body: 'As suas chaves CRYSTALS-Dilithium foram geradas no registo e armazenadas de forma segura no Keychain/Keystore.',
      date: DateTime(2026, 2, 1),
      tag: 'SEGURANÇA',
      tagColor: Colors.green,
    ),
    _SystemMessage(
      icon: Icons.account_balance_outlined,
      iconColor: Colors.purple,
      title: 'Bem-vindo ao BJBank',
      body: 'Aplicação de banca móvel com criptografia pós-quântica. Todas as transferências são assinadas com CRYSTALS-Dilithium (NIST FIPS 204).',
      date: DateTime(2026, 1, 1),
      tag: 'SISTEMA',
      tagColor: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: BJBankSpacing.sm),
      itemBuilder: (context, i) => _buildCard(context, _messages[i]),
    );
  }

  Widget _buildCard(BuildContext context, _SystemMessage msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: msg.iconColor.withValues(alpha: 0.12),
              child: Icon(msg.icon, color: msg.iconColor, size: 20),
            ),
            const SizedBox(width: BJBankSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          msg.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: msg.tagColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          msg.tag,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: msg.tagColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BJBankSpacing.xs),
                  Text(msg.body, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: BJBankSpacing.xs),
                  Text(
                    '${msg.date.day.toString().padLeft(2, '0')}/${msg.date.month.toString().padLeft(2, '0')}/${msg.date.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: BJBankColors.onSurfaceVariant,
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
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _PqcBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: BJBankColors.quantum.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'PQC✓',
        style: TextStyle(
          fontSize: 9,
          color: BJBankColors.quantum,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Widget _buildEmpty(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(BJBankSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: BJBankSpacing.iconXxl, color: BJBankColors.onSurfaceVariant),
          const SizedBox(height: BJBankSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    ),
  );
}

class _SystemMessage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final DateTime date;
  final String tag;
  final Color tagColor;

  const _SystemMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.date,
    required this.tag,
    required this.tagColor,
  });
}
