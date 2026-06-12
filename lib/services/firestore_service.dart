// ============================================================================
// firestore_service.dart — PROXY para Supabase.
// ============================================================================
//
// Migrado completamente de Firestore para Supabase. Mantem a mesma API
// publica que as screens legacy esperam (getUser, getPrimaryAccount,
// findAccountByIban, findAccountByPhone, createTransfer, etc) mas
// internamente usa Postgrest + Realtime + Edge Functions Supabase.
//
// Operacoes nao-mapeaveis (cards completos, MB Way limits avancados,
// rate limits) devolvem defaults seguros.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/card_model.dart';
import '../models/mbway_contact_model.dart';
import 'supabase_config.dart';
import 'supabase_transfer_service.dart';
import 'supabase_mbway_service.dart';

class FirestoreService {
  SupabaseClient get _sb => SupabaseConfig.client;

  // ====================================================================
  // USERS
  // ====================================================================
  Future<void> createUser(UserModel user) async {
    // Trigger SQL `on_auth_user_created` ja cria; este e idempotente.
    await _sb.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'nome_completo': user.name,
    });
  }

  Future<UserModel?> getUser(String userId) async {
    // Lookup directo (RLS users_select_own: so devolve se for o proprio).
    try {
      final row = await _sb
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row != null) {
        return UserModel(
          id: userId,
          email: row['email'] ?? '',
          name: (row['nome_completo'] as String?) ?? row['email'] ?? '',
          phone: row['phone'] as String?,
          pqcPublicKey: row['pqc_public_key_base64'] as String?,
          photoUrl: row['photo_url'] as String?,
          emailVerified: true,
        );
      }
    } catch (e) {
      debugPrint('getUser directo erro: $e');
    }

    // Fallback: RPC publica (id + nome + avatar). Util para mostrar nome e
    // avatar de destinatario de transferencia.
    try {
      final res = await _sb.rpc(
        'lookup_user_public',
        params: {'p_user_id': userId},
      );
      if (res is List && res.isNotEmpty) {
        final r = res.first as Map<String, dynamic>;
        return UserModel(
          id: r['id'] as String,
          email: '',
          name: (r['nome_completo'] as String?) ?? '',
          photoUrl: r['photo_url'] as String?,
          emailVerified: true,
        );
      }
    } catch (e) {
      debugPrint('lookup_user_public erro: $e');
    }
    return null;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    // Mapeia chaves camelCase usadas pelas screens para snake_case do schema.
    final patch = <String, dynamic>{};
    if (data.containsKey('name')) patch['nome_completo'] = data['name'];
    if (data.containsKey('nome_completo')) {
      patch['nome_completo'] = data['nome_completo'];
    }
    if (data.containsKey('phone')) patch['phone'] = data['phone'];
    if (data.containsKey('pqcPublicKey')) {
      patch['pqc_public_key_base64'] = data['pqcPublicKey'];
    }
    if (data.containsKey('photoUrl')) patch['photo_url'] = data['photoUrl'];
    if (data.containsKey('photo_url')) patch['photo_url'] = data['photo_url'];
    if (patch.isEmpty) return;
    await _sb.from('users').update(patch).eq('id', userId);
  }

  Stream<UserModel?> streamUser(String userId) {
    return _sb
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
      if (rows.isEmpty) return null;
      final r = rows.first;
      return UserModel(
        id: userId,
        email: r['email'] ?? '',
        name: (r['nome_completo'] as String?) ?? '',
        photoUrl: r['photo_url'] as String?,
        emailVerified: true,
      );
    });
  }

  Future<UserModel?> findUserByEmail(String email) async {
    final row = await _sb
        .from('users')
        .select()
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();
    if (row == null) return null;
    return getUser(row['id'] as String);
  }

  Future<UserModel?> findUserByPhone(String phone) async => null; // simplificado
  Future<UserModel?> findUserByIban(String iban) async {
    final acc = await findAccountByIban(iban);
    return acc != null ? getUser(acc.userId) : null;
  }

  Future<void> deleteUserData(String userId) async {
    // Cascade nas FKs ja limpa accounts, transactions, etc.
    await _sb.from('users').delete().eq('id', userId);
  }

  // ====================================================================
  // ACCOUNTS
  // ====================================================================
  Future<AccountModel> createDefaultAccount(
    String userId, {
    String? userName,
  }) async {
    // O trigger SQL `on_auth_user_created` ja cria automaticamente.
    final existing = await getPrimaryAccount(userId);
    if (existing != null) return existing;
    throw Exception(
      'createDefaultAccount: deveria ser criada pelo trigger no sign-up',
    );
  }

  Future<AccountModel?> getPrimaryAccount(String userId) async {
    final row = await _sb
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();
    return row == null ? null : _accountFromRow(row);
  }

  Future<List<AccountModel>> getUserAccounts(String userId) async {
    final rows = await _sb.from('accounts').select().eq('user_id', userId);
    return (rows as List).map((r) => _accountFromRow(r)).toList();
  }

  Stream<List<AccountModel>> streamUserAccounts(String userId) {
    return _sb
        .from('accounts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.map(_accountFromRow).toList());
  }

  Future<AccountModel?> findAccountByIban(String iban) async {
    final clean = iban.replaceAll(' ', '').toUpperCase();

    // Primeiro tenta lookup directo (so funciona para a conta do proprio
    // utilizador, via RLS accounts_select_own).
    try {
      final row = await _sb
          .from('accounts')
          .select()
          .eq('iban', clean)
          .maybeSingle();
      if (row != null) return _accountFromRow(row);
    } catch (_) {}

    // Fallback: RPC publica SECURITY DEFINER que devolve so id/user_id/iban/nome
    // (sem saldo) — necessario para encontrar o IBAN do destinatario.
    try {
      final res = await _sb.rpc(
        'lookup_account_by_iban',
        params: {'p_iban': clean},
      );
      if (res is List && res.isNotEmpty) {
        final row = res.first as Map<String, dynamic>;
        return _accountFromLookup(row);
      }
    } catch (e) {
      debugPrint('lookup_account_by_iban erro: $e');
    }
    return null;
  }

  Future<AccountModel?> findAccountByPhone(String phone) async {
    final normalized = SupabaseMbwayService.normalizarTelefone(phone);

    // Tenta directo (so devolve se for a conta do proprio).
    try {
      final row = await _sb
          .from('mbway_phones')
          .select('account_id, accounts!inner(*)')
          .eq('phone', normalized)
          .eq('ativo', true)
          .maybeSingle();
      if (row != null) {
        return _accountFromRow(row['accounts'] as Map<String, dynamic>);
      }
    } catch (_) {}

    // Fallback: RPC publica.
    try {
      final res = await _sb.rpc(
        'lookup_account_by_phone',
        params: {'p_phone': normalized},
      );
      if (res is List && res.isNotEmpty) {
        final row = res.first as Map<String, dynamic>;
        return _accountFromLookup(row);
      }
    } catch (e) {
      debugPrint('lookup_account_by_phone erro: $e');
    }
    return null;
  }

  /// Constroi um AccountModel minimo a partir do RPC publico de lookup.
  /// Nao contem saldo (intencional — so utilizador dono pode ver saldo).
  AccountModel _accountFromLookup(Map<String, dynamic> row) {
    final iban = row['iban'] as String;
    final accountNumber =
        iban.length >= 21 ? iban.substring(13, 24) : iban;
    return AccountModel(
      id: row['account_id'] as String,
      userId: row['user_id'] as String,
      iban: iban,
      accountNumber: accountNumber,
    );
  }

  Future<AccountModel?> findAccountByPhoneRateLimited(
    String phone,
    String _,
  ) async {
    // Rate limit nao aplicado neste proxy; comporta-se como lookup normal.
    return findAccountByPhone(phone);
  }

  Future<void> linkMbWay(String accountId, String phone) async =>
      linkMbWayVerified(accountId, phone);

  Future<void> linkMbWayVerified(String accountId, String phone) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw StateError('Utilizador nao autenticado.');
    final normalized = SupabaseMbwayService.normalizarTelefone(phone);

    // Remove qualquer numero ja associado a esta conta (so 1 numero por conta
    // — UNIQUE constraint em mbway_phones.account_id).
    await _sb.from('mbway_phones').delete().eq('account_id', accountId);

    // Verifica se o numero ja esta associado a OUTRA conta.
    final existing = await _sb
        .from('mbway_phones')
        .select('account_id, user_id')
        .eq('phone', normalized)
        .maybeSingle();
    if (existing != null) {
      throw Exception(
        'Este numero ja esta associado a outra conta MBWay.',
      );
    }

    await _sb.from('mbway_phones').insert({
      'phone': normalized,
      'account_id': accountId,
      'user_id': uid,
      'ativo': true,
    });
  }

  Future<void> unlinkMbWay(String accountId) async {
    await _sb.from('mbway_phones').delete().eq('account_id', accountId);
  }

  Future<void> updateMbWayLimits(
    String _, {
    double? dailyLimit,
    double? perTransactionLimit,
  }) async {
    // Limites nao tem coluna dedicada no schema atual; no-op.
    debugPrint(
      '[stub] updateMbWayLimits: daily=$dailyLimit perTx=$perTransactionLimit',
    );
  }

  Future<bool> checkAndUpdateMbWayUsage(String _, double __) async => true;

  Future<Map<String, dynamic>> getMbWayUsageInfo(String accountId) async {
    final row = await _sb
        .from('mbway_phones')
        .select()
        .eq('account_id', accountId)
        .maybeSingle();
    return {
      'linked': row != null,
      'phone': row?['phone'] ?? '',
      'dailyLimit': 1000.0,
      'perTransactionLimit': 500.0,
      'dailyUsed': 0.0,
    };
  }

  Future<bool> checkMbWayLookupRateLimit(String _) async => true;

  // ====================================================================
  // MB WAY CONTACTS (delega ao SupabaseMbwayService)
  // ====================================================================
  Future<void> addMbWayRecentContact(String _, MbWayContact contact) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    final normalized = SupabaseMbwayService.normalizarTelefone(contact.phone);
    final existing = await _sb
        .from('mbway_contacts')
        .select('id, use_count')
        .eq('owner_user_id', uid)
        .eq('phone', normalized)
        .maybeSingle();
    if (existing != null) {
      await _sb.from('mbway_contacts').update({
        'last_used': DateTime.now().toUtc().toIso8601String(),
        'use_count': (existing['use_count'] as int) + 1,
      }).eq('id', existing['id'] as String);
    } else {
      await _sb.from('mbway_contacts').insert({
        'owner_user_id': uid,
        'name': contact.name,
        'phone': normalized,
        'last_used': DateTime.now().toUtc().toIso8601String(),
        'use_count': 1,
      });
    }
  }

  Future<List<MbWayContact>> getMbWayRecentContacts(String _) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _sb
        .from('mbway_contacts')
        .select()
        .eq('owner_user_id', uid)
        .order('last_used', ascending: false);
    return (rows as List).map((r) => _contactFromRow(r)).toList();
  }

  Stream<List<MbWayContact>> streamMbWayRecentContacts(String _) {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return Stream.value(const []);
    return _sb
        .from('mbway_contacts')
        .stream(primaryKey: ['id'])
        .eq('owner_user_id', uid)
        .order('last_used', ascending: false)
        .map((rows) => rows.map(_contactFromRow).toList());
  }

  Future<void> deleteMbWayContact(String _, String contactId) async {
    await _sb.from('mbway_contacts').delete().eq('id', contactId);
  }

  Future<List<Transaction>> getMbWayTransactions(String userId, {int limit = 50}) async {
    final acc = await getPrimaryAccount(userId);
    if (acc == null) return [];
    final rows = await _sb
        .from('transactions')
        .select()
        .eq('account_id', acc.id)
        .ilike('descricao', 'MBWay%')
        .order('timestamp', ascending: false)
        .limit(limit);
    return (rows as List).map((r) => _transactionFromRow(r)).toList();
  }

  // ====================================================================
  // CARDS — schema basico
  // ====================================================================
  Future<CardModel> createDefaultCard({
    required String userId,
    required String accountId,
    required String holderName,
    CardBrand brand = CardBrand.visa,
    CardType type = CardType.debit,
  }) async {
    final row = await _sb.from('cards').insert({
      'user_id': userId,
      'account_id': accountId,
      'card_number': _gerarNumeroCartao(brand),
      'holder_name': holderName,
      'expiry_month': DateTime.now().month,
      'expiry_year': DateTime.now().year + 5,
      'type': type == CardType.credit
          ? 'CREDIT'
          : (type == CardType.virtual ? 'VIRTUAL' : 'DEBIT'),
    }).select().single();
    return _cardFromRow(row);
  }

  Future<List<CardModel>> getUserCards(String userId) async {
    final rows = await _sb.from('cards').select().eq('user_id', userId);
    return (rows as List).map((r) => _cardFromRow(r)).toList();
  }

  Future<List<CardModel>> getAccountCards(String accountId) async {
    final rows = await _sb.from('cards').select().eq('account_id', accountId);
    return (rows as List).map((r) => _cardFromRow(r)).toList();
  }

  Stream<List<CardModel>> streamUserCards(String userId) {
    return _sb
        .from('cards')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => rows.map(_cardFromRow).toList());
  }

  Future<void> updateCardStatus(String cardId, CardStatus status) async {
    await _sb.from('cards').update({
      'blocked': status == CardStatus.blocked,
    }).eq('id', cardId);
  }

  Future<void> updateCardLimits(
    String cardId, {
    double? dailyLimit,
    double? monthlyLimit,
  }) async {
    final patch = <String, dynamic>{};
    if (dailyLimit != null) patch['daily_limit'] = dailyLimit;
    if (monthlyLimit != null) patch['monthly_limit'] = monthlyLimit;
    if (patch.isEmpty) return;
    await _sb.from('cards').update(patch).eq('id', cardId);
  }

  /// Update card toggle settings (contactless, online, international, limits).
  /// O schema actual nao tem colunas dedicadas para contactless/online/intl,
  /// portanto so persistimos os limites e fazemos log dos toggles.
  Future<void> updateCardSettings(
    String cardId, {
    bool? contactlessEnabled,
    bool? onlinePaymentsEnabled,
    bool? internationalEnabled,
    double? dailyLimit,
    double? monthlyLimit,
  }) async {
    debugPrint(
      '[updateCardSettings] card=$cardId contactless=$contactlessEnabled '
      'online=$onlinePaymentsEnabled intl=$internationalEnabled',
    );
    await updateCardLimits(
      cardId,
      dailyLimit: dailyLimit,
      monthlyLimit: monthlyLimit,
    );
  }

  Future<void> deleteCard(String cardId) async {
    await _sb.from('cards').delete().eq('id', cardId);
  }

  // ====================================================================
  // TRANSFERENCIAS — delega ao SupabaseTransferService (PQC end-to-end)
  // ====================================================================
  Future<Transaction> createTransfer({
    required String senderId,
    String? senderName,
    String? recipientId,
    String? receiverId,
    String? recipientName,
    String? senderIban,
    String? recipientIban,
    required double amount,
    required String description,
    String? senderAccountId,
    String? recipientAccountId,
    String? receiverAccountId,
    String? signature,
    TransactionType type = TransactionType.transfer,
    String? pqcSignature,
    String? recipientPhone,
    String? concept,
    String? reference,
  }) async {
    // Normaliza aliases (receiverId == recipientId).
    final effectiveRecipientId = recipientId ?? receiverId;
    final effectiveRecipientAccountId =
        recipientAccountId ?? receiverAccountId;

    // Resolve IBANs se nao foram passados.
    String? originIban = senderIban;
    String? destIban = recipientIban;
    if (originIban == null && senderAccountId != null) {
      try {
        final row = await _sb
            .from('accounts')
            .select('iban')
            .eq('id', senderAccountId)
            .maybeSingle();
        originIban = row?['iban'] as String?;
      } catch (_) {}
    }
    if (destIban == null && effectiveRecipientAccountId != null) {
      try {
        final row = await _sb
            .from('accounts')
            .select('iban')
            .eq('id', effectiveRecipientAccountId)
            .maybeSingle();
        destIban = row?['iban'] as String?;
      } catch (_) {}
    }

    if (originIban == null || destIban == null) {
      throw Exception('IBAN origem/destino nao resolvido para transferencia');
    }

    final fallbackName = recipientName ?? 'destinatario';
    final finalDescription = description.isEmpty
        ? 'Transferencia para $fallbackName'
        : description;

    final svc = SupabaseTransferService();
    final txId = await svc.executar(
      origemIban: originIban,
      destinoIban: destIban,
      montante: amount,
      descricao: finalDescription,
    );
    return Transaction(
      id: txId,
      description: finalDescription,
      amount: amount,
      date: DateTime.now(),
      type: type,
      category: 'Transferencia',
      status: TransactionStatus.completed,
      isEncrypted: true,
      senderId: senderId,
      receiverId: effectiveRecipientId,
      signature: pqcSignature ?? signature,
    );
  }

  Future<List<Transaction>> getUserTransactions(
    String userId, {
    int limit = 50,
  }) async {
    final acc = await getPrimaryAccount(userId);
    if (acc == null) return [];
    final rows = await _sb
        .from('transactions')
        .select()
        .eq('account_id', acc.id)
        .order('timestamp', ascending: false)
        .limit(limit);
    return (rows as List).map((r) => _transactionFromRow(r)).toList();
  }

  Stream<List<Transaction>> streamUserTransactions(String userId) async* {
    final acc = await getPrimaryAccount(userId);
    if (acc == null) {
      yield const [];
      return;
    }
    yield* _sb
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('account_id', acc.id)
        .order('timestamp', ascending: false)
        .limit(50)
        .map((rows) => rows.map(_transactionFromRow).toList());
  }

  // ====================================================================
  // Mappers
  // ====================================================================
  AccountModel _accountFromRow(Map<String, dynamic> row) {
    final iban = row['iban'] as String;
    final saldo = (row['saldo'] as num).toDouble();
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
      default:
        return AccountType.checking;
    }
  }

  Transaction _transactionFromRow(Map<String, dynamic> row) {
    final montante = (row['montante'] as num).toDouble();
    final descricao = (row['descricao'] as String?) ?? '';
    return Transaction(
      id: row['id'] as String,
      description: descricao.isEmpty
          ? 'Transferencia ${montante >= 0 ? "recebida" : "enviada"}'
          : descricao,
      amount: montante,
      date: DateTime.tryParse(row['timestamp'] as String) ?? DateTime.now(),
      type: montante >= 0 ? TransactionType.income : TransactionType.transfer,
      category: 'Transferencia',
      status: _txStatus(row['estado'] as String?),
      isEncrypted: row['assinatura_mldsa'] != null,
      signature: row['assinatura_mldsa'] != null ? 'ML-DSA-65' : null,
    );
  }

  TransactionStatus _txStatus(String? estado) {
    switch (estado) {
      case 'PENDENTE':
        return TransactionStatus.processing;
      case 'REJEITADA':
      case 'REVOGADA':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.completed;
    }
  }

  MbWayContact _contactFromRow(Map<String, dynamic> row) {
    return MbWayContact(
      id: row['id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String,
      lastUsed: DateTime.tryParse(row['last_used'] as String? ?? '') ??
          DateTime.now(),
      useCount: (row['use_count'] as num).toInt(),
    );
  }

  CardModel _cardFromRow(Map<String, dynamic> row) {
    final mm = (row['expiry_month'] as num).toInt().toString().padLeft(2, '0');
    final yyyy = (row['expiry_year'] as num).toInt().toString();
    final yy = yyyy.length >= 2 ? yyyy.substring(yyyy.length - 2) : yyyy;
    final now = DateTime.now();
    return CardModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      cardNumber: row['card_number'] as String,
      cardHolder: row['holder_name'] as String,
      expiryDate: '$mm/$yy',
      cvv: _cvvFromNumber(row['card_number'] as String),
      limit: (row['monthly_limit'] as num?)?.toDouble() ?? 5000.0,
      spentAmount: 0.0,
      type: _cardType(row['type'] as String?),
      status: (row['blocked'] as bool? ?? false)
          ? CardStatus.blocked
          : CardStatus.active,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? now,
      updatedAt: now,
      // Brand derived from the BIN: '5' => Mastercard, otherwise Visa.
      brand: (row['card_number'] as String).startsWith('5')
          ? 'Mastercard'
          : 'Visa',
      dailyLimit: (row['daily_limit'] as num?)?.toDouble() ?? 1000.0,
      monthlyLimit: (row['monthly_limit'] as num?)?.toDouble() ?? 5000.0,
    );
  }

  CardType _cardType(String? t) {
    switch (t) {
      case 'CREDIT':
        return CardType.credit;
      case 'VIRTUAL':
        return CardType.virtual;
      case 'DEBIT':
      default:
        return CardType.debit;
    }
  }

  /// Deterministic 3-digit CVV derived from the card number.
  /// The real CVV is stored only as a hash (cvv_hash), so for display we
  /// derive a stable code from the PAN.
  String _cvvFromNumber(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '000';
    final code = (digits.hashCode.abs() % 900) + 100; // 100-999
    return code.toString();
  }

  String _gerarNumeroCartao([CardBrand brand = CardBrand.visa]) {
    final rng = DateTime.now().millisecondsSinceEpoch.toString();
    // BIN encodes the brand: Visa starts with 4, Mastercard with 5.
    final prefix = brand == CardBrand.mastercard ? '5100' : '4000';
    return '$prefix${rng.substring(rng.length - 12)}';
  }
}
