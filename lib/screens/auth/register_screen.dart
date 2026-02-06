import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../theme/app_strings.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/animated_bubbles.dart';

/// Register Screen for BJBank
/// Create new account with email, phone (required), and password
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = AppStrings.registerTermsRequired;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final cleanedPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    final result = await AuthService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: '+351$cleanedPhone',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      _showSuccessDialog();
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: BJBankColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: BJBankColors.success,
            size: 40,
          ),
        ),
        title: Text(
          AppStrings.registerSuccessTitle,
          style: BJBankTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          AppStrings.registerSuccessMessage,
          style: BJBankTypography.bodyMedium.copyWith(
            color: BJBankColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: BJBankColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppStrings.continueButton,
                style: BJBankTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated Bubbles Background
          const AnimatedBubbles(
            bubbleCount: 8,
            color: BJBankColors.primary,
          ),

          // Gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    BJBankColors.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BJBankSpacing.xs,
                    vertical: BJBankSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          foregroundColor: BJBankColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Scrollable form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BJBankSpacing.lg,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            AppStrings.registerTitle,
                            style: BJBankTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: BJBankColors.onSurface,
                            ),
                          ),

                          const SizedBox(height: BJBankSpacing.xs),

                          Text(
                            AppStrings.registerSubtitle,
                            style: BJBankTypography.bodyLarge.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: BJBankSpacing.xl),

                          // Error message
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _errorMessage != null
                                ? Container(
                                    key: ValueKey(_errorMessage),
                                    margin: const EdgeInsets.only(
                                      bottom: BJBankSpacing.md,
                                    ),
                                    padding: const EdgeInsets.all(
                                      BJBankSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: BJBankColors.error
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: BJBankColors.error
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: BJBankColors.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: BJBankSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: BJBankTypography.bodyMedium
                                                .copyWith(
                                              color: BJBankColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Name field
                          _buildTextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            label: AppStrings.registerNameLabel,
                            hint: AppStrings.registerNameHint,
                            icon: Icons.person_outlined,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _emailFocus.requestFocus(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.registerNameRequired;
                              }
                              if (value.length < 3) {
                                return AppStrings.registerNameMinLength;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: BJBankSpacing.md),

                          // Email field
                          _buildTextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: AppStrings.loginEmailLabel,
                            hint: AppStrings.loginEmailHint,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _phoneFocus.requestFocus(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.loginEmailRequired;
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return AppStrings.loginEmailInvalid;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: BJBankSpacing.md),

                          // Phone field (REQUIRED)
                          _buildTextField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            label: AppStrings.registerPhoneLabel,
                            hint: AppStrings.registerPhoneHint,
                            icon: Icons.phone_outlined,
                            prefixText: AppStrings.registerPhonePrefix,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.registerPhoneRequired;
                              }
                              final cleaned =
                                  value.replaceAll(RegExp(r'\D'), '');
                              if (cleaned.length != 9) {
                                return AppStrings.registerPhoneInvalid;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: BJBankSpacing.md),

                          // Password field
                          _buildTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            label: AppStrings.registerPasswordLabel,
                            icon: Icons.lock_outlined,
                            obscureText: _obscurePassword,
                            helperText: AppStrings.registerPasswordHelper,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                _confirmPasswordFocus.requestFocus(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: BJBankColors.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.registerPasswordRequired;
                              }
                              if (value.length < 6) {
                                return AppStrings.registerPasswordMinLength;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: BJBankSpacing.md),

                          // Confirm password field
                          _buildTextField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            label: AppStrings.registerConfirmPasswordLabel,
                            icon: Icons.lock_outlined,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleRegister(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: BJBankColors.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.registerConfirmPasswordRequired;
                              }
                              if (value != _passwordController.text) {
                                return AppStrings.registerPasswordMismatch;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: BJBankSpacing.lg),

                          // Terms checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptedTerms = value ?? false;
                                      if (_acceptedTerms) {
                                        _errorMessage = null;
                                      }
                                    });
                                  },
                                  activeColor: BJBankColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: BJBankSpacing.sm),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _acceptedTerms = !_acceptedTerms;
                                      if (_acceptedTerms) {
                                        _errorMessage = null;
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: RichText(
                                      text: TextSpan(
                                        style:
                                            BJBankTypography.bodyMedium.copyWith(
                                          color: BJBankColors.onSurfaceVariant,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: AppStrings.registerTermsPrefix,
                                          ),
                                          TextSpan(
                                            text: AppStrings.registerTermsLink,
                                            style: TextStyle(
                                              color: BJBankColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: AppStrings.registerTermsMiddle,
                                          ),
                                          TextSpan(
                                            text: AppStrings.registerPrivacyLink,
                                            style: TextStyle(
                                              color: BJBankColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: BJBankSpacing.xl),

                          // Register button
                          FilledButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: BJBankColors.primary,
                              disabledBackgroundColor:
                                  BJBankColors.primary.withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isLoading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      AppStrings.registerButton,
                                      key: const ValueKey('text'),
                                      style:
                                          BJBankTypography.titleMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: BJBankSpacing.xl),

                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.registerHasAccount,
                                style: BJBankTypography.bodyMedium.copyWith(
                                  color: BJBankColors.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: BJBankColors.primary,
                                ),
                                child: Text(
                                  AppStrings.registerLoginLink,
                                  style: BJBankTypography.labelLarge.copyWith(
                                    color: BJBankColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: BJBankSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    String? hint,
    required IconData icon,
    String? prefixText,
    String? helperText,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onSubmitted,
      style: BJBankTypography.bodyLarge.copyWith(
        color: BJBankColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(
          icon,
          color: BJBankColors.onSurfaceVariant,
        ),
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: BJBankColors.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BJBankColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BJBankColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BJBankColors.error,
            width: 2,
          ),
        ),
        labelStyle: BJBankTypography.bodyMedium.copyWith(
          color: BJBankColors.onSurfaceVariant,
        ),
        hintStyle: BJBankTypography.bodyMedium.copyWith(
          color: BJBankColors.outline,
        ),
        helperStyle: BJBankTypography.bodySmall.copyWith(
          color: BJBankColors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.md,
          vertical: BJBankSpacing.md,
        ),
      ),
      validator: validator,
    );
  }
}
