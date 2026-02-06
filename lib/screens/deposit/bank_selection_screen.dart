import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/nordigen_models.dart';
import '../../providers/deposit_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/deposit/bank_card.dart';
import 'bank_auth_screen.dart';

/// Bank Selection Screen
/// Allows user to select a Portuguese bank to connect
class BankSelectionScreen extends StatefulWidget {
  const BankSelectionScreen({super.key});

  @override
  State<BankSelectionScreen> createState() => _BankSelectionScreenState();
}

class _BankSelectionScreenState extends State<BankSelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load available banks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepositProvider>().loadAvailableBanks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Selecionar Banco'),
        backgroundColor: BJBankColors.surface,
        foregroundColor: BJBankColors.onSurface,
        elevation: 0,
      ),
      body: Consumer<DepositProvider>(
        builder: (context, provider, _) {
          if (provider.isBanksLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: BJBankColors.primary),
                  SizedBox(height: BJBankSpacing.md),
                  Text(
                    'A carregar bancos...',
                    style: TextStyle(color: BJBankColors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(BJBankSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: BJBankColors.error,
                    ),
                    const SizedBox(height: BJBankSpacing.md),
                    Text(
                      provider.error ?? 'Erro ao carregar bancos',
                      textAlign: TextAlign.center,
                      style: BJBankTypography.bodyMedium.copyWith(
                        color: BJBankColors.error,
                      ),
                    ),
                    const SizedBox(height: BJBankSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadAvailableBanks(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredBanks = provider.searchBanks(_searchQuery);

          return Column(
            children: [
              // Demo mode banner
              if (provider.isDemoMode)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(BJBankSpacing.md),
                  padding: const EdgeInsets.all(BJBankSpacing.sm),
                  decoration: BoxDecoration(
                    color: BJBankColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.science_outlined,
                        color: BJBankColors.warningDark,
                        size: 18,
                      ),
                      const SizedBox(width: BJBankSpacing.xs),
                      Expanded(
                        child: Text(
                          'Modo Demo: Bancos simulados para pesquisa',
                          style: BJBankTypography.bodySmall.copyWith(
                            color: BJBankColors.warningDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Search bar
              Padding(
                padding: const EdgeInsets.all(BJBankSpacing.md),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar banco...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: BJBankColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // Bank list header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BJBankSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bancos Disponiveis',
                      style: BJBankTypography.titleSmall.copyWith(
                        color: BJBankColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${filteredBanks.length} bancos',
                      style: BJBankTypography.bodySmall.copyWith(
                        color: BJBankColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BJBankSpacing.sm),

              // Bank list
              Expanded(
                child: filteredBanks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: BJBankColors.outline,
                            ),
                            const SizedBox(height: BJBankSpacing.md),
                            Text(
                              'Nenhum banco encontrado',
                              style: BJBankTypography.bodyMedium.copyWith(
                                color: BJBankColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BJBankSpacing.md,
                          vertical: BJBankSpacing.sm,
                        ),
                        itemCount: filteredBanks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: BJBankSpacing.sm),
                        itemBuilder: (context, index) {
                          final bank = filteredBanks[index];
                          return BankCard(
                            institution: bank,
                            onTap: () => _onBankSelected(bank),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onBankSelected(NordigenInstitution bank) async {
    final provider = context.read<DepositProvider>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: BJBankColors.primary),
            SizedBox(width: BJBankSpacing.md),
            Text('A preparar conexao...'),
          ],
        ),
      ),
    );

    try {
      final result = await provider.startBankConnection(bank.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to bank auth WebView
      if (mounted) {
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => BankAuthScreen(
              authUrl: result.authUrl,
              requisitionId: result.requisitionId,
              bankName: bank.name,
            ),
          ),
        );

        if (success == true && mounted) {
          // Return to deposit screen with success
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar: $e'),
            backgroundColor: BJBankColors.error,
          ),
        );
      }
    }
  }
}
