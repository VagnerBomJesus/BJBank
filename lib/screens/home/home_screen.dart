import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../models/transaction_model.dart' show Transaction;
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
// auth_service.dart removido: usar AuthProvider (Supabase) em vez disso.
import '../../routes/app_routes.dart';
import '../history/history_screen.dart';
import '../cards/cards_screen.dart';
import '../settings/settings_screen.dart';
import '../analysis/analysis_screen.dart';
import '../search/search_screen.dart';

/// Home Screen - Modern Banking Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Adiar carregamento para depois do primeiro frame: evita
    // setState()/notifyListeners() durante o build do provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAccountData();
    });
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadAccountData() {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<AccountProvider>().loadAccount(userId);
    }
  }

  Future<void> _refreshData() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await context.read<AccountProvider>().refreshTransactions(userId);
    }
  }

  void _onNavItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeContent(),
          const CardsScreen(),
          AnalysisScreen(onBack: () => _onNavItemTapped(0)),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    final authProvider = context.watch<AuthProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final user = authProvider.user;
    final userName = user?.firstName ?? 'Utilizador';
    final holderName = user?.name ?? userName;

    return Column(
      children: [
        // Fixed Header
        _buildFixedHeader(userName, user?.photoUrl, user?.initials),

        // Scrollable Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: ListView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.zero,
              children: [
                // Balance Section
                _buildBalanceSection(
                    accountProvider, settingsProvider, holderName),

                const SizedBox(height: 28),

                // Quick Services
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuickServices(),
                ),

                const SizedBox(height: 28),

                // Recent Transactions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTransactionsSection(accountProvider),
                ),

                // Bottom spacing for FAB
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedHeader(String userName, String? photoUrl, String? initials) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + BJBankSpacing.sm,
        left: 20,
        right: 20,
        bottom: BJBankSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: _buildAvatar(photoUrl, initials),
          ),
          const SizedBox(width: 14),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo de volta,',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  userName,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // Search Icon (mockup style)
          _buildHeaderIconButton(
            Icons.search_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(
    AccountProvider accountProvider,
    SettingsProvider settingsProvider,
    String holderName,
  ) {
    final account = accountProvider.primaryAccount;
    final visible = settingsProvider.isBalanceVisible;
    final ibanDisplay = visible
        ? (account?.formattedIban ?? 'PT50 •••• •••• •••• •••• •••• •')
        : (account?.maskedIban ?? 'PT50 •••• •••• •••• •••• •••• •');

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        gradient: BJBankColors.cardNavyGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: BJBankColors.cardNavyDeep.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: BJBankColors.accentBlue.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Blue glow (UI-kit signature)
            Positioned(
              right: -70,
              top: -20,
              bottom: -50,
              child: Container(
                width: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      BJBankColors.accentBlue.withValues(alpha: 0.45),
                      BJBankColors.accentBlue.withValues(alpha: 0.0),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
            // Faint dotted "world map" texture
            Positioned.fill(
              child: CustomPaint(painter: _CardMapDotsPainter()),
            ),

            Padding(
              padding: const EdgeInsets.all(BJBankSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: chip + contactless + visibility toggle
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: BJBankColors.onPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.memory_rounded,
                          size: 20,
                          color: BJBankColors.onPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.contactless_rounded,
                        size: 26,
                        color: BJBankColors.onPrimary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: BJBankSpacing.xs),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          settingsProvider.toggleBalanceVisibility();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color:
                                BJBankColors.onPrimary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            visible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: BJBankColors.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Available balance (hero)
                  Text(
                    'Saldo disponível',
                    style: BJBankTypography.labelMedium.copyWith(
                      color: BJBankColors.onPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: BJBankSpacing.xxs),
                  accountProvider.isLoading
                      ? Container(
                          height: 40,
                          width: 170,
                          decoration: BoxDecoration(
                            color:
                                BJBankColors.onPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            visible
                                ? account?.formattedBalance ?? '€ 0,00'
                                : '€ ••••••',
                            key: ValueKey(visible),
                            style: BJBankTypography.balanceLarge.copyWith(
                              color: BJBankColors.onPrimary,
                              fontSize: 32,
                            ),
                          ),
                        ),

                  const SizedBox(height: 22),

                  // IBAN of the logged-in account
                  Row(
                    children: [
                      Text(
                        'IBAN',
                        style: BJBankTypography.labelSmall.copyWith(
                          color: BJBankColors.onPrimary.withValues(alpha: 0.5),
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: BJBankSpacing.xs),
                      Expanded(
                        child: Text(
                          ibanDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BJBankTypography.valueSmall.copyWith(
                            color:
                                BJBankColors.onPrimary.withValues(alpha: 0.92),
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (visible)
                        GestureDetector(
                          onTap: () {
                            final iban = account?.iban;
                            if (iban != null && iban.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: iban));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('IBAN copiado'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color:
                                BJBankColors.onPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Bottom: holder + validade + Mastercard mark
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TITULAR',
                              style: BJBankTypography.labelSmall.copyWith(
                                color: BJBankColors.onPrimary
                                    .withValues(alpha: 0.5),
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              holderName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BJBankTypography.titleSmall.copyWith(
                                color: BJBankColors.onPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: BJBankSpacing.md),
                      // Quantum Safe pill (PQC identity)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BJBankSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BJBankColors.onPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: BJBankColors.quantum.withValues(alpha: 0.35),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 11,
                              color:
                                  BJBankColors.quantum.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quantum Safe',
                              style: BJBankTypography.labelSmall.copyWith(
                                color: BJBankColors.onPrimary
                                    .withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: BJBankSpacing.sm),
                      // Mastercard-style mark
                      SizedBox(
                        width: 40,
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
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEB001B),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF79E1B)
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildHeaderIconButton(IconData icon, {bool badge = false, VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: BJBankSpacing.minTouchTarget,
        height: BJBankSpacing.minTouchTarget,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: colorScheme.onSurfaceVariant,
                size: BJBankSpacing.iconMd,
              ),
            ),
            if (badge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, String? initials) {
    ImageProvider? imageProvider;
    if (photoUrl != null && photoUrl.startsWith('data:image')) {
      try {
        final base64Data = photoUrl.split(',').last;
        imageProvider = MemoryImage(base64Decode(base64Data));
      } catch (_) {}
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 2,
        ),
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
        gradient: imageProvider == null ? BJBankColors.primaryGradient : null,
      ),
      child: imageProvider == null
          ? Center(
              child: Text(
                initials ?? '?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BJBankColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            )
          : null,
    );
  }

  Widget _buildQuickServices() {
    // Single row of minimalist circular actions (mockup style)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCircularServiceButton(
          icon: Icons.north_rounded,
          label: 'Transferir',
          color: BJBankColors.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.transfer),
        ),
        _buildCircularServiceButton(
          imageAsset: 'assets/mbway.png',
          label: 'MB WAY',
          color: BJBankColors.mbwayRed,
          onTap: () => Navigator.pushNamed(context, AppRoutes.mbway),
        ),
        _buildCircularServiceButton(
          icon: Icons.qr_code_scanner_rounded,
          label: 'QR Code',
          color: BJBankColors.shield,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('QR Code - Em breve'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        _buildCircularServiceButton(
          icon: Icons.grid_view_rounded,
          label: 'Mais',
          color: BJBankColors.onSurfaceVariant,
          onTap: () => _showQuickActionsSheet(),
        ),
      ],
    );
  }

  Widget _buildCircularServiceButton({
    IconData? icon,
    String? imageAsset,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    assert(icon != null || imageAsset != null,
        'icon ou imageAsset obrigatorio');
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.45),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: imageAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(BJBankSpacing.sm),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(AccountProvider accountProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Atividade Recente',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: BJBankSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      'Ver tudo',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: BJBankSpacing.xxs),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BJBankSpacing.md),
        accountProvider.isLoading
            ? _buildTransactionsSkeleton()
            : _buildTransactionsList(accountProvider.transactions),
      ],
    );
  }

  Widget _buildTransactionsSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BJBankSpacing.md,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: BJBankSpacing.xs),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: BJBankSpacing.xs),
                    Container(
                      height: 16,
                      width: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayTransactions = transactions.take(5).toList();

    if (displayTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: BJBankSpacing.iconLg,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: BJBankSpacing.md),
            Text(
              'Sem transações',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: BJBankSpacing.xxs),
            Text(
              'As suas transações aparecerão aqui',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: displayTransactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          return Column(
            children: [
              _buildTransactionTile(transaction),
              if (index < displayTransactions.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BJBankSpacing.md,
                  ),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BJBankSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Circular icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: transaction.iconColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  transaction.icon,
                  size: BJBankSpacing.iconMd,
                  color: transaction.iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BJBankSpacing.xxs),
                    Row(
                      children: [
                        Text(
                          transaction.formattedDate,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (transaction.isEncrypted) ...[
                          const SizedBox(width: BJBankSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: BJBankColors.quantum.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shield_rounded,
                                  size: 10,
                                  color: BJBankColors.quantum,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'PQC',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: BJBankColors.quantum,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BJBankSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedAmount,
                    style: BJBankTypography.valueSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.amountColor,
                    ),
                  ),
                  const SizedBox(height: BJBankSpacing.xxs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: BJBankColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Concluída',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: BJBankColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBottomNav() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  0, Icons.home_outlined, Icons.home_rounded, 'Início'),
              _buildNavItem(1, Icons.credit_card_outlined, Icons.credit_card,
                  'Cartões'),
              _buildNavItem(2, Icons.bar_chart_outlined, Icons.bar_chart,
                  'Estatísticas'),
              _buildNavItem(3, Icons.settings_outlined, Icons.settings_rounded,
                  'Definições'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _currentNavIndex == index;

    Widget iconWidget = Icon(
      isSelected ? selectedIcon : icon,
      size: 22,
      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          badgeCount > 9 ? '9+' : '$badgeCount',
          style: textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: colorScheme.onError,
          ),
        ),
        backgroundColor: colorScheme.error,
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: BJBankSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(BJBankSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: BJBankSpacing.lg),
            Text(
              'Nova Operação',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionCircleItem(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transferir',
                  color: BJBankColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.transfer);
                  },
                ),
                _buildQuickActionCircleItem(
                  icon: Icons.smartphone_rounded,
                  label: 'MB WAY',
                  color: BJBankColors.mbwayRed,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.mbway);
                  },
                ),
                _buildQuickActionCircleItem(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'QR Code',
                  color: BJBankColors.shield,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: BJBankSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCircleItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(BJBankSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Transaction icon - circular
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: transaction.iconColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                transaction.icon,
                size: 40,
                color: transaction.iconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              transaction.description,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BJBankSpacing.sm,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                transaction.category ?? 'Transação',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 28),

            // Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(BJBankSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    transaction.iconColor.withValues(alpha: 0.08),
                    transaction.iconColor.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: transaction.iconColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Valor',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: BJBankSpacing.xs),
                  Text(
                    transaction.formattedAmount,
                    style: BJBankTypography.balanceLarge.copyWith(
                      color: transaction.amountColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BJBankSpacing.lg),

            // Details
            _buildDetailItem('Data', transaction.formattedDate),
            _buildDetailItem('Estado', 'Concluída', valueColor: BJBankColors.success),
            if (transaction.isEncrypted)
              _buildDetailItem(
                'Segurança',
                'Criptografia PQC',
                valueColor: BJBankColors.quantum,
                icon: Icons.shield_rounded,
              ),

            const SizedBox(height: 28),

            // Close button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: BJBankSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Fechar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor, IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: BJBankSpacing.iconXs,
                  color: valueColor ?? colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints a faint grid of dots evoking a world-map texture on the home card.
class _CardMapDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BJBankColors.onPrimary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const double spacing = 11.0;
    final rng = math.Random(42);
    for (double y = 8; y < size.height; y += spacing) {
      for (double x = 8; x < size.width; x += spacing) {
        if (rng.nextDouble() < 0.4) continue;
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardMapDotsPainter oldDelegate) => false;
}
