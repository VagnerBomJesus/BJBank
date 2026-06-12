import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../models/card_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/firestore_service.dart';

/// Add New Card screen (UI-kit style): live navy card preview + underline form.
/// Number / expiry / CVV are issued by BJBank automatically.
class AddNewCardScreen extends StatefulWidget {
  const AddNewCardScreen({
    super.key,
    required this.firestoreService,
    required this.onCardCreated,
  });

  final FirestoreService firestoreService;
  final VoidCallback onCardCreated;

  @override
  State<AddNewCardScreen> createState() => _AddNewCardScreenState();
}

class _AddNewCardScreenState extends State<AddNewCardScreen> {
  final _holderController = TextEditingController();
  CardType _type = CardType.debit;
  CardBrand _brand = CardBrand.visa;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _holderController.text = user?.name ?? '';
    _holderController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final holder = _holderController.text.trim();
    if (holder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indica o nome do titular'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final account = context.read<AccountProvider>();
      if (auth.user == null || account.primaryAccount == null) {
        throw Exception('Utilizador ou conta não encontrada');
      }
      await widget.firestoreService.createDefaultCard(
        userId: auth.user!.id,
        accountId: account.primaryAccount!.id,
        holderName: holder,
        type: _type,
        brand: _brand,
      );
      widget.onCardCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cartão criado com sucesso!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: BJBankColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar cartão: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: BJBankColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BJBankSpacing.md,
                BJBankSpacing.sm,
                BJBankSpacing.md,
                BJBankSpacing.xs,
              ),
              child: Row(
                children: [
                  _circleButton(Icons.arrow_back_ios_new_rounded,
                      () => Navigator.maybePop(context)),
                  Expanded(
                    child: Text(
                      'Adicionar Cartão',
                      textAlign: TextAlign.center,
                      style: BJBankTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: BJBankColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _cardPreview(),
                  const SizedBox(height: BJBankSpacing.xl),
                  _label('Nome do Titular'),
                  _underlineField(
                    controller: _holderController,
                    icon: Icons.person_outline_rounded,
                    hint: 'Nome no cartão',
                  ),
                  const SizedBox(height: BJBankSpacing.lg),
                  _label('Tipo de Cartão'),
                  const SizedBox(height: BJBankSpacing.xs),
                  Row(
                    children: [
                      _typeChip(CardType.debit, 'Débito'),
                      const SizedBox(width: BJBankSpacing.xs),
                      _typeChip(CardType.credit, 'Crédito'),
                      const SizedBox(width: BJBankSpacing.xs),
                      _typeChip(CardType.virtual, 'Virtual'),
                    ],
                  ),
                  const SizedBox(height: BJBankSpacing.lg),
                  _label('Bandeira'),
                  const SizedBox(height: BJBankSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: _brandOption(CardBrand.visa)),
                      const SizedBox(width: BJBankSpacing.sm),
                      Expanded(child: _brandOption(CardBrand.mastercard)),
                    ],
                  ),
                  const SizedBox(height: BJBankSpacing.lg),
                  // Info: auto-generated details
                  Container(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    decoration: BoxDecoration(
                      color: BJBankColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 20, color: BJBankColors.info),
                        const SizedBox(width: BJBankSpacing.sm),
                        Expanded(
                          child: Text(
                            'O número, validade e CVV são gerados de forma '
                            'segura pelo BJBank.',
                            style: BJBankTypography.bodySmall.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Submit
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: _isLoading ? null : _create,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: BJBankColors.primary,
                  foregroundColor: BJBankColors.onPrimary,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text(
                        'Adicionar Cartão',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card preview ──
  Widget _cardPreview() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        decoration: BoxDecoration(
          gradient: BJBankColors.cardNavyGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: BJBankColors.cardNavyDeep.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -10,
                bottom: -40,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        BJBankColors.accentBlue.withValues(alpha: 0.4),
                        BJBankColors.accentBlue.withValues(alpha: 0.0),
                      ],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BJBankSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.memory_rounded,
                            color: BJBankColors.onPrimary, size: 26),
                        const Spacer(),
                        Icon(Icons.contactless_rounded,
                            color:
                                BJBankColors.onPrimary.withValues(alpha: 0.7),
                            size: 24),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '••••  ••••  ••••  ••••',
                      style: BJBankTypography.valueMedium.copyWith(
                        color: BJBankColors.onPrimary,
                        fontSize: 19,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _holderController.text.isEmpty
                                ? 'NOME DO TITULAR'
                                : _holderController.text.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BJBankTypography.titleSmall.copyWith(
                              color: BJBankColors.onPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: BJBankSpacing.sm),
                        _brandMark(_brand),
                      ],
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

  Widget _brandMark(CardBrand brand) {
    if (brand == CardBrand.visa) {
      return const Text(
        'VISA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          letterSpacing: 1,
        ),
      );
    }
    // Mastercard
    return SizedBox(
      width: 42,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFEB001B)),
            ),
          ),
          Positioned(
            right: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form helpers ──
  Widget _label(String text) => Text(
        text,
        style: BJBankTypography.bodySmall.copyWith(
          color: BJBankColors.onSurfaceVariant,
        ),
      );

  Widget _underlineField({
    required TextEditingController controller,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      style: BJBankTypography.bodyLarge.copyWith(color: BJBankColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: BJBankColors.onSurfaceVariant),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: BJBankSpacing.sm),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: BJBankColors.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: BJBankColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _typeChip(CardType type, String label) {
    final sel = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: BJBankSpacing.md, vertical: BJBankSpacing.sm),
        decoration: BoxDecoration(
          color: sel
              ? BJBankColors.primary
              : BJBankColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: BJBankTypography.labelLarge.copyWith(
            color: sel ? BJBankColors.onPrimary : BJBankColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _brandOption(CardBrand brand) {
    final sel = _brand == brand;
    return GestureDetector(
      onTap: () => setState(() => _brand = brand),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: BJBankColors.surfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? BJBankColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: brand == CardBrand.visa
              ? const Text(
                  'VISA',
                  style: TextStyle(
                    color: Color(0xFF1A1F71),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : SizedBox(
                  width: 46,
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 4,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEB001B)),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF79E1B)),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: BJBankColors.surfaceVariant.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: BJBankColors.onSurface),
      ),
    );
  }
}
