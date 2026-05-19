import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart' as tx;
import '../services/supabase_account_service.dart';
import '../services/supabase_config.dart';
import '../services/supabase_transfer_service.dart';

/// Provider de transferencias migrado para Supabase + PQC end-to-end.
///
/// A `executar` chama agora o pipeline criptografico real:
///   payload canonico → assinatura ML-DSA-65 (via Edge Function)
///   → cifra AES-256-GCM local → Edge Function executar_transferencia.
class TransferProvider extends ChangeNotifier {
  final SupabaseTransferService _transfers = SupabaseTransferService();
  final SupabaseAccountService _accounts = SupabaseAccountService();

  List<tx.Transaction> _recentTransfers = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<tx.Transaction>>? _transfersSub;
  String? _accountIdAtual;

  List<tx.Transaction> get recentTransfers => _recentTransfers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Subscreve movimentos da primeira conta do utilizador (Realtime).
  /// `userId` recebido por compatibilidade com a API antiga (proxy provider);
  /// nao e usado porque o Supabase ja sabe qual e o utilizador autenticado.
  // ignore: avoid_positional_boolean_parameters
  void initialize([String? userId]) {
    SupabaseConfig.client.auth.currentUser; // garante client esta init
    // Carregar primeira conta para fazer stream.
    _accounts.obterContas().then((contas) {
      if (contas.isNotEmpty) {
        _accountIdAtual = contas.first.id;
        _transfersSub?.cancel();
        _transfersSub = _accounts
            .observarTransacoes(_accountIdAtual!, limite: 50)
            .listen((list) {
          _recentTransfers = list;
          notifyListeners();
        });
      }
    });
  }

  /// Executa uma transferencia com assinatura ML-DSA-65 + cifra AES-GCM.
  Future<bool> executarTransferencia({
    required String origemIban,
    required String destinoIban,
    required double amount,
    required String descricao,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final txId = await _transfers.executar(
        origemIban: origemIban,
        destinoIban: destinoIban,
        montante: amount,
        descricao: descricao,
      );
      debugPrint('Transferencia PQC concluida: $txId');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _transfersSub?.cancel();
    super.dispose();
  }
}
