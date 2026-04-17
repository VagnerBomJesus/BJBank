import 'package:flutter/material.dart';
import '../../services/qr_code_service.dart';
import '../../theme/spacing.dart';

/// QR Code Generator Screen
///
/// Allows users to generate QR codes for their IBAN to receive payments
class QrCodeGeneratorScreen extends StatefulWidget {
  final String userIban;
  final String userName;

  const QrCodeGeneratorScreen({
    Key? key,
    required this.userIban,
    required this.userName,
  }) : super(key: key);

  @override
  State<QrCodeGeneratorScreen> createState() => _QrCodeGeneratorScreenState();
}

class _QrCodeGeneratorScreenState extends State<QrCodeGeneratorScreen> {
  final QrCodeService _qrService = QrCodeService();
  late TextEditingController _amountController;
  late TextEditingController _referenceController;

  String? _generatedQrCode;
  QrTransferData? _transferData;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _referenceController = TextEditingController();
    _generateQrCode();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _generateQrCode() async {
    setState(() => _isGenerating = true);

    try {
      final amount = _amountController.text.isNotEmpty
          ? double.tryParse(_amountController.text)
          : null;

      if (amount != null && amount <= 0) {
        _showError('Montante deve ser superior a 0');
        return;
      }

      final transferData = QrTransferData(
        recipientIban: widget.userIban,
        recipientName: widget.userName,
        amount: amount,
        reference: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
        createdAt: DateTime.now(),
      );

      final qrCode = _qrService.generateQrCode(transferData);

      setState(() {
        _generatedQrCode = qrCode;
        _transferData = transferData;
      });
    } catch (e) {
      _showError('Erro ao gerar código QR: ${e.toString()}');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareQrCode() async {
    if (_generatedQrCode == null) return;

    try {
      // TODO: Implement share functionality
      // Share.share(
      //   'Escaneie este código para enviar-me pagamentos:\n\n$_generatedQrCode',
      //   subject: 'Meu Código QR de Pagamento',
      // );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Função de partilha ainda em desenvolvimento'),
        ),
      );
    } catch (e) {
      _showError('Erro ao partilhar: ${e.toString()}');
    }
  }

  Future<void> _downloadQrCode() async {
    if (_generatedQrCode == null) return;

    try {
      // TODO: Implement download functionality
      // final directory = await getDownloadsDirectory();
      // final file = File('${directory.path}/qr_payment.png');
      // await file.writeAsString(_generatedQrCode!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Função de download ainda em desenvolvimento'),
        ),
      );
    } catch (e) {
      _showError('Erro ao descarregar: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar Código QR'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(BJBankSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    SizedBox(width: BJBankSpacing.sm),
                    Expanded(
                      child: Text(
                        'Partilhe o código QR para receber pagamentos diretos',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: BJBankSpacing.md),

            // Your details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(BJBankSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seus Dados',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: BJBankSpacing.md),
                    _DetailRow(label: 'Nome', value: widget.userName),
                    SizedBox(height: BJBankSpacing.sm),
                    _DetailRow(
                      label: 'IBAN',
                      value: _maskIban(widget.userIban),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: BJBankSpacing.md),

            // Optional fields
            Text(
              'Adicionar à Código QR (Opcional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),

            SizedBox(height: BJBankSpacing.sm),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Montante Fixo (€)',
                hintText: 'Deixe em branco para montante livre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: '€ ',
              ),
              onChanged: (_) => _generateQrCode(),
            ),

            SizedBox(height: BJBankSpacing.md),

            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                hintText: 'Ex: Aluguel, Fatura #123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => _generateQrCode(),
            ),

            SizedBox(height: BJBankSpacing.lg),

            // QR Code Display
            if (_isGenerating)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_generatedQrCode != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BJBankSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Placeholder for actual QR code display
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[400]!,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 100,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: BJBankSpacing.sm),
                            Text(
                              'QR Code\n(qr_flutter aqui)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: BJBankSpacing.md),
                    Text(
                      'Montante: ${_transferData?.amount != null ? '€${_transferData!.amount!.toStringAsFixed(2)}' : 'Livre'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

            SizedBox(height: BJBankSpacing.lg),

            // Action buttons
            if (_generatedQrCode != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareQrCode,
                  icon: const Icon(Icons.share),
                  label: const Text('Partilhar Código QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      vertical: BJBankSpacing.md,
                    ),
                  ),
                ),
              ),
              SizedBox(height: BJBankSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloadQrCode,
                  icon: const Icon(Icons.download),
                  label: const Text('Descarregar Código QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(
                      vertical: BJBankSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
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

/// Detail row widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
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
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
