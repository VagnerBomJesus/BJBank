import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// MB WAY Phone Setup Screen
///
/// Ecra simples para inserir o numero de telemovel a associar ao MBWay.
/// Sem OTP nem email — apenas valida formato local (+351, 9 digitos, comeca
/// por 9) e devolve o numero normalizado ao ecra chamador, que persiste
/// em mbway_phones (UNIQUE account_id garante 1 numero por conta).
class MbWayPhoneVerificationScreen extends StatefulWidget {
  const MbWayPhoneVerificationScreen({
    super.key,
    this.initialPhone,
    this.onVerified,
  });

  final String? initialPhone;
  final void Function(String phone)? onVerified;

  @override
  State<MbWayPhoneVerificationScreen> createState() =>
      _MbWayPhoneVerificationScreenState();
}

class _MbWayPhoneVerificationScreenState
    extends State<MbWayPhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      final cleaned = widget.initialPhone!.replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.startsWith('351') && cleaned.length == 12) {
        _phoneController.text = _formatPhone(cleaned.substring(3));
      } else if (cleaned.length == 9) {
        _phoneController.text = _formatPhone(cleaned);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhone(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} '
        '${digits.substring(3, 6)} '
        '${digits.substring(6)}';
  }

  String? _validatePhone(String? value) {
    final cleaned = (value ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return 'Por favor insere o numero';
    if (cleaned.length != 9) return 'O numero deve ter 9 digitos';
    if (!cleaned.startsWith('9')) return 'Numero de telemovel invalido';
    return null;
  }

  void _submit() {
    final err = _validatePhone(_phoneController.text);
    if (err != null) {
      setState(() => _errorMessage = err);
      return;
    }
    final clean = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final phone = '+351$clean';
    if (widget.onVerified != null) widget.onVerified!(phone);
    Navigator.pop(context, phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Ativar MB WAY'),
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
              // Header info
              Container(
                padding: const EdgeInsets.all(BJBankSpacing.md),
                decoration: BoxDecoration(
                  color: BJBankColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_iphone_outlined,
                        color: BJBankColors.primary),
                    const SizedBox(width: BJBankSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Numero MBWay',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: BJBankColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Insere o telemovel que queres associar a esta '
                            'conta. So e permitido um numero por conta.',
                            style: TextStyle(
                              fontSize: 13,
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

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validatePhone,
                onFieldSubmitted: (_) => _submit(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _PhoneFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Numero de telemovel',
                  hintText: '9XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '+351 ',
                  helperText: 'Indicativo Portugal (+351) obrigatorio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: BJBankSpacing.xl),

              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: BJBankSpacing.sm),
                    Text(
                      'Ativar MB WAY',
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
}

/// Portuguese phone formatter — formata 9 digitos como "9XX XXX XXX".
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    if (text.length > 9) return oldValue;
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
