import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../cards/cards_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/notification_preferences_screen.dart';
import 'edit_profile_screen.dart';

/// Profile hub (UI-kit style): avatar + name + a list of options.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: BJBankColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  BJBankSpacing.md, BJBankSpacing.sm, BJBankSpacing.md, 0),
              child: Row(
                children: [
                  _circle(
                    Icons.arrow_back_ios_new_rounded,
                    () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text('Perfil',
                        textAlign: TextAlign.center,
                        style: BJBankTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BJBankColors.onSurface,
                        )),
                  ),
                  _circle(
                    Icons.edit_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: BJBankSpacing.lg),

            // Identity
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: BJBankSpacing.lg),
              child: Row(
                children: [
                  _avatar(user?.photoUrl, user?.initials),
                  const SizedBox(width: BJBankSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Utilizador',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BJBankTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: BJBankColors.onSurface,
                            )),
                        const SizedBox(height: 2),
                        Text(user?.email ?? 'Cliente BJBank',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BJBankTypography.bodyMedium.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: BJBankSpacing.lg),

            // Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: BJBankSpacing.lg, vertical: BJBankSpacing.xs),
                children: [
                  _row(context, Icons.person_outline_rounded,
                      'Informações Pessoais',
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()),
                          )),
                  _row(context, Icons.account_balance_outlined,
                      'Detalhes da Conta',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.accountDetails)),
                  _row(context, Icons.credit_card_outlined, 'Bancos e Cartões',
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CardsScreen()),
                          )),
                  _row(context, Icons.smartphone_rounded, 'MB WAY',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.mbwaySettings)),
                  _row(context, Icons.notifications_none_rounded,
                      'Notificações',
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationPreferencesScreen()),
                          )),
                  _row(context, Icons.description_outlined,
                      'Documentos e Extratos',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.documents)),
                  _row(context, Icons.shield_outlined, 'Segurança PQC',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.pqcBenchmark)),
                  _row(context, Icons.settings_outlined, 'Definições',
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const Scaffold(body: SettingsScreen()),
                            ),
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label,
      {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 22, color: BJBankColors.onSurfaceVariant),
              const SizedBox(width: BJBankSpacing.md),
              Expanded(
                child: Text(label,
                    style: BJBankTypography.bodyLarge.copyWith(
                      color: BJBankColors.onSurface,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: BJBankColors.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String? photoUrl, String? initials) {
    ImageProvider? img;
    if (photoUrl != null && photoUrl.startsWith('data:image')) {
      img = MemoryImage(base64Decode(photoUrl.split(',').last));
    }
    return CircleAvatar(
      radius: 34,
      backgroundColor: BJBankColors.primaryContainer,
      backgroundImage: img,
      child: img == null
          ? Text(initials ?? '?',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BJBankColors.onPrimaryContainer))
          : null,
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) {
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
