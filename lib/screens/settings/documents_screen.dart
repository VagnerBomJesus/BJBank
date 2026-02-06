import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Documents & Statements Screen - Placeholder
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos e Extratos'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(BJBankSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: BJBankSpacing.iconXxl,
                color: BJBankColors.onSurfaceVariant,
              ),
              const SizedBox(height: BJBankSpacing.lg),
              Text(
                'Documentos e Extratos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: BJBankSpacing.sm),
              Text(
                'Os seus extratos bancários e documentos fiscais estarão disponíveis aqui.',
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
