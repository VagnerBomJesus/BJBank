import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mbway_provider.dart';
import '../../models/mbway_contact_model.dart';
import '../../services/supabase_money_request_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'widgets/contact_picker_screen.dart';

/// Request Money (MB WAY): ask another user for money. They receive the
/// request and can approve or decline it.
class RequestMoneyScreen extends StatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  final _service = SupabaseMoneyRequestService();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  String? _selectedName;
  Uint8List? _selectedPhoto;

  Future<void> _openPicker() async {
    final frequent = context.read<MbWayProvider>().frequentContacts;
    final picked = await Navigator.push<PickedContact>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactPickerScreen(frequent: frequent),
      ),
    );
    if (picked != null) {
      setState(() {
        _phoneController.text = picked.phone;
        _selectedName = picked.name;
        _selectedPhoto = picked.photo;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;

    if (phone.length < 9) {
      _snack('Indica um número MB WAY válido');
      return;
    }
    if (amount <= 0) {
      _snack('Indica um montante válido');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final name = context.read<AuthProvider>().user?.name ?? 'Utilizador';
      await _service.criarPedido(
        requesterName: name,
        payerPhone: phone,
        amount: amount,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido enviado! Aguarda a aprovação.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: BJBankColors.success,
        ),
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
                  BJBankSpacing.md, BJBankSpacing.sm, BJBankSpacing.md, 0),
              child: Row(
                children: [
                  _circleButton(Icons.arrow_back_ios_new_rounded,
                      () => Navigator.maybePop(context)),
                  Expanded(
                    child: Text(
                      'Pedir Dinheiro',
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // MB WAY badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: BJBankSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: BJBankColors.mbwayRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.smartphone_rounded,
                              size: 16, color: BJBankColors.mbwayRed),
                          const SizedBox(width: 6),
                          Text('Via MB WAY',
                              style: BJBankTypography.labelMedium.copyWith(
                                color: BJBankColors.mbwayRed,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: BJBankSpacing.lg),

                  // Contacts: pick from frequent or phone contacts
                  _label('Para'),
                  const SizedBox(height: BJBankSpacing.xs),
                  _contactsRow(),
                  const SizedBox(height: BJBankSpacing.lg),

                  _label('Número MB WAY do pagador'),
                  _underlineField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hint: '9XX XXX XXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: BJBankSpacing.lg),

                  _label('Descrição (opcional)'),
                  _underlineField(
                    controller: _descController,
                    icon: Icons.notes_rounded,
                    hint: 'Motivo do pedido',
                  ),
                  const SizedBox(height: BJBankSpacing.xl),

                  // Amount box
                  Container(
                    padding: const EdgeInsets.all(BJBankSpacing.lg),
                    decoration: BoxDecoration(
                      color: BJBankColors.surfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BJBankColors.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Montante a pedir',
                            style: BJBankTypography.labelMedium.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            )),
                        const SizedBox(height: BJBankSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('EUR',
                                style: BJBankTypography.titleMedium.copyWith(
                                  color: BJBankColors.outline,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(width: BJBankSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,]')),
                                ],
                                style: BJBankTypography.balanceMedium.copyWith(
                                  color: BJBankColors.onSurface,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0,00',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
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
                onPressed: _isLoading ? null : _submit,
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
                    : const Text('Enviar Pedido',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactsRow() {
    final frequent = context.watch<MbWayProvider>().frequentContacts;
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Pick from phone contacts
          _contactAvatar(
            label: 'Contactos',
            onTap: _openPicker,
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: BJBankColors.primary),
            dashed: true,
          ),
          // Selected (from phone, with photo)
          if (_selectedPhoto != null && _phoneController.text.isNotEmpty)
            _contactAvatar(
              label: (_selectedName ?? '').split(' ').first,
              onTap: _openPicker,
              selected: true,
              image: MemoryImage(_selectedPhoto!),
            ),
          // Frequent MB WAY contacts
          for (final c in frequent)
            _contactAvatar(
              label: c.firstName,
              onTap: () => setState(() {
                _phoneController.text = c.phone;
                _selectedName = c.name;
                _selectedPhoto = null;
              }),
              selected: _phoneController.text == c.phone,
              child: Text(
                c.initials,
                style: BJBankTypography.titleSmall.copyWith(
                  color: BJBankColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactAvatar({
    required String label,
    required VoidCallback onTap,
    Widget? child,
    ImageProvider? image,
    bool selected = false,
    bool dashed = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: BJBankSpacing.xs),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BJBankColors.primary.withValues(alpha: 0.10),
                image: image != null
                    ? DecorationImage(image: image, fit: BoxFit.cover)
                    : null,
                border: Border.all(
                  color: selected
                      ? BJBankColors.primary
                      : BJBankColors.primary.withValues(alpha: 0.25),
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: image == null ? Center(child: child) : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: BJBankTypography.labelSmall.copyWith(
                color: BJBankColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: BJBankTypography.bodySmall.copyWith(
              color: BJBankColors.onSurfaceVariant,
            )),
      );

  Widget _underlineField({
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
