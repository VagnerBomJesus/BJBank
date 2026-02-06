import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../models/card_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/firestore_service.dart';

/// Cards Screen
/// Display and manage user's bank cards
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  int _currentCardIndex = 0;
  List<CardModel> _cards = [];
  bool _isLoading = true;
  bool _showCardNumber = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final authProvider = context.read<AuthProvider>();

      if (authProvider.user == null) {
        if (mounted) {
          setState(() {
            _cards = [];
            _isLoading = false;
          });
        }
        return;
      }

      final cards = await _firestoreService.getUserCards(authProvider.user!.id);

      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
          if (_currentCardIndex >= _cards.length && _cards.isNotEmpty) {
            _currentCardIndex = _cards.length - 1;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading cards: $e');
      if (mounted) {
        setState(() {
          _cards = [];
          _isLoading = false;
        });
      }
    }
  }

  Color _getCardColor(CardModel card) {
    switch (card.type) {
      case CardType.debit:
        return BJBankColors.primary;
      case CardType.credit:
        return BJBankColors.quantum;
      case CardType.prepaid:
        return BJBankColors.tertiary;
      case CardType.virtual:
        return BJBankColors.secondary;
    }
  }

  Color _getCardSecondaryColor(CardModel card) {
    switch (card.type) {
      case CardType.debit:
        return BJBankColors.primaryDark;
      case CardType.credit:
        return const Color(0xFF008B8B);
      case CardType.prepaid:
        return BJBankColors.tertiaryDark;
      case CardType.virtual:
        return BJBankColors.secondaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: BJBankColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - always visible
          _buildHeader(context, topPadding),

          // Content with animation
          Expanded(
            child: AnimatedOpacity(
              opacity: _isLoading ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: BJBankSpacing.md),
                          Text(
                            'A carregar cartões...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: BJBankColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : _cards.isEmpty
                      ? _buildEmptyState()
                      : _buildCardsContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsContent() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + BJBankSpacing.lg),
      child: Column(
        children: [
          // Cards carousel
          _buildCardsCarousel(),

          // Page indicator
          if (_cards.length > 1) _buildPageIndicator(),

          const SizedBox(height: BJBankSpacing.md),

          // Quick actions
          _buildQuickActions(),

          const SizedBox(height: BJBankSpacing.md),

          // Card details section
          _buildCardDetails(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        BJBankSpacing.lg,
        topPadding + BJBankSpacing.md,
        BJBankSpacing.lg,
        BJBankSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cartões',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: BJBankColors.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _cards.isEmpty
                    ? 'Nenhum cartão'
                    : '${_cards.length} ${_cards.length == 1 ? 'cartão' : 'cartões'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          // Add card button
          _buildCircularIconButton(
            icon: Icons.add_card,
            onTap: () => _showRequestCardSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: BJBankColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: BJBankColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: BJBankColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card_off_outlined,
                size: 56,
                color: BJBankColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: BJBankSpacing.xl),
            Text(
              'Sem cartões',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.sm),
            Text(
              'Ainda não tens nenhum cartão.\nPede o teu primeiro cartão agora!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.xl),
            FilledButton.icon(
              onPressed: () => _showRequestCardSheet(),
              icon: const Icon(Icons.add_card),
              label: const Text('Pedir Cartão'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: BJBankSpacing.xl,
                  vertical: BJBankSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsCarousel() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: _cards.length,
        controller: PageController(viewportFraction: 0.9),
        onPageChanged: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentCardIndex = index;
            _showCardNumber = false;
          });
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.xs),
            child: _buildCardWidget(_cards[index]),
          );
        },
      ),
    );
  }

  Widget _buildCardWidget(CardModel card) {
    final cardColor = _getCardColor(card);
    final secondaryColor = _getCardSecondaryColor(card);
    final isLocked = card.status == CardStatus.blocked;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showCardNumber = !_showCardNumber);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(BJBankSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'BJBank',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: BJBankSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: BJBankSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              card.typeDisplayName.split(' ').last,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildBrandLogo(card.brand),
                    ],
                  ),

                  const Spacer(),

                  // Chip and contactless
                  Row(
                    children: [
                      // Chip
                      Container(
                        width: 50,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BJBankColors.chipGoldLight,
                              BJBankColors.chipGold,
                              BJBankColors.chipGoldDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomPaint(
                          painter: _ChipPatternPainter(),
                        ),
                      ),
                      const SizedBox(width: BJBankSpacing.md),
                      if (card.contactlessEnabled)
                        Icon(
                          Icons.contactless,
                          color: Colors.white.withOpacity(0.8),
                          size: 28,
                        ),
                    ],
                  ),

                  const SizedBox(height: BJBankSpacing.md),

                  // Card number
                  Text(
                    _showCardNumber ? card.formattedNumber : card.maskedNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                      fontFamily: 'monospace',
                    ),
                  ),

                  const SizedBox(height: BJBankSpacing.md),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TITULAR',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            card.holderName.isNotEmpty
                                ? card.holderName
                                : 'TITULAR BJBANK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'VALIDADE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            card.expiryDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Locked overlay
            if (isLocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(BJBankSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: BJBankSpacing.sm),
                      const Text(
                        'Cartão Bloqueado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandLogo(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        );
      case CardBrand.mastercard:
        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            Transform.translate(
              offset: const Offset(-10, 0),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      case CardBrand.maestro:
        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: BJBankSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_cards.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentCardIndex == index ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentCardIndex == index
                  ? _getCardColor(_cards[index])
                  : BJBankColors.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickActions() {
    if (_cards.isEmpty) return const SizedBox.shrink();

    final currentCard = _cards[_currentCardIndex];
    final isLocked = currentCard.status == CardStatus.blocked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              label: isLocked ? 'Desbloquear' : 'Bloquear',
              color: isLocked ? BJBankColors.success : BJBankColors.warning,
              onTap: () => _toggleCardLock(currentCard),
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.visibility_outlined,
              label: 'Ver Dados',
              color: BJBankColors.info,
              onTap: () => _showCardDataSheet(currentCard),
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.tune_rounded,
              label: 'Definições',
              color: BJBankColors.primary,
              onTap: () => _showCardSettings(currentCard),
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Eliminar',
              color: BJBankColors.error,
              onTap: () => _confirmDeleteCard(currentCard),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: BJBankSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetails() {
    if (_cards.isEmpty) return const SizedBox.shrink();

    final currentCard = _cards[_currentCardIndex];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: BJBankSpacing.sm),
      padding: const EdgeInsets.all(BJBankSpacing.lg),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: BJBankColors.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BJBankColors.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          Text(
            'Detalhes do Cartão',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: BJBankSpacing.lg),
          _buildDetailRow(
            icon: Icons.credit_card_outlined,
            label: 'Tipo',
            value: currentCard.typeDisplayName,
          ),
          _buildDetailRow(
            icon: Icons.payment_outlined,
            label: 'Bandeira',
            value: currentCard.brandDisplayName,
          ),
          _buildDetailRow(
            icon: currentCard.status == CardStatus.active
                ? Icons.check_circle_outline
                : Icons.block_outlined,
            label: 'Estado',
            value: currentCard.status == CardStatus.active
                ? 'Ativo'
                : currentCard.status == CardStatus.blocked
                    ? 'Bloqueado'
                    : 'Inativo',
            valueColor: currentCard.status == CardStatus.active
                ? BJBankColors.success
                : BJBankColors.error,
          ),
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Validade',
            value: currentCard.expiryDate,
          ),
          _buildDetailRow(
            icon: Icons.trending_up_outlined,
            label: 'Limite Diário',
            value: '€ ${currentCard.dailyLimit.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            icon: Icons.date_range_outlined,
            label: 'Limite Mensal',
            value: '€ ${currentCard.monthlyLimit.toStringAsFixed(2)}',
          ),
          const SizedBox(height: BJBankSpacing.lg),
          const Divider(),
          const SizedBox(height: BJBankSpacing.md),
          Text(
            'Funcionalidades',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BJBankColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          _buildFeatureChip(
            icon: Icons.contactless,
            label: 'Contactless',
            enabled: currentCard.contactlessEnabled,
          ),
          _buildFeatureChip(
            icon: Icons.language,
            label: 'Pagamentos Online',
            enabled: currentCard.onlinePaymentsEnabled,
          ),
          _buildFeatureChip(
            icon: Icons.flight_takeoff,
            label: 'Internacional',
            enabled: currentCard.internationalEnabled,
          ),
          const SizedBox(height: BJBankSpacing.lg),
          // Security badge
          Container(
            padding: const EdgeInsets.all(BJBankSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BJBankColors.quantum.withOpacity(0.1),
                  BJBankColors.shield.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BJBankColors.quantum.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(BJBankSpacing.sm),
                  decoration: BoxDecoration(
                    color: BJBankColors.quantum.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: BJBankColors.quantum,
                    size: 24,
                  ),
                ),
                const SizedBox(width: BJBankSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proteção PQC Ativa',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: BJBankColors.quantum,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Criptografia Pós-Quântica',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BJBankSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BJBankColors.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: BJBankColors.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: BJBankSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? BJBankColors.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BJBankSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: enabled
                  ? BJBankColors.success.withOpacity(0.15)
                  : BJBankColors.outline.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: enabled ? BJBankColors.success : BJBankColors.outline,
              size: 16,
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BJBankSpacing.sm,
              vertical: BJBankSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: enabled
                  ? BJBankColors.success.withOpacity(0.1)
                  : BJBankColors.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              enabled ? 'Ativo' : 'Inativo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled ? BJBankColors.success : BJBankColors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== Actions ==============

  Future<void> _toggleCardLock(CardModel card) async {
    final newStatus = card.status == CardStatus.blocked
        ? CardStatus.active
        : CardStatus.blocked;

    try {
      await _firestoreService.updateCardStatus(card.id, newStatus);
      await _loadCards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == CardStatus.blocked
                  ? 'Cartão bloqueado temporariamente'
                  : 'Cartão desbloqueado',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: newStatus == CardStatus.blocked
                ? BJBankColors.warning
                : BJBankColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar cartão: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: BJBankColors.error,
          ),
        );
      }
    }
  }

  void _showCardDataSheet(CardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: BJBankColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: BJBankSpacing.sm),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: BJBankColors.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(BJBankSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Dados do Cartão',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: BJBankSpacing.xs),
                        Text(
                          'Mantenha estes dados em segurança',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: BJBankColors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: BJBankSpacing.lg),

                        _buildCopyableDataItem(
                          label: 'Número do Cartão',
                          value: card.formattedNumber,
                          icon: Icons.credit_card,
                        ),
                        _buildCopyableDataItem(
                          label: 'Data de Validade',
                          value: card.expiryDate,
                          icon: Icons.calendar_today,
                        ),
                        _buildCopyableDataItem(
                          label: 'CVV',
                          value: card.cvv,
                          icon: Icons.lock,
                        ),
                        _buildCopyableDataItem(
                          label: 'Titular',
                          value: card.holderName,
                          icon: Icons.person,
                        ),

                        const SizedBox(height: BJBankSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(BJBankSpacing.md),
                          decoration: BoxDecoration(
                            color: BJBankColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: BJBankColors.warning, size: 20),
                              const SizedBox(width: BJBankSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Nunca partilhe estes dados com terceiros',
                                  style: TextStyle(
                                    color: BJBankColors.warningDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(ctx).padding.bottom + BJBankSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopyableDataItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: BJBankSpacing.md),
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BJBankColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: BJBankColors.primary, size: 22),
          ),
          const SizedBox(width: BJBankSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: BJBankColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value.replaceAll(' ', '')));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copiado'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCardSettings(CardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CardSettingsSheet(
        card: card,
        firestoreService: _firestoreService,
        onUpdate: _loadCards,
      ),
    );
  }

  void _confirmDeleteCard(CardModel card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Cartão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: BJBankColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever,
                color: BJBankColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: BJBankSpacing.md),
            Text(
              'Tem a certeza que deseja eliminar este cartão?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BJBankSpacing.sm),
            Text(
              '•••• ${card.lastFourDigits}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: BJBankColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BJBankSpacing.sm),
            Text(
              'Esta ação não pode ser revertida.',
              style: TextStyle(
                color: BJBankColors.error,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteCard(card);
            },
            style: FilledButton.styleFrom(
              backgroundColor: BJBankColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(CardModel card) async {
    try {
      await _firestoreService.deleteCard(card.id);
      await _loadCards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cartão eliminado com sucesso'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao eliminar cartão: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: BJBankColors.error,
          ),
        );
      }
    }
  }

  void _showRequestCardSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RequestCardSheet(
        firestoreService: _firestoreService,
        onCardCreated: _loadCards,
      ),
    );
  }
}

