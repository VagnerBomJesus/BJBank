import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Invite Friends Screen
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  static const _referralCode = 'BJBANK2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convidar Amigos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        children: [
          const SizedBox(height: BJBankSpacing.lg),

          // Illustration
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: BJBankColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: BJBankColors.primary,
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Title
          Text(
            'Convide os seus amigos para o BJBank',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: BJBankSpacing.sm),

          Text(
            'Partilhe o futuro da banca segura com criptografia pós-quântica.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // Referral code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Column(
                children: [
                  Text(
                    'O seu código de referência',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: BJBankColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: BJBankSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BJBankSpacing.lg,
                          vertical: BJBankSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: BJBankColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: BJBankColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _referralCode,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: BJBankColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: BJBankSpacing.sm),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: _referralCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.copy,
                          color: BJBankColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.lg),

          // Share button
          FilledButton.icon(
            onPressed: () {
              Share.share(
                'Experimenta o BJBank - a app bancária com criptografia '
                'pós-quântica! Usa o meu código $_referralCode para aderir.',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Partilhar'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // How it works
          Text(
            'Como funciona',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Column(
                children: [
                  _buildStep(context, '1', 'Partilhe o seu código de referência'),
                  const SizedBox(height: BJBankSpacing.md),
                  _buildStep(context, '2', 'O seu amigo regista-se com o código'),
                  const SizedBox(height: BJBankSpacing.md),
                  _buildStep(context, '3', 'Ambos recebem benefícios exclusivos'),
                ],
              ),
            ),
          ),

          const SizedBox(height: BJBankSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: BJBankColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: BJBankSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
