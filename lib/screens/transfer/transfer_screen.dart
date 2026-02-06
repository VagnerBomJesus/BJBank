import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../services/firestore_service.dart';
import '../../services/pqc_service.dart';
import '../../services/auth_service.dart';
import '../../models/transaction_model.dart';
import 'transfer_confirmation_screen.dart';
import 'transfer_receipt_screen.dart';

/// Transfer Screen for BJBank
/// IBAN-based transfer with PQC signature
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ibanController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _pqcService = PqcService();

  bool _isLoading = false;
  bool _isSearchingRecipient = false;
  String? _errorMessage;
  String? _recipientName;

  @override
  void dispose() {
    _ibanController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _searchRecipient() async {
    final iban = _ibanController.text.replaceAll(' ', '').toUpperCase();
    if (iban.length < 15) return;

    setState(() {
      _isSearchingRecipient = true;
      _recipientName = null;
    });

    try {
      final account = await _firestoreService.findAccountByIban(iban);
      if (account != null) {
        final user = await _firestoreService.getUser(account.userId);
        if (user != null && mounted) {
          setState(() {
            _recipientName = user.name;
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching recipient: $e');
    }

    if (mounted) {
      setState(() {
        _isSearchingRecipient = false;
      });
    }
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    // Parse amount early for confirmation screen
    final amount = double.parse(
      _amountController.text.replaceAll(',', '.').replaceAll(' ', ''),
    );
    final recipientIban = _ibanController.text.replaceAll(' ', '').toUpperCase();

    // Show confirmation screen
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransferConfirmationScreen(
          recipientName: _recipientName ?? 'Destinatário',
          recipientIdentifier: _ibanController.text,
          amount: amount,
          description: _descriptionController.text,
          transferType: 'transfer',
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      // Get sender account
      final senderAccount = await _firestoreService.getPrimaryAccount(currentUserId);
      if (senderAccount == null) {
        throw Exception('Conta não encontrada');
      }

      // Get recipient account by IBAN
      final recipientAccount = await _firestoreService.findAccountByIban(recipientIban);
      if (recipientAccount == null) {
        throw Exception('IBAN destinatário não encontrado');
      }

      // Check if not sending to self
      if (recipientAccount.userId == currentUserId) {
        throw Exception('Não é possível transferir para si mesmo');
      }

      // Check balance
      if (amount > senderAccount.availableBalance) {
        throw Exception('Saldo insuficiente');
      }

      // Sign with PQC
      final signature = await _pqcService.signTransfer(
        senderId: currentUserId,
        receiverId: recipientAccount.userId,
        amount: amount,
        description: _descriptionController.text,
      );

      // Create transfer
      final transaction = await _firestoreService.createTransfer(
        senderId: currentUserId,
        senderAccountId: senderAccount.id,
        receiverId: recipientAccount.userId,
        receiverAccountId: recipientAccount.id,
        amount: amount,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : 'Transferência',
        type: TransactionType.transfer,
        pqcSignature: signature,
      );

      if (!mounted) return;

      // Navigate to receipt screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransferReceiptScreen(
            recipientName: _recipientName ?? 'Destinatário',
            recipientIdentifier: recipientAccount.maskedIban,
            amount: amount,
            description: _descriptionController.text,
            transferType: 'transfer',
            transactionId: transaction.id,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Transferir'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BJBankSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  decoration: BoxDecoration(
                    color: BJBankColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: BJBankColors.error),
                      const SizedBox(width: BJBankSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: BJBankColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BJBankSpacing.md),
              ],

              // IBAN field
              TextFormField(
                controller: _ibanController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                  _IbanFormatter(),
                ],
                onChanged: (_) => _searchRecipient(),
                decoration: InputDecoration(
                  labelText: 'IBAN do destinatário',
                  hintText: 'PT50 0000 0000 0000 0000 0000 0',
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  suffixIcon: _isSearchingRecipient
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _recipientName != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: _recipientName,
                  helperStyle: TextStyle(
                    color: BJBankColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira o IBAN';
                  }
                  final cleaned = value.replaceAll(' ', '');
                  if (cleaned.length < 15) {
                    return 'IBAN inválido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: BJBankSpacing.lg),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Montante',
                  hintText: '0,00',
                  prefixIcon: const Icon(Icons.euro),
                  prefixText: '€ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira o montante';
                  }
                  final amount = double.tryParse(
                    value.replaceAll(',', '.').replaceAll(' ', ''),
                  );
                  if (amount == null || amount <= 0) {
                    return 'Montante inválido';
                  }
                  if (amount < 0.01) {
                    return 'Montante mínimo: € 0,01';
                  }
                  return null;
                },
              ),

              const SizedBox(height: BJBankSpacing.lg),

              // Description field
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.done,
                maxLength: 140,
                decoration: InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Ex: Almoço, Renda, etc.',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: BJBankSpacing.xl),

              // PQC info
              Container(
                padding: const EdgeInsets.all(BJBankSpacing.md),
                decoration: BoxDecoration(
                  color: BJBankColors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BJBankColors.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: BJBankColors.tertiary,
                    ),
                    const SizedBox(width: BJBankSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transferência Segura',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: BJBankColors.tertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Protegida com assinatura CRYSTALS-Dilithium',
                            style: TextStyle(
                              fontSize: 12,
                              color: BJBankColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: BJBankSpacing.xl),

              // Transfer button
              FilledButton(
                onPressed: _isLoading ? null : _handleTransfer,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Transferir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// IBAN formatter - adds spaces every 4 characters
class _IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
