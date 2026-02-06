import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../services/auth_service.dart';

/// Forgot Password Screen for BJBank
/// Send password reset email
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.sendPasswordReset(_emailController.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      setState(() {
        _emailSent = true;
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BJBankSpacing.lg),
          child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: BJBankSpacing.xl),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: BJBankColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset,
              size: 40,
              color: BJBankColors.primary,
            ),
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // Title
          Text(
            'Recuperar palavra-passe',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BJBankColors.onBackground,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: BJBankSpacing.sm),

          Text(
            'Insira o seu email e enviaremos instruções para redefinir a sua palavra-passe.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: BJBankSpacing.xxl),

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
                  Icon(
                    Icons.error_outline,
                    color: BJBankColors.error,
                  ),
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

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'seu@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor insira o seu email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Por favor insira um email válido';
              }
              return null;
            },
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // Submit button
          FilledButton(
            onPressed: _isLoading ? null : _handleSubmit,
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
                    'Enviar instruções',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          const SizedBox(height: BJBankSpacing.xl),

          // Back to login
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar ao login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BJBankSpacing.xxl),

        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: BJBankColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: BJBankColors.success,
          ),
        ),

        const SizedBox(height: BJBankSpacing.xl),

        // Title
        Text(
          'Verifique o seu email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: BJBankColors.onBackground,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: BJBankSpacing.md),

        Text(
          'Enviámos instruções de recuperação para:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: BJBankColors.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: BJBankSpacing.sm),

        Text(
          _emailController.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: BJBankColors.primary,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: BJBankSpacing.xl),

        Container(
          padding: const EdgeInsets.all(BJBankSpacing.md),
          decoration: BoxDecoration(
            color: BJBankColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: BJBankColors.onSurfaceVariant,
              ),
              const SizedBox(height: BJBankSpacing.sm),
              Text(
                'Se não encontrar o email, verifique a pasta de spam ou lixo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: BJBankSpacing.xxl),

        // Back to login button
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Voltar ao login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: BJBankSpacing.md),

        // Resend button
        OutlinedButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Enviar novamente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
