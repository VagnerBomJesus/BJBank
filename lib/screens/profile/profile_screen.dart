import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Profile Screen
/// View and edit user profile information
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      // Convert to base64 and save to Firestore
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final userId = AuthService.currentUserId;
      if (userId == null) return;

      await _firestoreService.updateUser(userId, {
        'photoUrl': base64Image,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil atualizada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar foto'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return;

      await _firestoreService.updateUser(userId, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      await AuthService.updateProfile(
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar perfil'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAvatar(String? photoUrl, String? initials) {
    ImageProvider? imageProvider;
    if (photoUrl != null && photoUrl.startsWith('data:image')) {
      final base64Data = photoUrl.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64Data));
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: BJBankColors.primaryContainer,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Text(
                  initials ?? '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: BJBankColors.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BJBankColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final user = authProvider.user;
    final account = accountProvider.primaryAccount;

    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _loadUserData();
                setState(() => _isEditing = false);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar with photo support
              _buildAvatar(user?.photoUrl, user?.initials),

              const SizedBox(height: BJBankSpacing.xl),

              // Personal info section
              _buildSectionHeader('Informações Pessoais'),
              const SizedBox(height: BJBankSpacing.sm),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  child: Column(
                    children: [
                      // Name
                      _isEditing
                          ? TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nome é obrigatório';
                                }
                                return null;
                              },
                            )
                          : _buildInfoRow(
                              Icons.person_outline,
                              'Nome',
                              user?.name ?? '-',
                            ),

                      const Divider(height: BJBankSpacing.lg),

                      // Email (read-only)
                      _buildInfoRow(
                        Icons.email_outlined,
                        'Email',
                        user?.email ?? '-',
                      ),

                      const Divider(height: BJBankSpacing.lg),

                      // Phone
                      _isEditing
                          ? TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                                prefixIcon: Icon(Icons.phone_outlined),
                                hintText: '+351 912 345 678',
                              ),
                            )
                          : _buildInfoRow(
                              Icons.phone_outlined,
                              'Telefone',
                              user?.formattedPhone ?? '-',
                            ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: BJBankSpacing.lg),

              // Account info section
              _buildSectionHeader('Conta Bancária'),
              const SizedBox(height: BJBankSpacing.sm),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.account_balance_outlined,
                        'IBAN',
                        account?.formattedIban ?? '-',
                      ),
                      const Divider(height: BJBankSpacing.lg),
                      _buildInfoRow(
                        Icons.numbers_outlined,
                        'Nº Conta',
                        account?.accountNumber ?? '-',
                      ),
                      const Divider(height: BJBankSpacing.lg),
                      _buildInfoRow(
                        Icons.credit_card_outlined,
                        'Tipo',
                        account?.typeDisplayName ?? '-',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: BJBankSpacing.lg),

              // PQC info section
              _buildSectionHeader('Segurança PQC'),
              const SizedBox(height: BJBankSpacing.sm),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.security,
                        'Algoritmo',
                        'CRYSTALS-Dilithium',
                        iconColor: BJBankColors.quantum,
                      ),
                      const Divider(height: BJBankSpacing.lg),
                      _buildInfoRow(
                        Icons.shield_outlined,
                        'Nível',
                        'Nível 3 (192 bits)',
                        iconColor: BJBankColors.quantum,
                      ),
                      const Divider(height: BJBankSpacing.lg),
                      _buildInfoRow(
                        Icons.key_outlined,
                        'Chaves PQC',
                        user?.hasPqcKeys == true ? 'Configuradas' : 'Não configuradas',
                        iconColor: BJBankColors.quantum,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: BJBankSpacing.xl),

              // Save button (when editing)
              if (_isEditing)
                FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar Alterações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

              const SizedBox(height: BJBankSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: BJBankColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? BJBankColors.onSurfaceVariant),
        const SizedBox(width: BJBankSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
