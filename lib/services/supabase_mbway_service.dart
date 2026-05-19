import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mbway_contact_model.dart';
import 'supabase_config.dart';
import 'supabase_transfer_service.dart';

/// Servico MBWay sobre Supabase com PQC.
///
/// O lookup phone -> IBAN faz-se via `mbway_phones`. A transferencia
/// efectiva reutiliza [SupabaseTransferService.executar], que assina
/// com ML-DSA-65 e cifra envelope com AES-256-GCM.
class SupabaseMbwayService {
  static final SupabaseMbwayService _instance = SupabaseMbwayService._internal();
  factory SupabaseMbwayService() => _instance;
  SupabaseMbwayService._internal();

  final SupabaseTransferService _transfers = SupabaseTransferService();
  SupabaseClient get _sb => SupabaseConfig.client;

  /// Resolve telefone -> IBAN (lookup na tabela mbway_phones).
  /// @return null se o telefone nao esta registado.
  Future<String?> lookupIbanByPhone(String phone) async {
    final normalized = normalizarTelefone(phone);
    final row = await _sb
        .from('mbway_phones')
        .select('account_id, accounts!inner(iban)')
        .eq('phone', normalized)
        .eq('ativo', true)
        .maybeSingle();
    if (row == null) return null;
    final acc = row['accounts'] as Map<String, dynamic>?;
    return acc?['iban'] as String?;
  }

  /// Liga o numero de telefone do utilizador autenticado a uma conta sua.
  Future<void> registarTelefone({
    required String phone,
    required String accountId,
  }) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw StateError('Utilizador nao autenticado.');
    final normalized = normalizarTelefone(phone);
    await _sb.from('mbway_phones').upsert({
      'phone': normalized,
      'account_id': accountId,
      'user_id': uid,
      'ativo': true,
    });
  }

  Future<void> desligarTelefone(String phone) async {
    await _sb.from('mbway_phones').delete().eq('phone', normalizarTelefone(phone));
  }

  /// Pagamento MBWay com cripto pos-quantica end-to-end.
  /// @return txId em caso de sucesso.
  /// @throws Exception se o telefone destino nao tiver MBWay associado.
  Future<String> pagar({
    required String origemIban,
    required String destinoPhone,
    required double montante,
    required String descricao,
  }) async {
    final destinoIban = await lookupIbanByPhone(destinoPhone);
    if (destinoIban == null) {
      throw Exception('Numero $destinoPhone nao tem MBWay associado.');
    }
    final txId = await _transfers.executar(
      origemIban: origemIban,
      destinoIban: destinoIban,
      montante: montante,
      descricao: descricao.isEmpty ? 'MBWay para $destinoPhone' : descricao,
    );
    // Regista contacto recente.
    await _atualizarContacto(destinoPhone, fallbackNome: destinoPhone);
    return txId;
  }

  // ====================================================================
  // Contactos guardados
  // ====================================================================
  Stream<List<MbWayContact>> observarContactos() {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return Stream.value(const []);
    return _sb
        .from('mbway_contacts')
        .stream(primaryKey: ['id'])
        .eq('owner_user_id', uid)
        .order('last_used', ascending: false)
        .map((rows) => rows.map(_contactFromRow).toList());
  }

  Future<List<MbWayContact>> obterContactosFrequentes({int limite = 5}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _sb
        .from('mbway_contacts')
        .select()
        .eq('owner_user_id', uid)
        .order('use_count', ascending: false)
        .limit(limite);
    return (rows as List).map((r) => _contactFromRow(r as Map<String, dynamic>)).toList();
  }

  Future<void> apagarContacto(String contactId) async {
    await _sb.from('mbway_contacts').delete().eq('id', contactId);
  }

  Future<void> _atualizarContacto(String phone, {required String fallbackNome}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    final normalized = normalizarTelefone(phone);
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
        'name': fallbackNome,
        'phone': normalized,
        'last_used': DateTime.now().toUtc().toIso8601String(),
        'use_count': 1,
      });
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

  // ====================================================================
  // Helpers
  // ====================================================================
  static bool isValidPhoneNumber(String phone) {
    final c = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (c.startsWith('+351')) return c.length == 13;
    if (c.startsWith('00351')) return c.length == 14;
    if (c.startsWith('351')) return c.length == 12;
    return c.length == 9 && c.startsWith('9');
  }

  /// Normaliza para formato +351XXXXXXXXX (sem espacos).
  static String normalizarTelefone(String phone) {
    final c = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (c.startsWith('+351')) return c;
    if (c.startsWith('00351')) return '+${c.substring(2)}';
    if (c.startsWith('351')) return '+$c';
    if (c.length == 9 && c.startsWith('9')) return '+351$c';
    return c;
  }

  static String formatPhoneNumber(String phone) {
    final n = normalizarTelefone(phone);
    if (n.length == 13) {
      return '${n.substring(0, 4)} ${n.substring(4, 7)} '
          '${n.substring(7, 10)} ${n.substring(10)}';
    }
    return phone;
  }
}
