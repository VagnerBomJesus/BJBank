import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/deposit_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Bank Authorization Screen
/// WebView for user to authorize bank access via PSD2
///
/// Note: This screen uses a simulated WebView for demo purposes.
/// In production, use webview_flutter package with proper WebView widget.
class BankAuthScreen extends StatefulWidget {
  const BankAuthScreen({
    super.key,
    required this.authUrl,
    required this.requisitionId,
    required this.bankName,
  });

  final String authUrl;
  final String requisitionId;
  final String bankName;

  @override
  State<BankAuthScreen> createState() => _BankAuthScreenState();
}

class _BankAuthScreenState extends State<BankAuthScreen> {
  bool _isLoading = true;
  bool _isCompleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Simulate WebView loading
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: Text('Autorizar ${widget.bankName}'),
        backgroundColor: BJBankColors.surface,
        foregroundColor: BJBankColors.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: BJBankColors.primary),
                  SizedBox(height: BJBankSpacing.md),
                  Text(
                    'A carregar pagina do banco...',
                    style: TextStyle(color: BJBankColors.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
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
                _error!,
                textAlign: TextAlign.center,
                style: BJBankTypography.bodyMedium.copyWith(
                  color: BJBankColors.error,
                ),
              ),
              const SizedBox(height: BJBankSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      );
    }

    // Simulated bank authorization page
    // In production, replace with actual WebView
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BJBankSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BJBankSpacing.md),
            decoration: BoxDecoration(
              color: BJBankColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BJBankColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 48,
                  color: BJBankColors.primary,
                ),
                const SizedBox(height: BJBankSpacing.sm),
                Text(
                  widget.bankName,
                  style: BJBankTypography.titleMedium.copyWith(
                    color: BJBankColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BJBankSpacing.lg),

          // Instructions
          Text(
            'Autorizacao PSD2',
            style: BJBankTypography.titleMedium.copyWith(
              color: BJBankColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: BJBankSpacing.sm),
          Text(
            'Para conectar a sua conta bancaria, sera redirecionado para o site do seu banco onde devera:',
            style: BJBankTypography.bodyMedium.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BJBankSpacing.md),

          // Steps
          _buildStep(1, 'Fazer login com as suas credenciais'),
          _buildStep(2, 'Selecionar a(s) conta(s) a conectar'),
          _buildStep(3, 'Autorizar o acesso ao BJBank'),
          const SizedBox(height: BJBankSpacing.lg),

          // Security info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BJBankSpacing.md),
            decoration: BoxDecoration(
              color: BJBankColors.quantumLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield,
                  color: BJBankColors.quantum,
                ),
                const SizedBox(width: BJBankSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conexao Segura',
                        style: BJBankTypography.labelMedium.copyWith(
                          color: BJBankColors.quantum,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Protegida por PSD2 e criptografia PQC',
                        style: BJBankTypography.bodySmall.copyWith(
                          color: BJBankColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BJBankSpacing.lg),

          // Info about consent
          Text(
            'Informacao sobre o consentimento:',
            style: BJBankTypography.labelMedium.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BJBankSpacing.xs),
          Text(
            '- Valido por 90 dias (PSD2)\n'
            '- Acesso apenas para leitura\n'
            '- Pode revogar a qualquer momento',
            style: BJBankTypography.bodySmall.copyWith(
              color: BJBankColors.outline,
            ),
          ),
          const SizedBox(height: BJBankSpacing.xl),

          // Auth URL (demo)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BJBankSpacing.sm),
            decoration: BoxDecoration(
              color: BJBankColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'URL de autorizacao:',
                  style: BJBankTypography.labelSmall.copyWith(
                    color: BJBankColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: BJBankSpacing.xxs),
                Text(
                  widget.authUrl,
                  style: BJBankTypography.bodySmall.copyWith(
                    color: BJBankColors.primary,
                    fontFamily: BJBankTypography.fontFamilyMono,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: BJBankSpacing.xl),

          // Demo: Simulate authorization buttons
          Text(
            'Demo: Simular autorizacao',
            style: BJBankTypography.labelMedium.copyWith(
              color: BJBankColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BJBankSpacing.md),

          // Authorize button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCompleting ? null : _simulateAuthorization,
              icon: _isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: BJBankColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isCompleting ? 'A processar...' : 'Autorizar Acesso'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BJBankColors.success,
                foregroundColor: BJBankColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: BJBankSpacing.sm),

          // Reject button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCompleting
                  ? null
                  : () => Navigator.pop(context, false),
              icon: const Icon(Icons.cancel),
              label: const Text('Rejeitar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: BJBankColors.error,
                side: const BorderSide(color: BJBankColors.error),
                padding: const EdgeInsets.symmetric(vertical: BJBankSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BJBankSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: BJBankColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: BJBankTypography.labelSmall.copyWith(
                  color: BJBankColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: BJBankTypography.bodyMedium.copyWith(
                color: BJBankColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateAuthorization() async {
    setState(() => _isCompleting = true);

    try {
      final provider = context.read<DepositProvider>();

      // Complete bank connection
      final accounts = await provider.completeBankConnection(
        widget.requisitionId,
      );

      if (mounted) {
        if (accounts.isNotEmpty) {
          // Show success and return
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${accounts.length} conta(s) conectada(s) com sucesso!'),
              backgroundColor: BJBankColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _error = 'Nenhuma conta foi encontrada. Tente novamente.';
            _isCompleting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao completar conexao: $e';
          _isCompleting = false;
        });
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar conexao?'),
        content: const Text(
          'Tem a certeza que deseja cancelar a conexao bancaria?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nao'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Return to previous screen
            },
            style: TextButton.styleFrom(foregroundColor: BJBankColors.error),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
  }
}
