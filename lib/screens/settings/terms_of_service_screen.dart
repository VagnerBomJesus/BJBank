import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Terms of Service Screen
/// BJBank Terms and Conditions for academic use
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Serviço'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          // Header
          Center(
            child: Text(
              'Termos de Serviço do BJBank',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Center(
            child: Text(
              'Última atualização: Fevereiro 2026',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BJBankColors.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // 1. Natureza Académica
          _buildSection(
            context,
            '1. Natureza Académica da Aplicação',
            'O BJBank é uma prova de conceito (PoC) de investigação desenvolvida '
                'no Instituto Politécnico da Guarda para demonstrar a viabilidade de '
                'implementação de Criptografia Pós-Quântica (PQC) em serviços bancários móveis. '
                'Esta aplicação NÃO é um serviço bancário real e não deve ser utilizada para '
                'operações financeiras reais.',
          ),

          _buildSection(
            context,
            '2. Utilizador Aceita Termos',
            'Ao aceder e utilizar o BJBank, você concorda com estes Termos de Serviço. '
                'Se não concorda com qualquer parte destes termos, por favor não utilize a aplicação.',
          ),

          _buildSection(
            context,
            '3. Utilização Apropriada',
            'Você compromete-se a:\n'
                '• Usar a aplicação apenas para fins académicos e de pesquisa\n'
                '• Não utilizar a aplicação para atividades ilegais\n'
                '• Não tentar contornar qualquer medida de segurança\n'
                '• Não compartilhar as suas credenciais com terceiros\n'
                '• Não replicar ou clonar a aplicação sem permissão',
          ),

          _buildSection(
            context,
            '4. Limitações de Responsabilidade',
            'O BJBank é fornecido "como está" sem garantias de qualquer tipo. '
                'Os autores e a instituição não são responsáveis por:\n'
                '• Qualquer perda de dados\n'
                '• Interrupções de serviço\n'
                '• Problemas de segurança\n'
                '• Danos indiretos ou consequentes\n\n'
                'Esta é uma aplicação experimental. Não use para dados reais importantes.',
          ),

          _buildSection(
            context,
            '5. Dados do Utilizador',
            'Os dados que fornece (nome, email, telefone) são armazenados em Firebase. '
                'Pode eliminar a sua conta a qualquer momento através das Definições > Privacidade, '
                'o que resultará na eliminação permanente de todos os seus dados.',
          ),

          _buildSection(
            context,
            '6. Conformidade com NIST',
            'O BJBank implementa os algoritmos:\n'
                '• CRYSTALS-Dilithium (NIST FIPS 204) — Assinaturas Digitais\n'
                '• CRYSTALS-Kyber (NIST FIPS 203) — Encapsulamento de Chaves\n\n'
                'Estes são os algoritmos padronizados pelo NIST em agosto de 2024 '
                'como resistentes a ataques quânticos.',
          ),

          _buildSection(
            context,
            '7. Segurança',
            'O BJBank implementa várias camadas de segurança:\n'
                '• PIN de 6 dígitos com SHA-256 (10.000 iterações)\n'
                '• Autenticação biométrica (Face ID, Fingerprint)\n'
                '• Armazenamento seguro de chaves (FlutterSecureStorage)\n'
                '• Assinatura digital de transações com PQC\n'
                '• TLS 1.3 para todas as comunicações\n\n'
                'No entanto, como aplicação experimental, não garantimos segurança '
                'em nível de produção.',
          ),

          _buildSection(
            context,
            '8. Propriedade Intelectual',
            'O código-fonte do BJBank é académico e está protegido por direitos de autor. '
                'Todos os direitos reservados © 2026 Vagner Bom Jesus e '
                'Instituto Politécnico da Guarda.\n\n'
                'Pode ser utilizado para fins educacionais e de investigação com '
                'a devida atribuição.',
          ),

          _buildSection(
            context,
            '9. Alterações aos Termos',
            'Reservamos o direito de alterar estes Termos a qualquer momento. '
                'As alterações entram em vigor imediatamente após publicação. '
                'O seu uso contínuo da aplicação constitui aceitação dos termos alterados.',
          ),

          _buildSection(
            context,
            '10. Lei Aplicável',
            'Estes Termos de Serviço são regidos pelas leis de Portugal. '
                'Qualquer disputa será resolvida nos tribunais competentes de Portugal.',
          ),

          _buildSection(
            context,
            '11. Contacto',
            'Para questões sobre estes Termos de Serviço, contacte:\n'
                'Email: vagneripg@gmail.com\n'
                'Instituição: Instituto Politécnico da Guarda',
          ),

          const SizedBox(height: BJBankSpacing.xxl),

          // Acceptance button
          Card(
            color: BJBankColors.success.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: BJBankColors.success),
                      const SizedBox(width: BJBankSpacing.sm),
                      Expanded(
                        child: Text(
                          'Ao usar o BJBank, você concorda com estes Termos de Serviço',
                          style: TextStyle(
                            color: BJBankColors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BJBankSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: BJBankColors.primary,
            ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Text(
            content,
            style: TextStyle(
              color: BJBankColors.onSurfaceVariant,
              height: 1.6,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
