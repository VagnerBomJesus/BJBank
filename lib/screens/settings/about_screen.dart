import 'package:flutter/material.dart';
import '../../app_version.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../routes/app_routes.dart';

/// About Screen — BJBank: contexto academico, arquitectura PQC, stack tecnico.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o Projeto')),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          const SizedBox(height: BJBankSpacing.lg),
          _buildHeader(context),
          const SizedBox(height: BJBankSpacing.xl),

          _buildSectionTitle(context, 'Contexto Académico'),
          const SizedBox(height: BJBankSpacing.sm),
          _buildAcademicCard(),

          const SizedBox(height: BJBankSpacing.lg),

          _buildSectionTitle(context, 'Arquitectura PQC'),
          const SizedBox(height: BJBankSpacing.sm),
          _buildArchitectureCard(),

          const SizedBox(height: BJBankSpacing.lg),

          _buildSectionTitle(context, 'Stack Técnico'),
          const SizedBox(height: BJBankSpacing.sm),
          _buildStackCard(),

          const SizedBox(height: BJBankSpacing.lg),

          _buildSectionTitle(context, 'Normas NIST'),
          const SizedBox(height: BJBankSpacing.sm),
          _buildStandardsCard(),

          const SizedBox(height: BJBankSpacing.lg),

          _buildSectionTitle(context, 'Contribuições'),
          const SizedBox(height: BJBankSpacing.sm),
          _buildContributionsCard(),

          const SizedBox(height: BJBankSpacing.lg),

          _buildSectionTitle(context, 'Missão'),
          const SizedBox(height: BJBankSpacing.sm),
          _buildMissionCard(),

          const SizedBox(height: BJBankSpacing.lg),

          _buildSectionTitle(context, 'Informações Legais'),
          const SizedBox(height: BJBankSpacing.sm),
          _buildLegalCard(context),

          const SizedBox(height: BJBankSpacing.xxl),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: BJBankColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'BJ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          Text(
            'BJBank',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: BJBankSpacing.xxs),
          Text(
            'Versão ${AppVersion.displayString} — ${AppVersion.releaseDate}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: BJBankSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BJBankColors.quantum.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BJBankColors.quantum.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Cripto Pós-Quântica · FIPS 203/204',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BJBankColors.quantum,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _buildAcademicCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: Icons.person_outlined,
              label: 'Autor',
              value: 'Vagner Bom Jesus',
            ),
            const SizedBox(height: BJBankSpacing.sm),
            _buildInfoRow(
              icon: Icons.school_outlined,
              label: 'Orientador',
              value: 'Prof. Rui A. P. Perdigão',
            ),
            const SizedBox(height: BJBankSpacing.sm),
            _buildInfoRow(
              icon: Icons.account_balance_outlined,
              label: 'Instituição',
              value: 'Instituto Politécnico da Guarda',
            ),
            const SizedBox(height: BJBankSpacing.sm),
            _buildInfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Tese',
              value: 'Banca móvel pós-quântica (2025–2026)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchitectureCard() {
    return Card(
      color: BJBankColors.quantumLight,
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: BJBankColors.quantum, size: 28),
                const SizedBox(width: BJBankSpacing.sm),
                Expanded(
                  child: Text(
                    'Duas implementações comparadas',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: BJBankColors.quantum,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.sm),
            _buildPqcRow(
              'Kotlin (canónica):',
              true,
              'ML-KEM-768 + ML-DSA-65 via BouncyCastle. Chaves privadas '
                  'vivem no dispositivo. Assinatura é feita localmente antes '
                  'do envio.',
            ),
            const SizedBox(height: BJBankSpacing.sm),
            _buildPqcRow(
              'Flutter (pragmática):',
              true,
              'ML-DSA-65 server-side via Edge Function (@noble/post-quantum). '
                  'Sem libs Dart fiáveis para ML-DSA, a assinatura é delegada '
                  'ao Supabase pelo TLS. Decisão documentada como trade-off.',
            ),
            const SizedBox(height: BJBankSpacing.sm),
            _buildPqcRow(
              'Pipeline comum:',
              true,
              'Handshake com nonce + shared secret → HKDF-SHA256 → envelope '
                  'AES-256-GCM com IV derivado de transcript canónico. Verificação '
                  'ML-DSA acontece sempre no servidor antes da RPC atómica.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStackItem(
              icon: Icons.smartphone,
              color: Colors.blue,
              title: 'Frontend',
              detail:
                  'Flutter 3.x + Provider · Kotlin + Jetpack Compose (paralelo)',
            ),
            const Divider(height: BJBankSpacing.lg),
            _buildStackItem(
              icon: Icons.cloud,
              color: Colors.indigo,
              title: 'Backend',
              detail:
                  'Supabase: Auth + Postgrest + Realtime + Edge Functions (Deno)',
            ),
            const Divider(height: BJBankSpacing.lg),
            _buildStackItem(
              icon: Icons.storage,
              color: Colors.green,
              title: 'Base de dados',
              detail:
                  'Postgres 15 com RLS · 15 tabelas · RPCs SECURITY DEFINER',
            ),
            const Divider(height: BJBankSpacing.lg),
            _buildStackItem(
              icon: Icons.shield,
              color: BJBankColors.quantum,
              title: 'Cripto',
              detail:
                  'BouncyCastle ${AppVersion.bouncyCastleVersion} (Kotlin) · '
                  '@noble/post-quantum ${AppVersion.nobleVersion} (Deno) · '
                  'PointyCastle ${AppVersion.pointyCastleVersion} (HKDF, AES-GCM)',
            ),
            const Divider(height: BJBankSpacing.lg),
            _buildStackItem(
              icon: Icons.lock,
              color: Colors.orange,
              title: 'Auth',
              detail:
                  'Supabase Auth (email/password) · biométrico no Kotlin · '
                  'deep link bjbank://reset',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardsCard() {
    return Card(
      child: Column(
        children: [
          _buildStandardTile(
            icon: Icons.verified_outlined,
            iconColor: BJBankColors.quantum,
            title: 'NIST FIPS 204',
            subtitle: 'ML-DSA-65 (CRYSTALS-Dilithium) · Nível 3 (192 bits)',
            badge: 'Assinatura',
          ),
          const Divider(height: 1, indent: 56),
          _buildStandardTile(
            icon: Icons.key_outlined,
            iconColor: Colors.teal,
            title: 'NIST FIPS 203',
            subtitle: 'ML-KEM-768 (CRYSTALS-Kyber) · Nível 3 (192 bits)',
            badge: 'KEM',
          ),
          const Divider(height: 1, indent: 56),
          _buildStandardTile(
            icon: Icons.swap_horiz_outlined,
            iconColor: Colors.blue,
            title: 'Cifra simétrica',
            subtitle: 'AES-256-GCM com IV derivado e AAD canónico',
            badge: 'AEAD',
          ),
          const Divider(height: 1, indent: 56),
          _buildStandardTile(
            icon: Icons.calculate_outlined,
            iconColor: Colors.purple,
            title: 'Derivação',
            subtitle: 'HKDF-SHA-256 com info "BJBank-v1|session-keys"',
            badge: 'KDF',
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContributionRow(
              '1',
              'Implementação dupla (Kotlin canónica + Flutter pragmática) que '
                  'permite comparar PQC end-to-end vs. PQC delegada ao servidor',
            ),
            _buildContributionRow(
              '2',
              'Pipeline completo: handshake + assinatura ML-DSA-65 + envelope '
                  'AES-GCM + RPC atómica com debit/credit transaccional',
            ),
            _buildContributionRow(
              '3',
              'Migração documentada Firebase → Supabase (Auth, Postgres, Realtime, '
                  'Edge Functions) com RLS e RPCs SECURITY DEFINER',
            ),
            _buildContributionRow(
              '4',
              'Métricas experimentais comparativas: latência, tamanho de chaves '
                  'e assinaturas (ML-DSA-65: 1952 B pk, 3309 B sig)',
            ),
            _buildContributionRow(
              '5',
              'TOFU pinning da chave pública do servidor + transcript canónico '
                  'que previne MITM e replay',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Text(
          'O BJBank investiga a viabilidade da Criptografia Pós-Quântica em '
          'serviços bancários móveis perante o cenário "Harvest Now, Decrypt '
          'Later" (Y2Q). Demonstra que ML-DSA-65 e ML-KEM-768 (FIPS 203/204) '
          'são integráveis com overhead aceitável tanto numa arquitectura '
          'cliente-pesado (Kotlin com BouncyCastle local) como numa '
          'arquitectura cliente-leve (Flutter com assinatura delegada).',
          style: TextStyle(
            color: BJBankColors.onSurfaceVariant,
            height: 1.6,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Termos de Serviço'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.termsOfService),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.privacyPolicy),
          ),
        ],
      ),
    );
  }

  // ── Builders auxiliares ───────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: BJBankColors.primary),
        const SizedBox(width: BJBankSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: BJBankColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPqcRow(String label, bool isPositive, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isPositive ? Icons.check_circle_outline : Icons.highlight_off_outlined,
          size: 16,
          color: isPositive ? BJBankColors.success : BJBankColors.error,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: BJBankColors.onSurface),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStackItem({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: BJBankSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: BJBankColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandardTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          badge,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildContributionRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BJBankSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: BJBankColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: BJBankColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