// ============== Card Settings Sheet ==============

class _CardSettingsSheet extends StatefulWidget {
  final CardModel card;
  final FirestoreService firestoreService;
  final VoidCallback onUpdate;

  const _CardSettingsSheet({
    required this.card,
    required this.firestoreService,
    required this.onUpdate,
  });

  @override
  State<_CardSettingsSheet> createState() => _CardSettingsSheetState();
}

class _CardSettingsSheetState extends State<_CardSettingsSheet> {
  late bool _contactless;
  late bool _onlinePayments;
  late bool _international;

  @override
  void initState() {
    super.initState();
    _contactless = widget.card.contactlessEnabled;
    _onlinePayments = widget.card.onlinePaymentsEnabled;
    _international = widget.card.internationalEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: BJBankSpacing.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BJBankColors.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BJBankSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Definições do Cartão',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: BJBankSpacing.xl),

                    _buildSettingSwitch(
                      icon: Icons.contactless,
                      label: 'Pagamentos Contactless',
                      subtitle: 'Pagar aproximando o cartão',
                      value: _contactless,
                      onChanged: (v) => setState(() => _contactless = v),
                    ),
                    _buildSettingSwitch(
                      icon: Icons.language,
                      label: 'Pagamentos Online',
                      subtitle: 'Compras na internet',
                      value: _onlinePayments,
                      onChanged: (v) => setState(() => _onlinePayments = v),
                    ),
                    _buildSettingSwitch(
                      icon: Icons.flight_takeoff,
                      label: 'Pagamentos Internacionais',
                      subtitle: 'Usar fora de Portugal',
                      value: _international,
                      onChanged: (v) => setState(() => _international = v),
                    ),

                    const SizedBox(height: BJBankSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveSettings,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Guardar Alterações'),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + BJBankSpacing.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BJBankSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BJBankColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: BJBankColors.primary),
          ),
          const SizedBox(width: BJBankSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: BJBankColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: BJBankColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await widget.firestoreService.updateCardSettings(
        widget.card.id,
        contactlessEnabled: _contactless,
        onlinePaymentsEnabled: _onlinePayments,
        internationalEnabled: _international,
      );
      widget.onUpdate();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Definições atualizadas'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: BJBankColors.error,
          ),
        );
      }
    }
  }
}

