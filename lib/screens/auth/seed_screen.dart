import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../services/seed_data_service.dart';

/// Seed Data Screen for BJBank
/// Dev tool to populate Firestore with demo data
class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  bool _isSeeding = false;
  bool _isClearing = false;
  String _status = '';
  List<String> _logs = [];
  SeedResult? _result;

  Future<void> _runSeed() async {
    setState(() {
      _isSeeding = true;
      _status = 'A criar dados de demonstração...';
      _logs = ['Início do seed data...'];
    });

    // Check if data already exists
    final hasData = await SeedDataService.isSeedDataPresent();
    if (hasData) {
      setState(() {
        _logs.add('Dados existentes encontrados.');
        _logs.add('A criar utilizadores (ignora duplicados)...');
      });
    }

    final result = await SeedDataService.seedAll();

    setState(() {
      _isSeeding = false;
      _result = result;
      _status = result.success ? 'Seed concluído com sucesso!' : 'Seed concluído com erros';
      _logs.add('');
      _logs.add('=== Resultado ===');
      _logs.add('Utilizadores criados: ${result.usersCreated}');
      _logs.add('Utilizadores existentes: ${result.usersSkipped}');
      _logs.add('Transações criadas: ${result.transactionsCreated}');
      if (result.errors.isNotEmpty) {
        _logs.add('');
        _logs.add('Erros:');
        for (var error in result.errors) {
          _logs.add('  - $error');
        }
      }
    });
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar dados?'),
        content: const Text(
          'Isto irá apagar TODOS os dados do Firestore (utilizadores, contas e transações). Esta ação é irreversível!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: BJBankColors.error,
            ),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isClearing = true;
      _status = 'A limpar dados...';
      _logs = ['A apagar todos os dados do Firestore...'];
    });

    await SeedDataService.clearAllData();

    setState(() {
      _isClearing = false;
      _status = 'Dados limpos com sucesso!';
      _logs.add('Todos os dados foram removidos.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BJBankColors.background,
      appBar: AppBar(
        title: const Text('Seed Data (Dev)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(BJBankSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              decoration: BoxDecoration(
                color: BJBankColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BJBankColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: BJBankColors.info),
                      const SizedBox(width: BJBankSpacing.sm),
                      Text(
                        'Dados de Demonstração',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: BJBankColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BJBankSpacing.sm),
                  const Text(
                    '• 10 utilizadores com contas bancárias\n'
                    '• 12 transações (transferências e MB WAY)\n'
                    '• Saldos variados em EUR\n'
                    '• Assinaturas PQC (simuladas)',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: BJBankSpacing.lg),

            // Demo credentials card
            Container(
              padding: const EdgeInsets.all(BJBankSpacing.md),
              decoration: BoxDecoration(
                color: BJBankColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credenciais de teste:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Email: joao.silva@bjbank.pt\n'
                    'Password: Joao123456',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: BJBankSpacing.lg),

            // Seed button
            FilledButton.icon(
              onPressed: (_isSeeding || _isClearing) ? null : _runSeed,
              icon: _isSeeding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.dataset),
              label: Text(_isSeeding ? 'A criar dados...' : 'Criar Seed Data'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: BJBankSpacing.sm),

            // Clear button
            OutlinedButton.icon(
              onPressed: (_isSeeding || _isClearing) ? null : _clearData,
              icon: _isClearing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.delete_outline, color: BJBankColors.error),
              label: Text(
                _isClearing ? 'A limpar...' : 'Limpar todos os dados',
                style: TextStyle(color: _isClearing ? null : BJBankColors.error),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: BJBankColors.error.withValues(alpha: 0.5)),
              ),
            ),

            const SizedBox(height: BJBankSpacing.lg),

            // Status
            if (_status.isNotEmpty) ...[
              Text(
                _status,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _result?.success == true
                      ? BJBankColors.success
                      : BJBankColors.onSurface,
                ),
              ),
              const SizedBox(height: BJBankSpacing.sm),
            ],

            // Log output
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(BJBankSpacing.md),
                decoration: BoxDecoration(
                  color: BJBankColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    Color textColor = Colors.green.shade300;
                    if (log.contains('Erro') || log.contains('error')) {
                      textColor = Colors.red.shade300;
                    } else if (log.contains('===')) {
                      textColor = Colors.yellow.shade300;
                    } else if (log.isEmpty) {
                      return const SizedBox(height: 8);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
