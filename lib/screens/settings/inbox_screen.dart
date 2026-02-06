import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Inbox Screen - Placeholder
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caixa de Entrada'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(BJBankSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: BJBankSpacing.iconXxl,
                color: BJBankColors.onSurfaceVariant,
              ),
              const SizedBox(height: BJBankSpacing.lg),
              Text(
                'Sem mensagens',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: BJBankSpacing.sm),
              Text(
                'As suas notificações e mensagens aparecerão aqui.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: BJBankSpacing.md),
              Text(
                'Em breve',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: BJBankColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