// ============== Request Card Sheet ==============

class _RequestCardSheet extends StatefulWidget {
  final FirestoreService firestoreService;
  final VoidCallback onCardCreated;

  const _RequestCardSheet({
    required this.firestoreService,
    required this.onCardCreated,
  });

  @override
  State<_RequestCardSheet> createState() => _RequestCardSheetState();
}

class _RequestCardSheetState extends State<_RequestCardSheet> {
  CardType _selectedType = CardType.debit;
  CardBrand _selectedBrand = CardBrand.visa;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: BJBankSpacing.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BJBankColors.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BJBankSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pedir Novo Cartão',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: BJBankSpacing.xs),
                    Text(
                      'Escolhe o tipo de cartão que pretendes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BJBankColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: BJBankSpacing.lg),

                    // Card Type Selection
                    Text(
                      'Tipo de Cartão',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: BJBankSpacing.sm),
                    Wrap(
                      spacing: BJBankSpacing.sm,
                      runSpacing: BJBankSpacing.sm,
                      children: CardType.values.map((type) {
                        return _buildTypeChip(type);
                      }).toList(),
                    ),

                    const SizedBox(height: BJBankSpacing.lg),

                    // Brand Selection
                    Text(
                      'Bandeira',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: BJBankSpacing.sm),
                    Wrap(
                      spacing: BJBankSpacing.xs,
                      runSpacing: BJBankSpacing.xs,
                      alignment: WrapAlignment.center,
                      children: CardBrand.values.map((brand) {
                        return _buildBrandChip(brand);
                      }).toList(),
                    ),

                    const SizedBox(height: BJBankSpacing.lg),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(BJBankSpacing.md),
                      decoration: BoxDecoration(
                        color: BJBankColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: BJBankColors.info, size: 20),
                          const SizedBox(width: BJBankSpacing.sm),
                          Expanded(
                            child: Text(
                              'O cartão será criado instantaneamente',
                              style: TextStyle(
                                color: BJBankColors.infoDark,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: BJBankSpacing.lg),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _createCard,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Pedir Cartão'),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + BJBankSpacing.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(CardType type) {
    final isSelected = _selectedType == type;
    String label;
    IconData icon;

    switch (type) {
      case CardType.debit:
        label = 'Débito';
        icon = Icons.account_balance_wallet;
        break;
      case CardType.credit:
        label = 'Crédito';
        icon = Icons.credit_card;
        break;
      case CardType.prepaid:
        label = 'Pré-pago';
        icon = Icons.card_giftcard;
        break;
      case CardType.virtual:
        label = 'Virtual';
        icon = Icons.phone_android;
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.md,
          vertical: BJBankSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? BJBankColors.primary.withOpacity(0.15)
              : BJBankColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BJBankColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? BJBankColors.primary
                  : BJBankColors.onSurfaceVariant,
            ),
            const SizedBox(width: BJBankSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? BJBankColors.primary
                    : BJBankColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandChip(CardBrand brand) {
    final isSelected = _selectedBrand == brand;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedBrand = brand);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: BJBankSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.lg,
          vertical: BJBankSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? BJBankColors.primary.withOpacity(0.15)
              : BJBankColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BJBankColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          brand == CardBrand.visa
              ? 'Visa'
              : brand == CardBrand.mastercard
                  ? 'Mastercard'
                  : 'Maestro',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? BJBankColors.primary
                : BJBankColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _createCard() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final accountProvider = context.read<AccountProvider>();

      if (authProvider.user == null || accountProvider.primaryAccount == null) {
        throw Exception('Utilizador ou conta não encontrada');
      }

      await widget.firestoreService.createDefaultCard(
        userId: authProvider.user!.id,
        accountId: accountProvider.primaryAccount!.id,
        holderName: authProvider.user!.name,
        type: _selectedType,
        brand: _selectedBrand,
      );

      widget.onCardCreated();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cartão criado com sucesso!'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ============== Custom Painters ==============

class _ChipPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal lines
    for (var i = 0; i < 4; i++) {
      final y = size.height * (i + 1) / 5;
      canvas.drawLine(
        Offset(4, y),
        Offset(size.width - 4, y),
        paint,
      );
    }

    // Vertical lines
    for (var i = 0; i < 3; i++) {
      final x = size.width * (i + 1) / 4;
      canvas.drawLine(
        Offset(x, 4),
        Offset(x, size.height - 4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
