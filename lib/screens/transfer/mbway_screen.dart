import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../services/firestore_service.dart';
import '../../services/pqc_service.dart';
import '../../services/auth_service.dart';
import '../../models/transaction_model.dart';
import '../../models/mbway_contact_model.dart';
import '../../providers/account_provider.dart';
import 'transfer_confirmation_screen.dart';
import 'transfer_receipt_screen.dart';

/// MB WAY Screen for BJBank
/// Phone-based instant transfer (Portugal)
class MbWayScreen extends StatefulWidget {
  const MbWayScreen({super.key});

  @override
  State<MbWayScreen> createState() => _MbWayScreenState();
}

class _MbWayScreenState extends State<MbWayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _pqcService = PqcService();

  bool _isLoading = false;
  bool _isSearchingRecipient = false;
  String? _errorMessage;
  String? _recipientName;

  // Recent contacts and limits
  List<MbWayContact> _recentContacts = [];
  Map<String, dynamic> _usageInfo = {};
  bool _rateLimited = false;

  @override
  void initState() {
    super.initState();
    _loadRecentContacts();
    _loadUsageInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentContacts() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    try {
      final contacts = await _firestoreService.getMbWayRecentContacts(userId);
      if (mounted) {
        setState(() {
          _recentContacts = contacts;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent contacts: $e');
    }
  }

  Future<void> _loadUsageInfo() async {
    final accountProvider = context.read<AccountProvider>();
    final account = accountProvider.primaryAccount;
    if (account == null) return;

    try {
      final info = await _firestoreService.getMbWayUsageInfo(account.id);
      if (mounted) {
        setState(() => _usageInfo = info);
      }
    } catch (e) {
      debugPrint('Error loading usage info: $e');
    }
  }

  void _selectRecentContact(MbWayContact contact) {
    final cleaned = contact.phone.replaceAll(RegExp(r'[^\d]'), '');
    String phoneDigits = cleaned;
    if (cleaned.startsWith('351') && cleaned.length == 12) {
      phoneDigits = cleaned.substring(3);
    }

    _phoneController.text = _formatPhone(phoneDigits);
    setState(() {
      _recipientName = contact.name;
    });
  }

  String _formatPhone(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  Future<void> _searchRecipient() async {
    final phone = '+351${_phoneController.text.replaceAll(' ', '')}';
    if (_phoneController.text.replaceAll(' ', '').length < 9) return;

    setState(() {
      _isSearchingRecipient = true;
      _recipientName = null;
      _rateLimited = false;
    });

    try {
      final accountProvider = context.read<AccountProvider>();
      final myAccount = accountProvider.primaryAccount;

      // Use rate limited search if we have an account
      final account = myAccount != null
          ? await _firestoreService.findAccountByPhoneRateLimited(phone, myAccount.id)
          : await _firestoreService.findAccountByPhone(phone);

      if (account != null) {
        final user = await _firestoreService.getUser(account.userId);
        if (user != null && mounted) {
          setState(() {
            _recipientName = user.name;
          });
        }
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Limite de pesquisas')) {
        setState(() => _rateLimited = true);
      }
      debugPrint('Error searching recipient: $e');
    }

    if (mounted) {
      setState(() {
        _isSearchingRecipient = false;
      });
    }
  }

  Future<void> _handleMbWayTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    // Parse amount early for confirmation screen
    final amount = double.parse(
      _amountController.text.replaceAll(',', '.').replaceAll(' ', ''),
    );
    final recipientPhone = '+351${_phoneController.text.replaceAll(' ', '')}';

    // Show confirmation screen
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransferConfirmationScreen(
          recipientName: _recipientName ?? recipientPhone,
          recipientIdentifier: '+351 ${_phoneController.text}',
          amount: amount,
          description: _descriptionController.text,
          transferType: 'mbway',
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

      // Get recipient account by phone
      final recipientAccount = await _firestoreService.findAccountByPhone(recipientPhone);
      if (recipientAccount == null) {
        throw Exception('Número não encontrado no MB WAY');
      }

      // Check if not sending to self
      if (recipientAccount.userId == currentUserId) {
        throw Exception('Não é possível enviar para si mesmo');
      }

      // Check balance
      if (amount > senderAccount.availableBalance) {
        throw Exception('Saldo insuficiente');
      }

      // Check MB WAY limits (per transaction and daily)
      final perTxLimit = senderAccount.mbWayPerTransactionLimit;
      if (amount > perTxLimit) {
        throw Exception('Limite por transacao: EUR ${perTxLimit.toStringAsFixed(0)}');
      }

      // Check and update daily usage
      final canTransfer = await _firestoreService.checkAndUpdateMbWayUsage(
        senderAccount.id,
        amount,
      );
      if (!canTransfer) {
        throw Exception('Limite diario MB WAY excedido');
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
            : 'MB WAY',
        type: TransactionType.mbway,
        pqcSignature: signature,
      );

      if (!mounted) return;

      // Save recent contact
      final recipientUser = await _firestoreService.getUser(recipientAccount.userId);
      if (recipientUser != null) {
        final contact = MbWayContact(
          id: '',
          name: recipientUser.name,
          phone: recipientPhone,
          avatarUrl: recipientUser.photoUrl,
          lastUsed: DateTime.now(),
        );
        await _firestoreService.addMbWayRecentContact(currentUserId, contact);
      }

      if (!mounted) return;

      // Refresh account to update daily usage display
      context.read<AccountProvider>().refreshAccount();

      // Navigate to receipt screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransferReceiptScreen(
            recipientName: _recipientName ?? recipientPhone,
            recipientIdentifier: '+351 ${_phoneController.text}',
            amount: amount,
            description: _descriptionController.text,
            transferType: 'mbway',
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BJBankColors.mbwayRed, // MB WAY red
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'MB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('MB WAY'),
          ],
        ),
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
              // Daily limit bar
              if (_usageInfo.isNotEmpty) _buildDailyLimitBar(),

              if (_usageInfo.isNotEmpty) const SizedBox(height: BJBankSpacing.md),

              // MB WAY info card
              Container(
                padding: const EdgeInsets.all(BJBankSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BJBankColors.mbwayRed.withValues(alpha: 0.1),
                      BJBankColors.mbwayRed.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BJBankColors.mbwayRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BJBankColors.mbwayRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: BJBankSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transferência instantânea',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Envie dinheiro usando apenas o número de telemóvel',
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

              const SizedBox(height: BJBankSpacing.lg),

              // Recent contacts section
              if (_recentContacts.isNotEmpty) ...[
                _buildRecentContactsSection(),
                const SizedBox(height: BJBankSpacing.lg),
              ],

              // Rate limit warning
              if (_rateLimited) ...[
                Container(
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  decoration: BoxDecoration(
                    color: BJBankColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: BJBankColors.warning),
                      const SizedBox(width: BJBankSpacing.sm),
                      Expanded(
                        child: Text(
                          'Limite de pesquisas atingido. Aguarde 1 hora.',
                          style: TextStyle(color: BJBankColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BJBankSpacing.md),
              ],

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

              // Phone field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _PhoneFormatter(),
                ],
                onChanged: (_) => _searchRecipient(),
                decoration: InputDecoration(
                  labelText: 'Número de telemóvel',
                  hintText: '912 345 678',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '+351 ',
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
                    return 'Por favor insira o número';
                  }
                  final cleaned = value.replaceAll(' ', '');
                  if (cleaned.length != 9) {
                    return 'O número deve ter 9 dígitos';
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
                  helperText: 'Limite: € 500,00 por transação',
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
                  if (amount > 500) {
                    return 'Montante máximo: € 500,00';
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
                  hintText: 'Ex: Almoço, Táxi, etc.',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: BJBankSpacing.xl),

              // Quick amount buttons
              Text(
                'Montantes rápidos',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: BJBankSpacing.sm),
              Wrap(
                spacing: BJBankSpacing.sm,
                runSpacing: BJBankSpacing.sm,
                children: [5, 10, 20, 50, 100].map((amount) {
                  return ActionChip(
                    label: Text('€ $amount'),
                    onPressed: () {
                      _amountController.text = '$amount,00';
                    },
                  );
                }).toList(),
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
                            'MB WAY Seguro',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: BJBankColors.tertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Protegido com assinatura CRYSTALS-Dilithium',
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

              // Send button
              FilledButton(
                onPressed: _isLoading ? null : _handleMbWayTransfer,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: BJBankColors.mbwayRed, // MB WAY red
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded),
                          SizedBox(width: BJBankSpacing.sm),
                          Text(
                            'Enviar MB WAY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyLimitBar() {
    final dailyLimit = (_usageInfo['dailyLimit'] ?? 1000.0) as double;
    final dailyUsed = (_usageInfo['dailyUsed'] ?? 0.0) as double;
    final remaining = (_usageInfo['remaining'] ?? dailyLimit) as double;
    final usagePercent = dailyLimit > 0 ? (dailyUsed / dailyLimit) : 0.0;

    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Limite disponivel',
                style: TextStyle(
                  fontSize: 13,
                  color: BJBankColors.onSurfaceVariant,
                ),
              ),
              Text(
                'EUR ${remaining.toStringAsFixed(0)} / EUR ${dailyLimit.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: BJBankSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usagePercent.clamp(0.0, 1.0),
              backgroundColor: BJBankColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercent > 0.9
                    ? BJBankColors.error
                    : usagePercent > 0.7
                        ? BJBankColors.warning
                        : BJBankColors.mbwayRed,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contactos Recentes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: BJBankColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: BJBankSpacing.sm),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentContacts.length,
            separatorBuilder: (context, index) => const SizedBox(width: BJBankSpacing.sm),
            itemBuilder: (context, index) {
              final contact = _recentContacts[index];
              return _buildContactChip(contact);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactChip(MbWayContact contact) {
    return GestureDetector(
      onTap: () => _selectRecentContact(contact),
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(BJBankSpacing.sm),
        decoration: BoxDecoration(
          color: BJBankColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BJBankColors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: BJBankColors.primaryContainer,
              child: Text(
                contact.initials,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: BJBankColors.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact.firstName,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Portuguese phone formatter - adds spaces (912 345 678)
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    if (text.length > 9) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) buffer.write(' ');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
