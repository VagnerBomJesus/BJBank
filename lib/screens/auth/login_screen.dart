import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../theme/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/animated_bubbles.dart';

/// Login Screen for BJBank
/// Clean white design with animated bubbles and logo
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      final pinEnabled = await SecureStorageService.isPinEnabled();
      if (!mounted) return;

      if (pinEnabled) {
        final hasPinSet = await SecureStorageService.isPinSet();
        if (!mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil(
          hasPinSet ? AppRoutes.pinVerify : AppRoutes.pinSetup,
          (route) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated Bubbles Background
          const AnimatedBubbles(
            bubbleCount: 10,
            color: BJBankColors.primary,
          ),

          // Gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: BJBankSpacing.xl),

                    // Logo with animation
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoFade.value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildLogo(),
                    ),

                    const SizedBox(height: BJBankSpacing.xl),

                    // Title and subtitle with animation
                    SlideTransition(
                      position: _formSlide,
                      child: FadeTransition(
                        opacity: _formFade,
                        child: Column(
                          children: [
                            Text(
                              AppStrings.loginTitle,
                              style: BJBankTypography.headlineMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: BJBankColors.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: BJBankSpacing.xs),
                            Text(
                              AppStrings.loginSubtitle,
                              style: BJBankTypography.bodyLarge.copyWith(
                                color: BJBankColors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: BJBankSpacing.xl),

                    // Form fields with animation
                    SlideTransition(
                      position: _formSlide,
                      child: FadeTransition(
                        opacity: _formFade,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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

                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              label: AppStrings.loginEmailLabel,
                              hint: AppStrings.loginEmailHint,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
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

                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              label: AppStrings.loginPasswordLabel,
                              icon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
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
                                  return AppStrings.loginPasswordRequired;
                                }
                                if (value.length < 6) {
                                  return AppStrings.loginPasswordMinLength;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: BJBankSpacing.sm),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _navigateToForgotPassword,
                                style: TextButton.styleFrom(
                                  foregroundColor: BJBankColors.primary,
                                ),
                                child: Text(
                                  AppStrings.loginForgotPassword,
                                  style: BJBankTypography.labelLarge.copyWith(
                                    color: BJBankColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: BJBankSpacing.lg),

                            // Login button
                            _buildLoginButton(),

                            const SizedBox(height: BJBankSpacing.xl),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: BJBankColors.outlineVariant,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: BJBankSpacing.md,
                                  ),
                                  child: Text(
                                    AppStrings.loginOr,
                                    style: BJBankTypography.bodyMedium.copyWith(
                                      color: BJBankColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: BJBankColors.outlineVariant,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: BJBankSpacing.xl),

                            // Register link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.loginNoAccount,
                                  style: BJBankTypography.bodyMedium.copyWith(
                                    color: BJBankColors.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _navigateToRegister,
                                  style: TextButton.styleFrom(
                                    foregroundColor: BJBankColors.primary,
                                  ),
                                  child: Text(
                                    AppStrings.loginRegister,
                                    style: BJBankTypography.labelLarge.copyWith(
                                      color: BJBankColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: BJBankSpacing.lg),

                            // PQC badge
                            _buildPqcBadge(),

                            const SizedBox(height: BJBankSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        AppStrings.logo,
        width: 280,
        height: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to text logo
          return Text(
            AppStrings.appName,
            style: BJBankTypography.displayMedium.copyWith(
              color: BJBankColors.primary,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    String? hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
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
      onFieldSubmitted: onSubmitted,
      style: BJBankTypography.bodyLarge.copyWith(
        color: BJBankColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: BJBankColors.onSurfaceVariant,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.md,
          vertical: BJBankSpacing.md,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildLoginButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: BJBankColors.primary,
        disabledBackgroundColor: BJBankColors.primary.withValues(alpha: 0.6),
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
                AppStrings.loginButton,
                key: const ValueKey('text'),
                style: BJBankTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildPqcBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.md,
          vertical: BJBankSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: BJBankColors.quantum.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 16,
              color: BJBankColors.quantum,
            ),
            const SizedBox(width: BJBankSpacing.xs),
            Text(
              AppStrings.loginPqcBadge,
              style: BJBankTypography.labelSmall.copyWith(
                color: BJBankColors.quantum,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
