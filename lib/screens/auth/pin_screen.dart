import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/app_strings.dart';
import '../../services/secure_storage_service.dart';
import '../../services/pqc_service.dart';
import '../../routes/app_routes.dart';

/// PIN Setup Screen
/// Clean, modern design with custom numeric keypad
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFromSettings = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isFromSettings = Navigator.of(context).canPop();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    HapticFeedback.lightImpact();

    if (_isLoading) return;

    setState(() => _errorMessage = null);

    if (_isConfirmStep) {
      if (_confirmPin.length < 6) {
        setState(() => _confirmPin += key);
        if (_confirmPin.length == 6) {
          _validateAndSave();
        }
      }
    } else {
      if (_pin.length < 6) {
        setState(() => _pin += key);
        if (_pin.length == 6) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() => _isConfirmStep = true);
            }
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    HapticFeedback.lightImpact();

    if (_isLoading) return;

    setState(() => _errorMessage = null);

    if (_isConfirmStep) {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    }
  }

  void _goBack() {
    if (_isConfirmStep) {
      setState(() {
        _isConfirmStep = false;
        _confirmPin = '';
        _errorMessage = null;
      });
    } else if (_isFromSettings) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _validateAndSave() async {
    if (_pin != _confirmPin) {
      _shakeController.forward().then((_) => _shakeController.reset());
      setState(() {
        _errorMessage = AppStrings.pinMismatchError;
        _confirmPin = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SecureStorageService.setPin(_pin);

      final pqcService = PqcService();
      await pqcService.initialize();
      await pqcService.generateKeyPair();

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _errorMessage = '${AppStrings.pinSaveError}: $e';
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: BJBankSpacing.md),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: BJBankColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: BJBankColors.success, size: 40),
            ),
            const SizedBox(height: BJBankSpacing.lg),
            const Text(
              AppStrings.pinSetupSuccess,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BJBankSpacing.sm),
            Text(
              AppStrings.pinSetupSuccessMessage,
              style: TextStyle(color: BJBankColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BJBankSpacing.md),
            Container(
              padding: const EdgeInsets.all(BJBankSpacing.sm),
              decoration: BoxDecoration(
                color: BJBankColors.quantum.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield, size: 18, color: BJBankColors.quantum),
                  const SizedBox(width: BJBankSpacing.xs),
                  Flexible(
                    child: Text(
                      AppStrings.pinPqcKeysGenerated,
                      style: TextStyle(fontSize: 12, color: BJBankColors.quantum),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BJBankSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_isFromSettings) {
                    Navigator.of(context).pop(true);
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.home,
                      (route) => false,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(AppStrings.continueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirmStep ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: BJBankColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(BJBankSpacing.sm),
              child: Row(
                children: [
                  if (_isConfirmStep || _isFromSettings)
                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Text(
                    _isConfirmStep ? '2/2' : '1/2',
                    style: TextStyle(
                      color: BJBankColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.xl),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [BJBankColors.primary, BJBankColors.quantum],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isConfirmStep ? Icons.lock : Icons.pin,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: BJBankSpacing.xl),

                    // Title
                    Text(
                      _isConfirmStep ? AppStrings.pinConfirmTitle : AppStrings.pinSetupTitle,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: BJBankSpacing.xs),

                    // Subtitle
                    Text(
                      _isConfirmStep ? AppStrings.pinConfirmSubtitle : AppStrings.pinSetupSubtitle,
                      style: TextStyle(color: BJBankColors.onSurfaceVariant, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: BJBankSpacing.xxl),

                    // PIN dots
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final offset = _shakeAnimation.value * 12 *
                            ((_shakeController.value * 6).round().isEven ? 1 : -1);
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: _buildPinDots(currentPin),
                    ),

                    const SizedBox(height: BJBankSpacing.lg),

                    // Error message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _errorMessage != null
                          ? Container(
                              key: ValueKey(_errorMessage),
                              padding: const EdgeInsets.symmetric(
                                horizontal: BJBankSpacing.md,
                                vertical: BJBankSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: BJBankColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: BJBankColors.error, fontSize: 13),
                              ),
                            )
                          : const SizedBox(height: 36),
                    ),

                    const Spacer(flex: 1),

                    // Loading or Keypad
                    if (_isLoading)
                      Column(
                        children: [
                          CircularProgressIndicator(color: BJBankColors.primary),
                          const SizedBox(height: BJBankSpacing.md),
                          Text(
                            AppStrings.pinGeneratingKeys,
                            style: TextStyle(color: BJBankColors.onSurfaceVariant),
                          ),
                        ],
                      )
                    else
                      _buildKeypad(),

                    const SizedBox(height: BJBankSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < pin.length;
        final isActive = index == pin.length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isFilled ? 18 : 16,
          height: isFilled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (_isConfirmStep ? BJBankColors.quantum : BJBankColors.primary)
                : Colors.transparent,
            border: Border.all(
              color: isFilled
                  ? Colors.transparent
                  : isActive
                      ? (_isConfirmStep ? BJBankColors.quantum : BJBankColors.primary)
                      : BJBankColors.outline.withValues(alpha: 0.5),
              width: isActive ? 2 : 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: BJBankSpacing.sm),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: BJBankSpacing.sm),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: BJBankSpacing.sm),
        _buildKeypadRow(['', '0', 'delete']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 80, height: 64);
        }
        if (key == 'delete') {
          return _buildKeypadButton(
            child: Icon(Icons.backspace_outlined, color: BJBankColors.onSurface),
            onTap: _onDeletePressed,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              setState(() {
                if (_isConfirmStep) {
                  _confirmPin = '';
                } else {
                  _pin = '';
                }
              });
            },
          );
        }
        return _buildKeypadButton(
          child: Text(
            key,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
          onTap: () => _onKeyPressed(key),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 72,
            height: 64,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// PIN Verification Screen
class PinVerifyScreen extends StatefulWidget {
  const PinVerifyScreen({super.key});

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  int _attempts = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _canUseBiometrics = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final enabled = await SecureStorageService.isBiometricsEnabled();
    if (mounted) {
      setState(() => _canUseBiometrics = enabled);
      if (enabled) {
        _authenticateWithBiometrics();
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final success = await SecureStorageService.authenticateWithBiometrics();
    if (success && mounted) {
      _onSuccess();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    HapticFeedback.lightImpact();

    if (_isLoading || _attempts >= 5) return;

    setState(() => _errorMessage = null);

    if (_pin.length < 6) {
      setState(() => _pin += key);
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    HapticFeedback.lightImpact();

    if (_isLoading) return;

    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final isValid = await SecureStorageService.verifyPin(_pin);

    if (!mounted) return;

    if (isValid) {
      _onSuccess();
    } else {
      _shakeController.forward().then((_) => _shakeController.reset());
      setState(() {
        _attempts++;
        _isLoading = false;
        _pin = '';
        if (_attempts >= 5) {
          _errorMessage = AppStrings.pinTooManyAttempts;
        } else {
          _errorMessage = AppStrings.pinIncorrectAttempts(5 - _attempts);
        }
      });
    }
  }

  void _onSuccess() {
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: BJBankColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: isSmallScreen ? BJBankSpacing.md : BJBankSpacing.xl),

                      // Logo - responsive size
                      Image.asset(
                        AppStrings.logo,
                        width: isSmallScreen ? 200 : 280,
                        height: isSmallScreen ? 100 : 160,
                        fit: BoxFit.contain,
                      ),

                      SizedBox(height: isSmallScreen ? BJBankSpacing.md : BJBankSpacing.lg),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.xl),
                        child: Column(
                          children: [
                            Text(
                              AppStrings.pinVerifyTitle,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: BJBankSpacing.xs),
                            Text(
                              AppStrings.pinVerifySubtitle,
                              style: TextStyle(
                                color: BJBankColors.onSurfaceVariant,
                                fontSize: isSmallScreen ? 13 : 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? BJBankSpacing.lg : BJBankSpacing.xxl),

                      // PIN dots
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          final offset = _shakeAnimation.value * 12 *
                              ((_shakeController.value * 6).round().isEven ? 1 : -1);
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: child,
                          );
                        },
                        child: _buildPinDots(),
                      ),

                      const SizedBox(height: BJBankSpacing.md),

                      // Error message
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.xl),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _errorMessage != null
                              ? Container(
                                  key: ValueKey(_errorMessage),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: BJBankSpacing.md,
                                    vertical: BJBankSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BJBankColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: BJBankColors.error, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const SizedBox(height: 32),
                        ),
                      ),

                      const Spacer(),

                      // Keypad or loading
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else if (_attempts < 5)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
                          child: _buildKeypad(),
                        ),

                      SizedBox(height: isSmallScreen ? BJBankSpacing.xs : BJBankSpacing.md),

                      // Biometrics button
                      if (_canUseBiometrics && _attempts < 5 && !_isLoading)
                        TextButton.icon(
                          onPressed: _authenticateWithBiometrics,
                          icon: Icon(Icons.fingerprint, color: BJBankColors.primary),
                          label: Text(
                            AppStrings.pinUseBiometrics,
                            style: TextStyle(color: BJBankColors.primary),
                          ),
                        ),

                      SizedBox(height: isSmallScreen ? BJBankSpacing.sm : BJBankSpacing.lg),

                      // Security badge
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: BJBankSpacing.xl),
                        padding: const EdgeInsets.symmetric(
                          horizontal: BJBankSpacing.md,
                          vertical: BJBankSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: BJBankColors.quantum.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: BJBankColors.quantum),
                            const SizedBox(width: BJBankSpacing.xs),
                            Text(
                              AppStrings.pinQuantumBadge,
                              style: TextStyle(
                                fontSize: 12,
                                color: BJBankColors.quantum,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? BJBankSpacing.md : BJBankSpacing.xl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _pin.length;
        final isActive = index == _pin.length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isFilled ? 18 : 16,
          height: isFilled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? BJBankColors.primary : Colors.transparent,
            border: Border.all(
              color: isFilled
                  ? Colors.transparent
                  : isActive
                      ? BJBankColors.primary
                      : BJBankColors.outline.withValues(alpha: 0.5),
              width: isActive ? 2 : 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: BJBankSpacing.sm),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: BJBankSpacing.sm),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: BJBankSpacing.sm),
        _buildKeypadRow(['', '0', 'delete']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final buttonSize = isSmallScreen ? 56.0 : 64.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key.isEmpty) {
          return SizedBox(width: buttonSize + 16, height: buttonSize);
        }
        if (key == 'delete') {
          return _buildKeypadButton(
            child: Icon(Icons.backspace_outlined, color: BJBankColors.onSurface),
            onTap: _onDeletePressed,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              setState(() => _pin = '');
            },
            size: buttonSize,
          );
        }
        return _buildKeypadButton(
          child: Text(
            key,
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => _onKeyPressed(key),
          size: buttonSize,
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    double size = 64,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: size + 8,
            height: size,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
