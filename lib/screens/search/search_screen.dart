import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../models/transaction_model.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Search screen (UI-kit style): search bar + live-filtered transactions.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = _controller.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Transaction> _filter(List<Transaction> all) {
    if (_query.isEmpty) return all;
    return all.where((t) {
      final desc = t.description.toLowerCase();
      final cat = (t.category ?? '').toLowerCase();
      return desc.contains(_query) || cat.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final results = _filter(accountProvider.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: BJBankColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back + title + close
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BJBankSpacing.md,
                BJBankSpacing.sm,
                BJBankSpacing.md,
                BJBankSpacing.xs,
              ),
              child: Row(
                children: [
                  _circleButton(
                    Icons.arrow_back_ios_new_rounded,
                    () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Pesquisar',
                      textAlign: TextAlign.center,
                      style: BJBankTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: BJBankColors.onSurface,
                      ),
                    ),
                  ),
                  _circleButton(
                    Icons.close_rounded,
                    () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BJBankSpacing.md,
                BJBankSpacing.sm,
                BJBankSpacing.md,
                BJBankSpacing.sm,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: BJBankTypography.bodyLarge.copyWith(
                  color: BJBankColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Pesquisar transações',
                  hintStyle: BJBankTypography.bodyLarge.copyWith(
                    color: BJBankColors.outline,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: BJBankColors.onSurfaceVariant,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: BJBankColors.onSurfaceVariant),
                          onPressed: () => _controller.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor:
                      BJBankColors.surfaceVariant.withValues(alpha: 0.5),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: BJBankColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            // Results
            Expanded(
              child: results.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BJBankSpacing.md,
                        vertical: BJBankSpacing.xs,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 46 + BJBankSpacing.md,
                        color: BJBankColors.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, i) => _row(results[i]),
                    ),
            ),
          ],
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

  Widget _row(Transaction t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: t.iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(t.icon, size: 20, color: t.iconColor),
          ),
          const SizedBox(width: BJBankSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BJBankTypography.bodyMedium.copyWith(
                    color: BJBankColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.category ?? t.formattedDate,
                  style: BJBankTypography.bodySmall.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            t.formattedAmount,
            style: BJBankTypography.valueSmall.copyWith(
              color: t.amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: BJBankColors.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: BJBankSpacing.md),
          Text(
            _query.isEmpty
                ? 'Escreve para pesquisar transações'
                : 'Sem resultados para "$_query"',
            textAlign: TextAlign.center,
            style: BJBankTypography.bodyMedium.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
