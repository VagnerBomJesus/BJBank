import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Help Screen with FAQ and contact info
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'question': 'O que é Criptografia Pós-Quântica (PQC)?',
      'answer':
          'A Criptografia Pós-Quântica utiliza algoritmos resistentes a ataques '
              'de computadores quânticos. O BJBank implementa CRYSTALS-Dilithium '
              'Nível 3 para assinar digitalmente todas as transações, garantindo '
              'segurança mesmo contra futuras ameaças quânticas.',
    },
    {
      'question': 'Como funcionam as transferências no BJBank?',
      'answer':
          'As transferências são processadas através do sistema SEPA e assinadas '
              'digitalmente com criptografia pós-quântica. Pode transferir via IBAN '
              'ou MB WAY de forma segura e instantânea.',
    },
    {
      'question': 'As minhas transações são seguras?',
      'answer':
          'Sim. Cada transação é assinada com CRYSTALS-Dilithium e verificada '
              'pela nossa infraestrutura. Além disso, todos os dados são encriptados '
              'em trânsito e em repouso.',
    },
    {
      'question': 'Como ativo a autenticação biométrica?',
      'answer':
          'Vá a Configurações > Segurança e ative a opção "Biometria". '
              'É necessário ter um PIN configurado previamente.',
    },
    {
      'question': 'Posso usar o BJBank em vários dispositivos?',
      'answer':
          'Sim, pode iniciar sessão em múltiplos dispositivos. Cada dispositivo '
              'terá o seu próprio par de chaves PQC para máxima segurança.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          // FAQ section
          Text(
            'Perguntas Frequentes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ExpansionTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: BJBankColors.primary,
                    ),
                    title: Text(
                      _faqs[i]['question']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          BJBankSpacing.md,
                          0,
                          BJBankSpacing.md,
                          BJBankSpacing.md,
                        ),
                        child: Text(
                          _faqs[i]['answer']!,
                          style: TextStyle(
                            color: BJBankColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // Contact section
          Text(
            'Contacte-nos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email_outlined, color: BJBankColors.primary),
                  title: const Text('Email'),
                  subtitle: const Text('suporte@bjbank.pt'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.phone_outlined, color: BJBankColors.primary),
                  title: const Text('Telefone'),
                  subtitle: const Text('+351 210 000 000'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.chat_outlined, color: BJBankColors.primary),
                  title: const Text('Chat'),
                  subtitle: const Text('Disponível 24/7'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BJBankSpacing.sm,
                      vertical: BJBankSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: BJBankColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: BJBankColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
