import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';

/// History Screen
/// Full transaction history with filters and search
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  TransactionType? _filterType;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isSearchExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    var filtered = transactions;

    // Apply type filter
    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (t.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    return filtered;
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final groups = <String, List<Transaction>>{};
    final now = DateTime.now();

    for (final transaction in transactions) {
      final diff = now.difference(transaction.date);
      String group;

      if (diff.inDays == 0) {
        group = 'Hoje';
      } else if (diff.inDays == 1) {
        group = 'Ontem';
      } else if (diff.inDays < 7) {
        group = 'Esta Semana';
      } else if (diff.inDays < 30) {
        group = 'Este Mês';
      } else {
        group =
            '${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}';
      }

      groups.putIfAbsent(group, () => []);
      groups[group]!.add(transaction);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final allTransactions = accountProvider.transactions;
    final filteredTransactions = _getFilteredTransactions(allTransactions);
    final groupedTransactions = _groupByDate(filteredTransactions);
    final isLoading = accountProvider.isLoadingTransactions;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Search bar (expandable)
          _buildSearchBar(context),

          // Filter chips
          _buildFilterSection(context),

          const SizedBox(height: BJBankSpacing.sm),

          // Summary card
          if (filteredTransactions.isNotEmpty)
            _buildSummaryCard(context, filteredTransactions),

          // Transaction list
          Expanded(
            child: isLoading && allTransactions.isEmpty
                ? _buildLoadingState()
                : filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(groupedTransactions),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: BJBankColors.primary,
          ),
          const SizedBox(height: BJBankSpacing.md),
          Text(
            'A carregar transações...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BJBankColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(
        BJBankSpacing.lg,
        topPadding + BJBankSpacing.md,
        BJBankSpacing.lg,
        BJBankSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: BJBankColors.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Todas as tuas transações',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BJBankColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          Row(
            children: [
              // Search toggle button
              _buildCircularIconButton(
                icon: _isSearchExpanded ? Icons.close : Icons.search,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                    if (!_isSearchExpanded) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
              const SizedBox(width: BJBankSpacing.xs),
              // Filter button
              _buildCircularIconButton(
                icon: Icons.tune_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFilterBottomSheet(context);
                },
                showBadge: _filterType != null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BJBankColors.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: BJBankColors.onSurfaceVariant,
              size: 22,
            ),
          ),
          if (showBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: BJBankColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BJBankColors.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearchExpanded ? 60 : 0,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _isSearchExpanded ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BJBankSpacing.lg,
              vertical: BJBankSpacing.xs,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: BJBankColors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BJBankColors.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome ou categoria...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BJBankColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: BJBankColors.onSurfaceVariant.withOpacity(0.6),
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: BJBankColors.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: BJBankSpacing.md,
                    vertical: BJBankSpacing.sm + 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.lg),
      child: Row(
        children: [
          _buildModernFilterChip(
            context,
            label: 'Todos',
            icon: Icons.receipt_long_outlined,
            type: null,
          ),
          const SizedBox(width: BJBankSpacing.sm),
          _buildModernFilterChip(
            context,
            label: 'Receitas',
            icon: Icons.arrow_downward_rounded,
            type: TransactionType.income,
            activeColor: BJBankColors.success,
          ),
          const SizedBox(width: BJBankSpacing.sm),
          _buildModernFilterChip(
            context,
            label: 'Despesas',
            icon: Icons.arrow_upward_rounded,
            type: TransactionType.expense,
            activeColor: BJBankColors.error,
          ),
          const SizedBox(width: BJBankSpacing.sm),
          _buildModernFilterChip(
            context,
            label: 'Transferências',
            icon: Icons.swap_horiz_rounded,
            type: TransactionType.transfer,
            activeColor: BJBankColors.info,
          ),
          const SizedBox(width: BJBankSpacing.sm),
          _buildModernFilterChip(
            context,
            label: 'MB WAY',
            icon: Icons.phone_android_rounded,
            type: TransactionType.mbway,
            activeColor: BJBankColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required TransactionType? type,
    Color? activeColor,
  }) {
    final isSelected = _filterType == type;
    final chipColor = activeColor ?? BJBankColors.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filterType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.md,
          vertical: BJBankSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.15)
              : BJBankColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? chipColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? chipColor : BJBankColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        isSelected ? chipColor : BJBankColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount.abs();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.lg,
        vertical: BJBankSpacing.sm,
      ),
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BJBankColors.primary.withOpacity(0.08),
            BJBankColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BJBankColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              icon: Icons.arrow_downward_rounded,
              iconColor: BJBankColors.success,
              label: 'Receitas',
              value: '+ ${totalIncome.toStringAsFixed(2)} €',
              valueColor: BJBankColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: BJBankColors.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildSummaryItem(
              context,
              icon: Icons.arrow_upward_rounded,
              iconColor: BJBankColors.error,
              label: 'Despesas',
              value: '- ${totalExpense.toStringAsFixed(2)} €',
              valueColor: BJBankColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: BJBankSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BJBankColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(
      Map<String, List<Transaction>> groupedTransactions) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        BJBankSpacing.lg,
        BJBankSpacing.xs,
        BJBankSpacing.lg,
        BJBankSpacing.xxl,
      ),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final group = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[group]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(context, group),
            ...transactions.map((transaction) {
              return _buildModernTransactionTile(context, transaction);
            }),
            const SizedBox(height: BJBankSpacing.sm),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, String group) {
    return Padding(
      padding: const EdgeInsets.only(
        top: BJBankSpacing.md,
        bottom: BJBankSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BJBankSpacing.sm,
              vertical: BJBankSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: BJBankColors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              group,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Container(
              height: 1,
              color: BJBankColors.outline.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTransactionTile(
      BuildContext context, Transaction transaction) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showTransactionDetails(transaction);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: BJBankSpacing.sm),
        padding: const EdgeInsets.all(BJBankSpacing.md),
        decoration: BoxDecoration(
          color: BJBankColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: BJBankColors.onSurface.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: BJBankColors.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: transaction.iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.icon,
                size: 24,
                color: transaction.iconColor,
              ),
            ),
            const SizedBox(width: BJBankSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: BJBankColors.onSurface,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: BJBankColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BJBankColors.onSurfaceVariant,
                            ),
                      ),
                      if (transaction.category != null) ...[
                        const SizedBox(width: BJBankSpacing.sm),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                BJBankColors.onSurfaceVariant.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: BJBankSpacing.sm),
                        Flexible(
                          child: Text(
                            transaction.category!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: BJBankColors.onSurfaceVariant,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: transaction.type == TransactionType.income
                            ? BJBankColors.success
                            : BJBankColors.onSurface,
                      ),
                ),
                if (transaction.isEncrypted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 12,
                          color: BJBankColors.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'PQC',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: BJBankColors.primary.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
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
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _filterType != null || _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: BJBankColors.surfaceVariant.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.receipt_long_outlined,
                size: 48,
                color: BJBankColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: BJBankSpacing.lg),
            Text(
              hasFilters ? 'Nenhum resultado' : 'Sem transações',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BJBankColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: BJBankSpacing.xs),
            Text(
              hasFilters
                  ? 'Nenhuma transação encontrada com os filtros selecionados'
                  : 'Faz uma transferência ou depósito para ver o histórico aqui',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: BJBankSpacing.lg),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filterType = null;
                    _searchQuery = '';
                    _searchController.clear();
                    _isSearchExpanded = false;
                  });
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: BJBankColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: BJBankSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BJBankColors.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BJBankSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtrar por tipo',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (_filterType != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _filterType = null;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Limpar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: BJBankSpacing.md),
                    _buildFilterOption(
                      context,
                      icon: Icons.receipt_long_outlined,
                      label: 'Todas as transações',
                      type: null,
                    ),
                    _buildFilterOption(
                      context,
                      icon: Icons.arrow_downward_rounded,
                      iconColor: BJBankColors.success,
                      label: 'Receitas',
                      type: TransactionType.income,
                    ),
                    _buildFilterOption(
                      context,
                      icon: Icons.arrow_upward_rounded,
                      iconColor: BJBankColors.error,
                      label: 'Despesas',
                      type: TransactionType.expense,
                    ),
                    _buildFilterOption(
                      context,
                      icon: Icons.swap_horiz_rounded,
                      iconColor: BJBankColors.info,
                      label: 'Transferências',
                      type: TransactionType.transfer,
                    ),
                    _buildFilterOption(
                      context,
                      icon: Icons.phone_android_rounded,
                      iconColor: BJBankColors.warning,
                      label: 'MB WAY',
                      type: TransactionType.mbway,
                    ),
                    const SizedBox(height: BJBankSpacing.md),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required IconData icon,
    Color? iconColor,
    required String label,
    required TransactionType? type,
  }) {
    final isSelected = _filterType == type;
    final color = iconColor ?? BJBankColors.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filterType = type;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: BJBankSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.md,
          vertical: BJBankSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : BJBankColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: BJBankSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? color : BJBankColors.onSurface,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 24,
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
          color: BJBankColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: BJBankSpacing.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BJBankColors.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.lg),
                  child: Column(
                    children: [
                      // Icon and amount
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: transaction.iconColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          transaction.icon,
                          size: 40,
                          color: transaction.iconColor,
                        ),
                      ),
                      const SizedBox(height: BJBankSpacing.md),
                      Text(
                        transaction.formattedAmount,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      transaction.type == TransactionType.income
                                          ? BJBankColors.success
                                          : BJBankColors.onSurface,
                                ),
                      ),
                      const SizedBox(height: BJBankSpacing.xs),
                      Text(
                        transaction.description,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: BJBankColors.onSurface,
                                ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: BJBankSpacing.lg),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BJBankSpacing.md,
                          vertical: BJBankSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: BJBankColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: BJBankColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Concluída',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: BJBankColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: BJBankSpacing.lg),
                      const Divider(),
                      const SizedBox(height: BJBankSpacing.md),

                      // Details
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Data',
                        value: transaction.formattedDate,
                      ),
                      _buildDetailRow(
                        context,
                        icon: Icons.category_outlined,
                        label: 'Categoria',
                        value: transaction.category ?? 'Sem categoria',
                      ),
                      _buildDetailRow(
                        context,
                        icon: Icons.receipt_outlined,
                        label: 'Tipo',
                        value: _getTransactionTypeName(transaction.type),
                      ),
                      if (transaction.isEncrypted)
                        _buildDetailRow(
                          context,
                          icon: Icons.shield_outlined,
                          label: 'Segurança',
                          value: 'Criptografada (PQC)',
                          valueColor: BJBankColors.primary,
                        ),

                      const SizedBox(height: BJBankSpacing.lg),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                // Share functionality
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Partilhar'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: BJBankSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: BJBankSpacing.md),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                                // Report functionality
                              },
                              icon: const Icon(Icons.flag_outlined),
                              label: const Text('Reportar'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: BJBankSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BJBankSpacing.md),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTransactionTypeName(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Receita';
      case TransactionType.expense:
        return 'Despesa';
      case TransactionType.transfer:
        return 'Transferência';
      case TransactionType.mbway:
        return 'MB WAY';
      case TransactionType.payment:
        return 'Pagamento';
    }
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BJBankColors.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: BJBankColors.onSurfaceVariant,
            ),
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
}
