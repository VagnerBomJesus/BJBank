import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/external_account_model.dart';
import '../../providers/deposit_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'deposit_receipt_screen.dart';

/// Deposit Confirmation Screen
/// Shows deposit summary before confirming
class DepositConfirmationScreen extends StatefulWidget {
  const DepositConfirmationScreen({
    super.key,
    required this.externalAccount,
    required this.amount,
  });

  final ExternalAccountModel externalAccount;
  final double amount;

  @override
  State<DepositConfirmationScreen> createState() =>
      _DepositConfirmationScreenState();
}

class _DepositConfirmationScreenState extends State<DepositConfirmationScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Confirmar Deposito'),
        backgroundColor: BJBankColors.surface,
        foregroundColor: BJBankColors.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: BJBankSpacing.lg),

                  // Amount display
                  _buildAmountDisplay(),
                  const SizedBox(height: BJBankSpacing.xl),

                  // Transfer details card
                  _buildDetailsCard(),
                  const SizedBox(height: BJBankSpacing.lg),

                  // Security badge
                  _buildSecurityBadge(),
                ],
              ),
            ),
          ),

          // Confirm button
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        Text(
          'Valor a depositar',
          style: BJBankTypography.labelMedium.copyWith(
            color: BJBankColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BJBankSpacing.sm),
        Text(
          _formatAmount(widget.amount),
          style: BJBankTypography.displayMedium.copyWith(
            color: BJBankColors.success,
            fontWeight: FontWeight.w700,
            fontFamily: BJBankTypography.fontFamilyMono,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
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
          // From
          _buildDetailRow(
            label: 'De',
            icon: Icons.account_balance,
            title: widget.externalAccount.institutionName,
            subtitle: widget.externalAccount.maskedIban,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: BJBankSpacing.md),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: BJBankSpacing.sm),
                  child: Icon(
                    Icons.arrow_downward,
                    color: BJBankColors.primary,
                    size: 20,
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
          // To
          _buildDetailRow(
            label: 'Para',
            icon: Icons.account_balance_wallet,
            title: 'BJBank',
            subtitle: 'Conta a Ordem',
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isPrimary = false,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary
                ? BJBankColors.primaryLight
                : BJBankColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isPrimary ? BJBankColors.primary : BJBankColors.onSurfaceVariant,
            size: 24,
          ),
        ),
        const SizedBox(width: BJBankSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: BJBankTypography.labelSmall.copyWith(
                  color: BJBankColors.outline,
                ),
              ),
              Text(
                title,
                style: BJBankTypography.titleSmall.copyWith(
                  color: BJBankColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: BJBankTypography.bodySmall.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                  fontFamily: isPrimary ? null : BJBankTypography.fontFamilyMono,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.quantumLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BJBankColors.quantum.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user,
              color: BJBankColors.quantum,
              size: 20,
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transacao Segura',
                  style: BJBankTypography.labelMedium.copyWith(
                    color: BJBankColors.quantum,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Protegida por criptografia pos-quantica (CRYSTALS-Dilithium)',
                  style: BJBankTypography.bodySmall.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
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
            // Terms
            Text(
              'Ao confirmar, autoriza a transferencia do valor indicado da sua conta externa para o BJBank.',
              textAlign: TextAlign.center,
              style: BJBankTypography.bodySmall.copyWith(
                color: BJBankColors.outline,
              ),
            ),
            const SizedBox(height: BJBankSpacing.md),
            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
                  backgroundColor: BJBankColors.success,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BJBankColors.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 20),
                          const SizedBox(width: BJBankSpacing.xs),
                          Text(
                            'Confirmar Deposito',
                            style: BJBankTypography.labelLarge.copyWith(
                              color: BJBankColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '€$intPart,${parts[1]}';
  }

  Future<void> _onConfirm() async {
    setState(() => _isProcessing = true);

    try {
      final provider = context.read<DepositProvider>();

      // Get BJBank account ID (would come from account provider in production)
      // For demo, we'll use a placeholder
      const bjbankAccountId = 'primary'; // Should be fetched from AccountProvider

      final deposit = await provider.createDeposit(
        bjbankAccountId: bjbankAccountId,
        externalAccountId: widget.externalAccount.id,
        amount: widget.amount,
      );

      if (mounted) {
        // Navigate to receipt screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DepositReceiptScreen(
              deposit: deposit,
              externalAccount: widget.externalAccount,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar deposito: $e'),
            backgroundColor: BJBankColors.error,
          ),
        );
      }
    }
  }
}
