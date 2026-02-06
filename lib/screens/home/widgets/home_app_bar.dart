import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../theme/app_strings.dart';

/// Home Screen App Bar
/// Clean design with greeting, avatar and notifications
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    this.userName = 'Utilizador',
    this.userPhotoUrl,
    this.onProfileTap,
    this.onNotificationsTap,
  });

  final String userName;
  final String? userPhotoUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.homeGreetingMorning;
    if (hour < 18) return AppStrings.homeGreetingAfternoon;
    return AppStrings.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BJBankSpacing.lg,
            vertical: BJBankSpacing.sm,
          ),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: onProfileTap,
                child: _buildAvatar(),
              ),

              const SizedBox(width: BJBankSpacing.md),

              // Greeting and name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _greeting,
                      style: BJBankTypography.bodyMedium.copyWith(
                        color: BJBankColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      userName,
                      style: BJBankTypography.titleMedium.copyWith(
                        color: BJBankColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Notifications
              Container(
                decoration: BoxDecoration(
                  color: BJBankColors.surfaceVariant.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onNotificationsTap,
                  icon: Badge(
                    smallSize: 8,
                    backgroundColor: BJBankColors.error,
                    child: Icon(
                      Icons.notifications_outlined,
                      color: BJBankColors.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (userPhotoUrl != null && userPhotoUrl!.startsWith('data:image')) {
      final base64Data = userPhotoUrl!.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64Data));
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageProvider == null
            ? LinearGradient(
                colors: [
                  BJBankColors.primary,
                  BJBankColors.primaryDark,
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: BJBankColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Text(
                _getInitials(userName),
                style: BJBankTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
