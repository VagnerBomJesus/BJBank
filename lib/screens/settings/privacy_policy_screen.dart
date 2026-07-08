import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Privacy Policy Screen
/// Detailed privacy and data handling practices
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          // Header
          Center(
            child: Text(
              'Política de Privacidade do BJBank',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Center(
            child: Text(
              'RGPD Compliant — Última atualização: Fevereiro 2026',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BJBankColors.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          _buildSection(
            context,
            '1. Responsável pelos Dados',
            'O BJBank é desenvolvido como projeto académico no Instituto Politécnico da Guarda.\n\n'
                'Responsável pelos Dados:\n'
                'Vagner Bom Jesus\n'
                'Email: vagneripg@gmail.com',
          ),

          _buildSection(
            context,
            '2. Dados Pessoais Recolhidos',
            'Recolhemos os seguintes dados pessoais:\n\n'
                '• Nome completo\n'
                '• Email\n'
                '• Número de telefone\n'
                '• Foto de perfil (opcional)\n'
                '• PIN (hash SHA-256)\n'
                '• Chaves criptográficas PQC\n'
                '• Histórico de transações\n'
                '• Dados de autenticação biométrica (armazenados localmente)',
          ),

          _buildSection(
            context,
            '3. Base Legal para Processamento',
            'Processamos os seus dados pessoais com base em:\n\n'
                '• Consentimento explícito (RGPD Art. 6(1)(a))\n'
                '• Interesse legítimo em investigação académica (Art. 6(1)(f))\n'
                '• Cumprimento de obrigações legais (Art. 6(1)(c))',
          ),

          _buildSection(
            context,
            '4. Finalidade do Processamento',
            'Os seus dados são processados para:\n\n'
                '• Crear e manter a sua conta bancária de demonstração\n'
                '• Processar transações de teste\n'
                '• Investigação científica sobre PQC em aplicações móveis\n'
                '• Melhorias de segurança e UX\n'
                '• Análise de logs para debugging',
          ),

          _buildSection(
            context,
            '5. Partilha de Dados',
            'Os seus dados podem ser partilhados com:\n\n'
                '• Google Firebase (hospedagem, autenticação)\n'
                '• Professor orientador da dissertação (dados anónimos)\n'
                '• Instituto Politécnico da Guarda (fins académicos)\n\n'
                'NÃO partilhamos dados com terceiros comerciais ou agências de publicidade.',
          ),

          _buildSection(
            context,
            '6. Armazenamento Seguro',
            'Os seus dados são protegidos através de:\n\n'
                '• Encriptação em repouso (Firebase + local)\n'
                '• TLS 1.3 em trânsito\n'
                '• FlutterSecureStorage para dados sensíveis\n'
                '• Firestore Security Rules (acesso uid-based)\n'
                '• Hashing SHA-256 para PINs\n\n'
                'As chaves criptográficas PQC são armazenadas APENAS no seu dispositivo, '
                'nunca no servidor.',
          ),

          _buildSection(
            context,
            '7. Retenção de Dados',
            'Retemos os seus dados enquanto a sua conta estiver ativa. '
                'Pode solicitar a eliminação completa a qualquer momento.\n\n'
                'Prazos de retenção:\n'
                '• Dados de conta: Enquanto activo + 30 dias após eliminação\n'
                '• Histórico de transações: 7 anos (conformidade legal)\n'
                '• Logs de acesso: 90 dias\n'
                '• Dados de backup: Até 365 dias',
          ),

          _buildSection(
            context,
            '8. Seus Direitos RGPD',
            'Tem o direito de:\n\n'
                '• Acesso: Solicitar cópia dos seus dados\n'
                '• Retificação: Corrigir dados imprecisos\n'
                '• Eliminação: "Direito ao esquecimento"\n'
                '• Restrição: Limitar processamento\n'
                '• Portabilidade: Receber dados em formato estruturado\n'
                '• Objeção: Opor-se ao processamento\n\n'
                'Para exercer estes direitos, contacte: vagneripg@gmail.com',
          ),

          _buildSection(
            context,
            '9. Biometria',
            'Se ativar autenticação biométrica:\n\n'
                '• Os dados biométricos são processados LOCALMENTE no seu dispositivo\n'
                '• Nunca são enviados para servidores\n'
                '• Nunca são armazenados por nós\n'
                '• Só a Apple/Android têm acesso (sistema operativo)',
          ),

          _buildSection(
            context,
            '10. Chaves Criptográficas PQC',
            'Segurança de chaves:\n\n'
                '• Chaves privadas: Armazenadas APENAS no seu dispositivo\n'
                '• Chaves públicas: Podem ser armazenadas em servidor (necessário para verificação)\n'
                '• Nenhuma chave privada sai do seu dispositivo\n'
                '• Padrão NIST FIPS 204 (CRYSTALS-Dilithium)',
          ),

          _buildSection(
            context,
            '11. Análise e Telemetria',
            'Coletamos dados de uso:\n\n'
                '• Operações de benchmark (latência, tamanho)\n'
                '• Eventos de autenticação (para segurança)\n'
                '• Erros e crashes (para debugging)\n\n'
                'Estes dados são anónimos e usados APENAS para pesquisa académica.',
          ),

          _buildSection(
            context,
            '12. Cookies e Armazenamento Local',
            'A aplicação utiliza:\n\n'
                '• SharedPreferences: Para preferências da app\n'
                '• FlutterSecureStorage: Para dados sensíveis\n'
                '• Firebase: Para autenticação e sessões\n\n'
                'Não utilizamos cookies tradicionais (aplicação móvel).',
          ),

          _buildSection(
            context,
            '13. Transferências Internacionais',
            'Os seus dados podem ser processados em:\n\n'
                '• Portugal (servidor de investigação)\n'
                '• EUA (Google Firebase)\n\n'
                'As transferências cumprem a GDPR através de:\n'
                '• Cláusulas padrão contratuais (SCC)\n'
                '• Adequação de proteção',
          ),

          _buildSection(
            context,
            '14. Menores de Idade',
            'O BJBank é destinado a investigação académica de nível superior. '
                'Não é intencionado para menores de 16 anos. '
                'Se descobrirmos que um utilizador é menor de idade, eliminaremos '
                'todos os seus dados imediatamente.',
          ),

          _buildSection(
            context,
            '15. Alterações a Esta Política',
            'Podemos atualizar esta Política a qualquer tempo. '
                'Notificaremos através de email ou notificação na app. '
                'O uso continuado representa aceitação.',
          ),

          _buildSection(
            context,
            '16. Reclamações e Contacto',
            'Tem direito a apresentar reclamação junto da Autoridade de Proteção de Dados (CNPD).\n\n'
                'Para questões de privacidade:\n'
                'Email: vagneripg@gmail.com\n'
                'Instituição: Instituto Politécnico da Guarda\n'
                'Orientador: Prof. Rui A. P. Perdigão',
          ),

          // Compliance badge
          const SizedBox(height: BJBankSpacing.lg),
          Card(
            color: BJBankColors.success.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: BJBankColors.success, size: 28),
                      const SizedBox(width: BJBankSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conformidade RGPD',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: BJBankColors.success,
                              ),
                            ),
                            const SizedBox(height: BJBankSpacing.xs),
                            Text(
                              'Esta aplicação cumpre com GDPR (Regulamento (UE) 2016/679)',
                              style: TextStyle(
                                fontSize: 12,
                                color: BJBankColors.onSurfaceVariant,
                              ),
                            ),
                          ],
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
