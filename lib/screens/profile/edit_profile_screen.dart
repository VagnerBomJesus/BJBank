import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

/// Edit Profile screen (UI-kit style): centred avatar + underline form.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      final cleaned = (user.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
      String local = cleaned;
      if (cleaned.startsWith('351') && cleaned.length == 12) {
        local = cleaned.substring(3);
      } else if (cleaned.startsWith('00351') && cleaned.length == 14) {
        local = cleaned.substring(5);
      }
      _phoneController.text = _formatPhoneLocal(local);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhoneLocal(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  String? _validatePhone(String? value) {
    final cleaned = (value ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return 'Telefone obrigatório';
    if (cleaned.length != 9) return 'O número deve ter 9 dígitos';
    if (!cleaned.startsWith('9')) return 'Número de telemóvel inválido';
    return null;
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await _imagePicker.pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 75);
      if (picked == null) return;
      final bytes = await File(picked.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) return;
      await _firestoreService.updateUser(userId, {'photoUrl': base64Image});
      if (mounted) await context.read<AuthProvider>().refreshProfile();
      _snack('Foto de perfil atualizada');
    } catch (_) {
      _snack('Erro ao atualizar foto');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) return;
      final localDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      final normalizedPhone =
          localDigits.length == 9 ? '+351$localDigits' : _phoneController.text.trim();
      await _firestoreService.updateUser(userId, {
        'name': _nameController.text.trim(),
        'phone': normalizedPhone,
      });
      await AuthService.updateProfile(displayName: _nameController.text.trim());
      if (mounted) await context.read<AuthProvider>().refreshProfile();
      if (mounted) {
        Navigator.pop(context);
        _snack('Perfil atualizado com sucesso');
      }
    } catch (_) {
      _snack('Erro ao atualizar perfil');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
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
                    child: Text('Editar Perfil',
                        textAlign: TextAlign.center,
                        style: BJBankTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BJBankColors.onSurface,
                        )),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    // Avatar
                    Center(child: _avatar(user?.photoUrl, user?.initials)),
                    const SizedBox(height: BJBankSpacing.md),
                    Center(
                      child: Text(user?.name ?? '-',
                          style: BJBankTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: BJBankColors.onSurface,
                          )),
                    ),
                    Center(
                      child: Text(user?.email ?? '',
                          style: BJBankTypography.bodySmall.copyWith(
                            color: BJBankColors.onSurfaceVariant,
                          )),
                    ),
                    const SizedBox(height: BJBankSpacing.xl),

                    _label('Nome Completo'),
                    TextFormField(
                      controller: _nameController,
                      decoration: _dec(Icons.person_outline_rounded),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nome é obrigatório'
                          : null,
                    ),
                    const SizedBox(height: BJBankSpacing.lg),

                    _label('Email'),
                    TextFormField(
                      enabled: false,
                      initialValue: user?.email ?? '',
                      decoration: _dec(Icons.mail_outline_rounded),
                    ),
                    const SizedBox(height: BJBankSpacing.lg),

                    _label('Número de Telemóvel'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _PtPhoneFormatter(),
                      ],
                      validator: _validatePhone,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _dec(Icons.phone_outlined, prefix: '+351 '),
                    ),

                    const SizedBox(height: BJBankSpacing.xxl),
                    if (user?.createdAt != null)
                      Center(
                        child: Text('Membro desde ${_fmtDate(user!.createdAt!)}',
                            style: BJBankTypography.bodySmall.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            )),
                      ),
                  ],
                ),
              ),
            ),
            // Save
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: BJBankColors.primary,
                  foregroundColor: BJBankColors.onPrimary,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Guardar Alterações',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _avatar(String? photoUrl, String? initials) {
    ImageProvider? img;
    if (photoUrl != null && photoUrl.startsWith('data:image')) {
      img = MemoryImage(base64Decode(photoUrl.split(',').last));
    }
    return Stack(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: BJBankColors.primaryContainer,
          backgroundImage: img,
          child: img == null
              ? Text(initials ?? '?',
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: BJBankColors.onPrimaryContainer))
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: BJBankColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: BJBankColors.surface, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(t,
            style: BJBankTypography.bodySmall.copyWith(
              color: BJBankColors.onSurfaceVariant,
            )),
      );

  InputDecoration _dec(IconData icon, {String? prefix}) => InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: BJBankColors.onSurfaceVariant),
        prefixText: prefix,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: BJBankSpacing.sm),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: BJBankColors.outlineVariant),
        ),
        disabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: BJBankColors.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: BJBankColors.primary, width: 2),
        ),
      );

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

/// Formats local PT number (9 digits) as "9XX XXX XXX".
class _PtPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 9) return oldValue;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
