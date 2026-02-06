import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../services/otp_service.dart';

/// MB WAY Phone Verification Screen
/// Two-step verification: phone input -> OTP verification
class MbWayPhoneVerificationScreen extends StatefulWidget {
  const MbWayPhoneVerificationScreen({
    super.key,
    this.initialPhone,
    this.onVerified,
  });

  final String? initialPhone;
  final void Function(String phone)? onVerified;

  @override
  State<MbWayPhoneVerificationScreen> createState() => _MbWayPhoneVerificationScreenState();
}

class _MbWayPhoneVerificationScreenState extends State<MbWayPhoneVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _currentStep = 1; // 1 = phone, 2 = OTP
  bool _isLoading = false;
  String? _errorMessage;
  String? _verifiedPhone;

  // Resend timer
  Timer? _resendTimer;
  int _resendSeconds = 0;

  // Shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

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

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  String _formatPhone(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) return '${digits.substring(0, 3)} ${digits.substring(3)}';
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor insira o numero';
    }
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length != 9) {
      return 'O numero deve ter 9 digitos';
    }
    if (!cleaned.startsWith('9')) {
      return 'Numero de telemovel invalido';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    final error = _validatePhone(_phoneController.text);
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cleanPhone = '+351${_phoneController.text.replaceAll(' ', '')}';
      final sent = await OtpService.sendOtp(cleanPhone);

      if (!sent) {
        throw Exception('Erro ao enviar codigo');
      }

      _verifiedPhone = cleanPhone;
      _startResendTimer();

      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });

      // Focus first OTP field
      _otpFocusNodes[0].requestFocus();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    await _sendOtp();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    // Check if all fields are filled
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      _verifyOtp(otp);
    }
  }

  void _onOtpBackspace(int index, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyOtp(String otp) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await OtpService.verifyOtp(otp);

      if (!result.success) {
        // Shake animation
        _shakeController.forward().then((_) => _shakeController.reset());

        // Clear OTP fields
        for (var c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();

        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
        return;
      }

      // Success!
      if (widget.onVerified != null && _verifiedPhone != null) {
        widget.onVerified!(_verifiedPhone!);
      }

      if (mounted) {
        Navigator.pop(context, _verifiedPhone);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao verificar codigo';
        _isLoading = false;
      });
    }
  }

  void _goBack() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
        _errorMessage = null;
        for (var c in _otpControllers) {
          c.clear();
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Verificar Telefone'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BJBankSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator
            _buildStepIndicator(),

            const SizedBox(height: BJBankSpacing.xl),

            // Content based on step
            if (_currentStep == 1) _buildPhoneStep() else _buildOtpStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, 'Telefone'),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 2
                ? BJBankColors.primary
                : BJBankColors.outline.withValues(alpha: 0.3),
          ),
        ),
        _buildStepCircle(2, 'Codigo'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? BJBankColors.primary : BJBankColors.surfaceVariant,
            border: isCurrent
                ? Border.all(color: BJBankColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : BJBankColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? BJBankColors.primary : BJBankColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(BJBankSpacing.md),
          decoration: BoxDecoration(
            color: BJBankColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_android, color: BJBankColors.primary),
              const SizedBox(width: BJBankSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passo 1 de 2',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: BJBankColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Insira o numero de telemovel para associar ao MB WAY',
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
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _PhoneFormatter(),
          ],
          onFieldSubmitted: (_) => _sendOtp(),
          decoration: InputDecoration(
            labelText: 'Numero de telemovel',
            hintText: '912 345 678',
            prefixIcon: const Icon(Icons.phone_outlined),
            prefixText: '+351 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: 'Formato: 9XX XXX XXX',
          ),
        ),

        const SizedBox(height: BJBankSpacing.xl),

        // Send button
        FilledButton(
          onPressed: _isLoading ? null : _sendOtp,
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
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded),
                    SizedBox(width: BJBankSpacing.sm),
                    Text(
                      'Enviar Codigo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(BJBankSpacing.md),
          decoration: BoxDecoration(
            color: BJBankColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.sms_outlined, color: BJBankColors.primary),
              const SizedBox(width: BJBankSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passo 2 de 2',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: BJBankColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Codigo enviado para ${_formatDisplayPhone(_verifiedPhone ?? '')}',
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

        // OTP input fields
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _shakeAnimation.value * ((_shakeController.value * 10).floor() % 2 == 0 ? 1 : -1),
                0,
              ),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 48,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) => _onOtpBackspace(index, event),
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _onOtpChanged(index, value),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: BJBankSpacing.lg),

        // Loading indicator
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),

        const SizedBox(height: BJBankSpacing.xl),

        // Resend button
        Center(
          child: TextButton(
            onPressed: _resendSeconds > 0 ? null : _resendOtp,
            child: Text(
              _resendSeconds > 0
                  ? 'Reenviar codigo (${_resendSeconds}s)'
                  : 'Reenviar codigo',
            ),
          ),
        ),

        const SizedBox(height: BJBankSpacing.md),

        // Demo hint
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
              Icon(Icons.info_outline, color: BJBankColors.tertiary, size: 20),
              const SizedBox(width: BJBankSpacing.sm),
              Expanded(
                child: Text(
                  'Demo: O codigo OTP esta visivel na consola de depuracao',
                  style: TextStyle(
                    fontSize: 12,
                    color: BJBankColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDisplayPhone(String phone) {
    if (phone.length == 13 && phone.startsWith('+351')) {
      return '+351 ${phone.substring(4, 7)} ${phone.substring(7, 10)} ${phone.substring(10)}';
    }
    return phone;
  }
}

/// Portuguese phone formatter
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
