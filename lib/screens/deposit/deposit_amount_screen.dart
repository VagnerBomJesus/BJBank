import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/external_account_model.dart';
import '../../providers/deposit_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'deposit_confirmation_screen.dart';

/// Deposit Amount Screen
/// Allows user to enter deposit amount
class DepositAmountScreen extends StatefulWidget {
  const DepositAmountScreen({
    super.key,
    required this.externalAccountId,
  });

  final String externalAccountId;

  @override
  State<DepositAmountScreen> createState() => _DepositAmountScreenState();
}

class _DepositAmountScreenState extends State<DepositAmountScreen> {
  final _amountController = TextEditingController();
  double _amount = 0.0;
  ExternalAccountModel? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  void _loadAccount() {
    final provider = context.read<DepositProvider>();
    _selectedAccount = provider.linkedAccounts.firstWhere(
      (a) => a.id == widget.externalAccountId,
      orElse: () => provider.activeAccounts.first,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Valor do Deposito'),
        backgroundColor: BJBankColors.surface,
        foregroundColor: BJBankColors.onSurface,
        elevation: 0,
      ),
      body: _selectedAccount == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // From account
                        Text(
                          'De:',
                          style: BJBankTypography.labelMedium.copyWith(
                            color: BJBankColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: BJBankSpacing.xs),
                        _buildAccountCard(_selectedAccount!),
                        const SizedBox(height: BJBankSpacing.lg),

                        // To account (BJBank)
                        Text(
                          'Para:',
                          style: BJBankTypography.labelMedium.copyWith(
                            color: BJBankColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: BJBankSpacing.xs),
                        _buildBJBankCard(),
                        const SizedBox(height: BJBankSpacing.xl),

                        // Amount input
                        _buildAmountInput(),
                        const SizedBox(height: BJBankSpacing.md),

                        // Quick amount buttons
                        _buildQuickAmounts(),
                      ],
                    ),
                  ),
                ),

                // Continue button
                _buildContinueButton(),
              ],
            ),
    );
  }

  Widget _buildAccountCard(ExternalAccountModel account) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BJBankColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BJBankColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: account.institutionLogo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      account.institutionLogo!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance,
                        color: BJBankColors.primary,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.account_balance,
                    color: BJBankColors.primary,
                    size: 20,
                  ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.institutionName,
                  style: BJBankTypography.titleSmall.copyWith(
                    color: BJBankColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  account.maskedIban,
                  style: BJBankTypography.bodySmall.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                    fontFamily: BJBankTypography.fontFamilyMono,
                  ),
                ),
              ],
            ),
          ),
          if (account.formattedLastBalance != null)
            Text(
              account.formattedLastBalance!,
              style: BJBankTypography.valueMedium.copyWith(
                color: BJBankColors.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBJBankCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        gradient: BJBankColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BJBankColors.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: BJBankColors.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BJBank',
                  style: BJBankTypography.titleSmall.copyWith(
                    color: BJBankColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Conta a Ordem',
                  style: BJBankTypography.bodySmall.copyWith(
                    color: BJBankColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.lg,
        vertical: BJBankSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BJBankColors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'Valor a depositar',
            style: BJBankTypography.labelMedium.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '€',
                style: BJBankTypography.headlineMedium.copyWith(
                  color: BJBankColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: BJBankSpacing.xs),
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: BJBankTypography.displaySmall.copyWith(
                    color: BJBankColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFamily: BJBankTypography.fontFamilyMono,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0,00',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  onChanged: (value) {
                    final parsed = double.tryParse(
                      value.replaceAll(',', '.'),
                    );
                    setState(() {
                      _amount = parsed ?? 0.0;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    final quickAmounts = [10.0, 25.0, 50.0, 100.0, 250.0, 500.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valores rapidos',
          style: BJBankTypography.labelMedium.copyWith(
            color: BJBankColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BJBankSpacing.sm),
        Wrap(
          spacing: BJBankSpacing.sm,
          runSpacing: BJBankSpacing.sm,
          children: quickAmounts.map((amount) {
            final isSelected = _amount == amount;
            return FilterChip(
              label: Text('€${amount.toInt()}'),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _amount = amount;
                  _amountController.text = amount.toStringAsFixed(2).replaceAll('.', ',');
                });
              },
              backgroundColor: BJBankColors.surface,
              selectedColor: BJBankColors.primaryLight,
              checkmarkColor: BJBankColors.primary,
              labelStyle: BJBankTypography.labelMedium.copyWith(
                color: isSelected
                    ? BJBankColors.primary
                    : BJBankColors.onSurface,
              ),
              side: BorderSide(
                color: isSelected
                    ? BJBankColors.primary
                    : BJBankColors.outlineVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final isValid = _amount > 0;

    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid ? _onContinue : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
              backgroundColor: BJBankColors.primary,
              disabledBackgroundColor: BJBankColors.surfaceVariant,
            ),
            child: Text(
              'Continuar',
              style: BJBankTypography.labelLarge.copyWith(
                color: isValid
                    ? BJBankColors.onPrimary
                    : BJBankColors.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onContinue() {
    if (_selectedAccount == null || _amount <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositConfirmationScreen(
          externalAccount: _selectedAccount!,
          amount: _amount,
        ),
      ),
    );
  }
}
