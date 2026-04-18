import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/card_model.dart';
import '../../providers/card_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Card Settings Dialog
/// Comprehensive card management (block/unblock, limits, features)
class CardSettingsDialog extends StatefulWidget {
  final CardModel card;

  const CardSettingsDialog({
    required this.card,
    super.key,
  });

  @override
  State<CardSettingsDialog> createState() => _CardSettingsDialogState();
}

class _CardSettingsDialogState extends State<CardSettingsDialog> {
  late TextEditingController _dailyLimitController;
  late TextEditingController _monthlyLimitController;
  bool _contactlessEnabled = false;
  bool _onlinePaymentsEnabled = false;
  bool _internationalEnabled = false;

  @override
  void initState() {
    super.initState();
    _dailyLimitController =
        TextEditingController(text: (widget.card.dailyLimit ?? 0).toString());
    _monthlyLimitController =
        TextEditingController(text: (widget.card.monthlyLimit ?? 0).toString());
    _contactlessEnabled = widget.card.contactlessEnabled;
    _onlinePaymentsEnabled = widget.card.onlinePaymentsEnabled;
    _internationalEnabled = widget.card.internationalEnabled;
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _monthlyLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveLimits(CardProvider cardProvider) async {
    try {
      if (widget.card.id.isEmpty) {
        _showSnackbar('ID do cartão inválido', isError: true);
        return;
      }

      final dailyLimit = double.tryParse(_dailyLimitController.text);
      final monthlyLimit = double.tryParse(_monthlyLimitController.text);

      if (dailyLimit == null || monthlyLimit == null) {
        _showSnackbar('Valores inválidos', isError: true);
        return;
      }

      final success = await cardProvider.updateCardLimits(
        widget.card.id,
        dailyLimit,
        monthlyLimit,
      );

      if (mounted) {
        _showSnackbar(
          success ? 'Limites atualizados' : 'Erro ao atualizar limites',
          isError: !success,
        );
        if (success) Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Erro: ${e.toString()}', isError: true);
    }
  }

  Future<void> _toggleFeature(
    CardProvider cardProvider,
    String feature,
    bool newValue,
  ) async {
    final success = await cardProvider.toggleCardFeature(
      widget.card.id,
      feature,
    );

    if (!success && mounted) {
      _showSnackbar('Erro ao atualizar recurso', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? BJBankColors.error : BJBankColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Consumer<CardProvider>(
        builder: (context, cardProvider, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    gradient: BJBankColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Definições do Cartão',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BJBankSpacing.sm),
                      Text(
                        widget.card.maskedNumber,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Status
                      _buildStatusSection(),
                      const SizedBox(height: BJBankSpacing.lg),

                      // Limits Section
                      _buildLimitsSection(),
                      const SizedBox(height: BJBankSpacing.lg),

                      // Features Section
                      _buildFeaturesSection(cardProvider),
                      const SizedBox(height: BJBankSpacing.lg),

                      // Save Button
                      if (cardProvider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton.icon(
                          onPressed: () => _saveLimits(cardProvider),
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar Alterações'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),

                      // Danger Zone
                      const SizedBox(height: BJBankSpacing.lg),
                      _buildDangerZone(cardProvider),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection() {
    final isBlocked = widget.card.status == CardStatus.blocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado do Cartão',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: BJBankSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BJBankSpacing.md,
            vertical: BJBankSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isBlocked
                ? BJBankColors.error.withValues(alpha: 0.1)
                : BJBankColors.success.withValues(alpha: 0.1),
            border: Border.all(
              color: isBlocked ? BJBankColors.error : BJBankColors.success,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isBlocked ? Icons.lock : Icons.verified,
                color: isBlocked ? BJBankColors.error : BJBankColors.success,
                size: 20,
              ),
              const SizedBox(width: BJBankSpacing.sm),
              Text(
                isBlocked ? 'Cartão Bloqueado' : 'Cartão Ativo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color:
                      isBlocked ? BJBankColors.error : BJBankColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLimitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Limites de Transação',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: BJBankSpacing.md),
        TextField(
          controller: _dailyLimitController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Limite Diário (€)',
            prefixIcon: const Icon(Icons.euro),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: BJBankSpacing.md),
        TextField(
          controller: _monthlyLimitController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Limite Mensal (€)',
            prefixIcon: const Icon(Icons.euro),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(CardProvider cardProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funcionalidades do Cartão',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: BJBankSpacing.md),
        _buildFeatureToggle(
          'Pagamentos sem Contacto',
          'Permitir pagamentos NFC',
          _contactlessEnabled,
          (value) async {
            setState(() => _contactlessEnabled = value);
            await _toggleFeature(
              cardProvider,
              'contactlessEnabled',
              value,
            );
          },
        ),
        const Divider(),
        _buildFeatureToggle(
          'Compras Online',
          'Permitir pagamentos na Internet',
          _onlinePaymentsEnabled,
          (value) async {
            setState(() => _onlinePaymentsEnabled = value);
            await _toggleFeature(
              cardProvider,
              'onlinePaymentsEnabled',
              value,
            );
          },
        ),
        const Divider(),
        _buildFeatureToggle(
          'Transações Internacionais',
          'Permitir compras no estrangeiro',
          _internationalEnabled,
          (value) async {
            setState(() => _internationalEnabled = value);
            await _toggleFeature(
              cardProvider,
              'internationalEnabled',
              value,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
            activeThumbColor: BJBankColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(CardProvider cardProvider) {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.error.withValues(alpha: 0.05),
        border: Border.all(color: BJBankColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zona de Perigo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: BJBankColors.error,
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(cardProvider);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Cancelar Cartão'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BJBankColors.error,
              side: BorderSide(color: BJBankColors.error),
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(CardProvider cardProvider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _DeleteConfirmationDialog(
        card: widget.card,
        cardProvider: cardProvider,
        onConfirm: () {
          Navigator.pop(dialogContext);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cartão cancelado')),
          );
        },
      ),
    );
  }
}

/// Delete Confirmation Dialog
class _DeleteConfirmationDialog extends StatelessWidget {
  final CardModel card;
  final CardProvider cardProvider;
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({
    required this.card,
    required this.cardProvider,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar Cartão'),
      content: const Text(
        'Tem a certeza que deseja cancelar este cartão? Esta ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final success = await cardProvider.deleteCard(card.id);
            if (success) {
              onConfirm();
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: BJBankColors.error,
          ),
          child: const Text('Cancelar Cartão'),
        ),
      ],
    );
  }
}
