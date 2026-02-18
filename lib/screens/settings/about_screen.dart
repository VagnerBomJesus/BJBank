import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// About Screen - BJBank academic info, PQC classification, research context
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o Projeto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          const SizedBox(height: BJBankSpacing.lg),

          // Logo & Version
          Center(
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
                  'Versão 1.0.1 — Fevereiro 2026',
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
                    'PoC Arquitetural PQC',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BJBankColors.quantum,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // Research Context Card
          _buildSectionTitle(context, 'Contexto Académico'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
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
                    label: 'Data',
                    value: 'Fevereiro 2026',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // PQC Classification Card
          _buildSectionTitle(context, 'Classificação PQC (ADR-001)'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
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
                          'Simulador de Interface PQC',
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
                  _buildPqcRow('O que está implementado:', true,
                      'Tamanhos exatos NIST FIPS 203/204, armazenamento seguro, '
                      'pipeline de assinatura completo, handshake híbrido, métricas experimentais'),
                  const SizedBox(height: BJBankSpacing.xs),
                  _buildPqcRow('O que não está:', false,
                      'Operações Module-LWE e Fiat-Shamir reais (requer liboqs via FFI)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // NIST Standards Card
          _buildSectionTitle(context, 'Normas NIST Implementadas'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Column(
              children: [
                _buildStandardTile(
                  icon: Icons.verified_outlined,
                  iconColor: BJBankColors.quantum,
                  title: 'NIST FIPS 204',
                  subtitle: 'CRYSTALS-Dilithium — Assinaturas Digitais',
                  badge: 'Assinatura',
                ),
                const Divider(height: 1, indent: 56),
                _buildStandardTile(
                  icon: Icons.key_outlined,
                  iconColor: Colors.teal,
                  title: 'NIST FIPS 203',
                  subtitle: 'CRYSTALS-Kyber — Key Encapsulation Mechanism',
                  badge: 'KEM',
                ),
                const Divider(height: 1, indent: 56),
                _buildStandardTile(
                  icon: Icons.swap_horiz_outlined,
                  iconColor: Colors.blue,
                  title: 'Handshake Híbrido',
                  subtitle: 'TLS ECDHE-P256 + Kyber768 + HKDF-SHA256',
                  badge: 'TLS+PQC',
                ),
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Scientific Contributions
          _buildSectionTitle(context, 'Contribuições Científicas'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContributionRow('1',
                      'Prova de conceito de banca móvel com PQC integrado end-to-end'),
                  _buildContributionRow('2',
                      'Métricas experimentais: latência, tamanho e overhead de handshake (~43ms, +2272 bytes)'),
                  _buildContributionRow('3',
                      'Benchmark PQC vs. clássico com dados NIST/SUPERCOP @ Intel i7-6500U'),
                  _buildContributionRow('4',
                      'Achado contra-intuitivo: Dilithium3 KeyGen 38% mais rápido que ECDSA-256 Sign, apesar de 45.7× maior'),
                ],
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Mission
          _buildSectionTitle(context, 'Missão'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Text(
                'O BJBank é um projeto de investigação que demonstra a viabilidade '
                'da Criptografia Pós-Quântica (PQC) em serviços bancários móveis. '
                'Prepara a banca digital para a era quântica, validando que os '
                'algoritmos NIST FIPS 203/204 são funcionalmente integráveis com '
                'overhead aceitável (<50ms por operação).',
                style: TextStyle(
                  color: BJBankColors.onSurfaceVariant,
                  height: 1.6,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Legal Info
          _buildSectionTitle(context, 'Informações Legais'),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Termos de Serviço'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Política de Privacidade'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.xxl),
        ],
      ),
    );
  }

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
