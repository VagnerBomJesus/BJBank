import 'package:flutter/material.dart';
import '../../services/qr_code_service.dart';
import '../../theme/spacing.dart';

/// QR Payment Confirmation Screen
///
/// Shows payment details from scanned QR code and allows user to:
/// - Review payment details
/// - Edit amount if not specified in QR
/// - Confirm or cancel payment
class QrPaymentConfirmationScreen extends StatefulWidget {
  final QrTransferData transferData;

  const QrPaymentConfirmationScreen({
    Key? key,
    required this.transferData,
  }) : super(key: key);

  @override
  State<QrPaymentConfirmationScreen> createState() =>
      _QrPaymentConfirmationScreenState();
}

class _QrPaymentConfirmationScreenState
    extends State<QrPaymentConfirmationScreen> {
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transferData.amount?.toStringAsFixed(2) ?? '',
    );
    _referenceController = TextEditingController(
      text: widget.transferData.reference ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    // Validate amount if required
    if (widget.transferData.amount == null &&
        _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor insira o montante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Validate amount format
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        throw Exception('Montante inválido');
      }

      // TODO: Create transfer transaction
      // Transfer(
      //   recipientIban: widget.transferData.recipientIban,
      //   recipientName: widget.transferData.recipientName,
      //   amount: amount,
      //   reference: _referenceController.text.isNotEmpty
      //       ? _referenceController.text
      //       : widget.transferData.reference,
      //   type: TransferType.qrPayment,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pagamento'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(BJBankSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beneficiário',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: BJBankSpacing.sm),
                    Text(
                      widget.transferData.recipientName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: BJBankSpacing.md),
                    Text(
                      'IBAN',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: BJBankSpacing.xs),
                    Text(
                      _maskIban(widget.transferData.recipientIban),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: BJBankSpacing.md),

            // Amount field (editable if not in QR)
            if (widget.transferData.amount == null)
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montante (€)',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixText: '€ ',
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Montante',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      SizedBox(height: BJBankSpacing.sm),
                      Text(
                        '€${widget.transferData.amount!.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: BJBankSpacing.md),

            // Reference field
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Referência (Opcional)',
                hintText: 'Descrição do pagamento',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),

            // Description from QR (if available)
            if (widget.transferData.description != null) ...[
              SizedBox(height: BJBankSpacing.md),
              Card(
                color: Colors.blue.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descrição QR',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      SizedBox(height: BJBankSpacing.xs),
                      Text(
                        widget.transferData.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: BJBankSpacing.lg),

            // Summary card
            Container(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Beneficiário',
                    value: widget.transferData.recipientName,
                  ),
                  Divider(height: BJBankSpacing.md),
                  _SummaryRow(
                    label: 'Montante',
                    value:
                        '€${(widget.transferData.amount ?? double.tryParse(_amountController.text) ?? 0).toStringAsFixed(2)}',
                    isAmount: true,
                  ),
                  if (_referenceController.text.isNotEmpty) ...[
                    Divider(height: BJBankSpacing.md),
                    _SummaryRow(
                      label: 'Referência',
                      value: _referenceController.text,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: BJBankSpacing.lg),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                SizedBox(width: BJBankSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _confirmPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Confirmar',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _maskIban(String iban) {
    if (iban.length < 8) return iban;
    return '${iban.substring(0, 4)}****${iban.substring(iban.length - 4)}';
  }
}

/// Summary row widget
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isAmount;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isAmount ? FontWeight.w600 : FontWeight.normal,
                color: isAmount ? Colors.green : null,
              ),
        ),
      ],
    );
  }
}
