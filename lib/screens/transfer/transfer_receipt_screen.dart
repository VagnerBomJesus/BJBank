import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/border_radius.dart';
import '../../routes/app_routes.dart';

/// Transfer Receipt Screen
/// Shows transfer confirmation after successful transfer
class TransferReceiptScreen extends StatelessWidget {
  final String recipientName;
  final String recipientIdentifier;
  final double amount;
  final String description;
  final String transferType;
  final String transactionId;

  const TransferReceiptScreen({
    super.key,
    required this.recipientName,
    required this.recipientIdentifier,
    required this.amount,
    required this.description,
    required this.transferType,
    required this.transactionId,
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
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Comprovante'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(BJBankSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Success icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BJBankColors.success.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: BJBankColors.success,
                ),
              ),

              const SizedBox(height: BJBankSpacing.lg),

              Text(
                isMbWay
                    ? 'MB WAY enviado!'
                    : 'Transferência realizada!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: BJBankSpacing.xl),

              // Receipt card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.lg),
                  child: Column(
                    children: [
                      _buildRow(context, 'Destinatário', recipientName),
                      const Divider(height: BJBankSpacing.lg),
                      _buildRow(
                        context,
                        isMbWay ? 'Telemóvel' : 'IBAN',
                        recipientIdentifier,
                      ),
                      const Divider(height: BJBankSpacing.lg),
                      _buildRow(
                        context,
                        'Montante',
                        '€ ${_formatEuro(amount)}',
                      ),
                      if (description.isNotEmpty) ...[
                        const Divider(height: BJBankSpacing.lg),
                        _buildRow(context, 'Descrição', description),
                      ],
                      const Divider(height: BJBankSpacing.lg),
                      _buildRow(context, 'Data', dateStr),
                      const Divider(height: BJBankSpacing.lg),
                      _buildRow(
                        context,
                        'Referência',
                        transactionId.length > 8
                            ? transactionId.substring(0, 8).toUpperCase()
                            : transactionId.toUpperCase(),
                      ),
                      const Divider(height: BJBankSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Segurança',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: BJBankSpacing.sm,
                              vertical: BJBankSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: BJBankColors.quantum.withValues(alpha:0.1),
                              borderRadius: BJBankBorderRadius.mdRadius,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.security,
                                  size: 14,
                                  color: BJBankColors.quantum,
                                ),
                                const SizedBox(width: BJBankSpacing.xxs),
                                Text(
                                  'PQC Dilithium',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: BJBankColors.quantum,
                                    fontWeight: FontWeight.w600,
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

              const Spacer(flex: 2),

              // Done button
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.home,
                    (_) => false,
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(BJBankSpacing.inputHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BJBankBorderRadius.mdRadius,
                  ),
                ),
                child: Text(
                  'Concluir',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),

              const SizedBox(height: BJBankSpacing.lg),
            ],
          ),
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
