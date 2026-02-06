import 'package:flutter/material.dart';
import '../../models/deposit_model.dart';
import '../../models/external_account_model.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Deposit Receipt Screen
/// Shows deposit confirmation receipt
class DepositReceiptScreen extends StatelessWidget {
  const DepositReceiptScreen({
    super.key,
    required this.deposit,
    required this.externalAccount,
  });

  final DepositModel deposit;
  final ExternalAccountModel externalAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BJBankSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: BJBankSpacing.xl),

                    // Success animation
                    _buildSuccessIcon(),
                    const SizedBox(height: BJBankSpacing.lg),

                    // Status text
                    Text(
                      deposit.isCompleted
                          ? 'Deposito Concluido!'
                          : 'Deposito em Processamento',
                      style: BJBankTypography.headlineSmall.copyWith(
                        color: BJBankColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: BJBankSpacing.xs),
                    Text(
                      deposit.isCompleted
                          ? 'O valor foi creditado na sua conta BJBank'
                          : 'O seu deposito esta a ser processado',
                      style: BJBankTypography.bodyMedium.copyWith(
                        color: BJBankColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: BJBankSpacing.xl),

                    // Amount
                    Text(
                      deposit.formattedAmount,
                      style: BJBankTypography.displayMedium.copyWith(
                        color: BJBankColors.success,
                        fontWeight: FontWeight.w700,
                        fontFamily: BJBankTypography.fontFamilyMono,
                      ),
                    ),
                    const SizedBox(height: BJBankSpacing.xl),

                    // Receipt details
                    _buildReceiptCard(),
                    const SizedBox(height: BJBankSpacing.lg),

                    // PQC verification
                    if (deposit.pqcSignature != null)
                      _buildPqcVerification(),
                  ],
                ),
              ),
            ),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: deposit.isCompleted
            ? BJBankColors.successLight
            : BJBankColors.warningLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        deposit.isCompleted
            ? Icons.check_circle
            : Icons.schedule,
        size: 56,
        color: deposit.isCompleted
            ? BJBankColors.success
            : BJBankColors.warning,
      ),
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BJBankColors.outlineVariant),
      ),
      child: Column(
        children: [
          _buildReceiptRow('ID da Transacao', deposit.id.substring(0, 8)),
          const Divider(height: BJBankSpacing.lg),
          _buildReceiptRow('De', externalAccount.institutionName),
          _buildReceiptRow('IBAN Origem', externalAccount.maskedIban),
          const Divider(height: BJBankSpacing.lg),
          _buildReceiptRow('Para', 'BJBank'),
          _buildReceiptRow('Tipo', 'Conta a Ordem'),
          const Divider(height: BJBankSpacing.lg),
          _buildReceiptRow('Estado', deposit.statusDisplayName),
          _buildReceiptRow(
            'Data',
            _formatDateTime(deposit.createdAt ?? DateTime.now()),
          ),
          if (deposit.completedAt != null) ...[
            _buildReceiptRow(
              'Concluido',
              _formatDateTime(deposit.completedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: BJBankTypography.bodySmall.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: BJBankTypography.bodySmall.copyWith(
              color: BJBankColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPqcVerification() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.quantumLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified,
                color: BJBankColors.quantum,
                size: 20,
              ),
              const SizedBox(width: BJBankSpacing.xs),
              Text(
                'Assinatura PQC Verificada',
                style: BJBankTypography.labelMedium.copyWith(
                  color: BJBankColors.quantum,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Text(
            'Esta transacao foi assinada digitalmente usando CRYSTALS-Dilithium (Nivel 3)',
            textAlign: TextAlign.center,
            style: BJBankTypography.bodySmall.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          // Show truncated signature
          Container(
            padding: const EdgeInsets.all(BJBankSpacing.xs),
            decoration: BoxDecoration(
              color: BJBankColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${deposit.pqcSignature!.substring(0, 32)}...',
              style: BJBankTypography.bodySmall.copyWith(
                color: BJBankColors.outline,
                fontFamily: BJBankTypography.fontFamilyMono,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Primary button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Go back to home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
                  backgroundColor: BJBankColors.primary,
                ),
                child: Text(
                  'Voltar ao Inicio',
                  style: BJBankTypography.labelLarge.copyWith(
                    color: BJBankColors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: BJBankSpacing.sm),
            // Secondary button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Share receipt
                  _shareReceipt(context);
                },
                icon: const Icon(Icons.share),
                label: const Text('Partilhar Comprovativo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareReceipt(BuildContext context) {
    // In production, implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de partilha em desenvolvimento'),
        backgroundColor: BJBankColors.info,
      ),
    );
  }
}
