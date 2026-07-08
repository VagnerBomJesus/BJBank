import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/border_radius.dart';
import '../../theme/typography.dart';

/// Transfer Confirmation Screen
/// Review transfer details before executing
class TransferConfirmationScreen extends StatelessWidget {
  final String recipientName;
  final String recipientIdentifier; // IBAN or phone
  final double amount;
  final String description;
  final String transferType; // 'transfer' or 'mbway'

  const TransferConfirmationScreen({
    super.key,
    required this.recipientName,
    required this.recipientIdentifier,
    required this.amount,
    required this.description,
    required this.transferType,
  });

  String _formatEuro(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$intPart,${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isMbWay = transferType == 'mbway';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Confirmar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.lg),
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Amount display (mono style for currency values)
            Text(
              '€ ${_formatEuro(amount)}',
              style: BJBankTypography.balanceLarge.copyWith(
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(height: BJBankSpacing.xl),

            // Details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(BJBankSpacing.lg),
                child: Column(
                  children: [
                    _buildRow(
                      context,
                      'Tipo',
                      isMbWay ? 'MB WAY' : 'Transferência IBAN',
                    ),
                    const Divider(height: BJBankSpacing.lg),
                    _buildRow(context, 'Destinatário', recipientName),
                    const Divider(height: BJBankSpacing.lg),
                    _buildRow(
                      context,
                      isMbWay ? 'Telemóvel' : 'IBAN',
                      recipientIdentifier,
                    ),
                    if (description.isNotEmpty) ...[
                      const Divider(height: BJBankSpacing.lg),
                      _buildRow(context, 'Descrição', description),
                    ],
                    const Divider(height: BJBankSpacing.lg),
                    _buildRow(context, 'Montante', '€ ${_formatEuro(amount)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: BJBankSpacing.lg),

            // PQC badge
            Container(
              padding: const EdgeInsets.all(BJBankSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BJBankBorderRadius.smRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security,
                    size: BJBankSpacing.iconXs,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: BJBankSpacing.xs),
                  Text(
                    'Assinatura PQC CRYSTALS-Dilithium',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Confirm button
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(BJBankSpacing.inputHeight),
                backgroundColor: isMbWay
                    ? BJBankColors.mbwayRed
                    : colorScheme.primary,
                foregroundColor: isMbWay
                    ? BJBankColors.onPrimary
                    : colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BJBankBorderRadius.mdRadius,
                ),
              ),
              child: Text(
                isMbWay ? 'Confirmar MB WAY' : 'Confirmar Transferência',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isMbWay
                      ? BJBankColors.onPrimary
                      : colorScheme.onPrimary,
                ),
              ),
            ),

            const SizedBox(height: BJBankSpacing.md),

            // Cancel button
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(BJBankSpacing.minTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BJBankBorderRadius.mdRadius,
                ),
              ),
              child: const Text('Cancelar'),
            ),

            const SizedBox(height: BJBankSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: BJBankSpacing.md),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
