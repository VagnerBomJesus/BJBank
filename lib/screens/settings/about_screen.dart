import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// About Screen - BJBank info, mission, PQC details
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre Nós'),
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
                  'Versão 1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BJBankColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // PQC Badge
          Card(
            color: BJBankColors.quantumLight,
            child: Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.security, color: BJBankColors.quantum, size: 32),
                  const SizedBox(width: BJBankSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Criptografia Pós-Quântica',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: BJBankColors.quantum,
                          ),
                        ),
                        const SizedBox(height: BJBankSpacing.xxs),
                        Text(
                          'Protegido com CRYSTALS-Dilithium Nível 3',
                          style: TextStyle(
                            fontSize: 13,
                            color: BJBankColors.quantum,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Mission
          Text(
            'A Nossa Missão',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Text(
                'O BJBank é um projeto de investigação que explora a aplicação '
                'de Criptografia Pós-Quântica (PQC) em serviços bancários móveis. '
                'O nosso objetivo é demonstrar como os algoritmos resistentes a '
                'computação quântica podem proteger transações financeiras, '
                'preparando a banca digital para a era quântica.',
                style: TextStyle(
                  color: BJBankColors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Links
          Text(
            'Informações Legais',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
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
}
