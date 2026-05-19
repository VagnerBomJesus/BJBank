import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart' as tx;
import 'supabase_config.dart';

/// Servico de contas + transacoes sobre Postgrest + Realtime.
/// Substitui o `FirestoreService` antigo.
class SupabaseAccountService {
  static final SupabaseAccountService _instance =
      SupabaseAccountService._internal();
  factory SupabaseAccountService() => _instance;
  SupabaseAccountService._internal();

  SupabaseClient get _sb => SupabaseConfig.client;

  /// Stream das contas do utilizador autenticado (Realtime via Supabase).
  /// Enriquece com info de MBWay (linked / phone) para cada conta.
  Stream<List<AccountModel>> observarContas() {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return Stream.value(const []);

    return _sb
        .from('accounts')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('nome', ascending: true)
        .asyncMap((rows) async {
      final base = rows.map(_accountFromRow).toList();
      return await _enrichWithMbWay(base);
    });
  }

  /// Stream das transacoes de uma conta (ordenadas decrescente, paginadas).
  Stream<List<tx.Transaction>> observarTransacoes(
    String accountId, {
    int limite = 50,
  }) {
    return _sb
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('account_id', accountId)
        .order('timestamp', ascending: false)
        .limit(limite)
        .map((rows) => rows.map(_transactionFromRow).toList());
  }

  /// Fetch one-shot, sem realtime (useful para refresh manual).
  Future<List<AccountModel>> obterContas() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _sb
        .from('accounts')
        .select()
        .eq('user_id', uid)
        .order('nome', ascending: true);
    final base = (rows as List).map((r) => _accountFromRow(r)).toList();
    return _enrichWithMbWay(base);
  }

  /// Faz batch lookup a `mbway_phones` para preencher `mbWayLinked` e
  /// `mbWayPhone` em cada conta. Devolve uma nova lista (imutavel).
  Future<List<AccountModel>> _enrichWithMbWay(
    List<AccountModel> accounts,
  ) async {
    if (accounts.isEmpty) return accounts;
    final ids = accounts.map((a) => a.id).toList();
    final rows = await _sb
        .from('mbway_phones')
        .select('account_id, phone, ativo')
        .inFilter('account_id', ids);
    final byAccount = <String, Map<String, dynamic>>{};
    for (final r in (rows as List)) {
      final m = r as Map<String, dynamic>;
      byAccount[m['account_id'] as String] = m;
    }
    return accounts.map((a) {
      final mb = byAccount[a.id];
      if (mb == null) return a;
      final ativo = (mb['ativo'] as bool?) ?? false;
      return a.copyWith(
        mbWayLinked: ativo,
        mbWayPhone: mb['phone'] as String?,
      );
    }).toList();
  }

  Future<List<tx.Transaction>> obterTransacoes(
    String accountId, {
    int limite = 50,
  }) async {
    final rows = await _sb
        .from('transactions')
        .select()
        .eq('account_id', accountId)
        .order('timestamp', ascending: false)
        .limit(limite);
    return (rows as List).map((r) => _transactionFromRow(r)).toList();
  }

  // ====================================================================
  // Mappers
  // ====================================================================
  AccountModel _accountFromRow(Map<String, dynamic> row) {
    final iban = row['iban'] as String;
    final saldo = (row['saldo'] as num).toDouble();
    // accountNumber = ultimos 11 digitos do IBAN PT (BBAN minus check digits).
    final accountNumber = iban.length >= 21 ? iban.substring(13, 24) : iban;
    return AccountModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      iban: iban,
      accountNumber: accountNumber,
      balance: saldo,
      availableBalance: saldo,
      currency: (row['moeda'] as String?) ?? 'EUR',
      type: _accountType(row['tipo'] as String?),
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
    );
  }

  AccountType _accountType(String? tipo) {
    switch (tipo) {
      case 'POUPANCA':
        return AccountType.savings;
      case 'CARTAO_CREDITO':
      case 'BUSINESS':
        return AccountType.business;
      case 'CORRENTE':
      default:
        return AccountType.checking;
    }
  }

  tx.Transaction _transactionFromRow(Map<String, dynamic> row) {
    final montante = (row['montante'] as num).toDouble();
    final descricao = (row['descricao'] as String?) ?? '';
    return tx.Transaction(
      id: row['id'] as String,
      description: descricao.isEmpty
          ? 'Transferencia ${montante >= 0 ? "recebida" : "enviada"}'
          : descricao,
      amount: montante,
      date: DateTime.tryParse(row['timestamp'] as String) ?? DateTime.now(),
      type: montante >= 0
          ? tx.TransactionType.income
          : tx.TransactionType.transfer,
      category: 'Transferencia',
      status: _transactionStatus(row['estado'] as String?),
      signature: row['assinatura_mldsa'] != null ? 'ML-DSA-65' : null,
      isEncrypted: true,
    );
  }

  tx.TransactionStatus _transactionStatus(String? estado) {
    switch (estado) {
      case 'PENDENTE':
        return tx.TransactionStatus.processing;
      case 'REJEITADA':
      case 'REVOGADA':
        return tx.TransactionStatus.cancelled;
      case 'CONFIRMADA':
      default:
        return tx.TransactionStatus.completed;
    }
  }
}
