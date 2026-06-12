import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/money_request_model.dart';
import 'supabase_config.dart';
import 'supabase_mbway_service.dart';

/// Serviço de "Pedir Dinheiro" (MB WAY) sobre Supabase.
///
/// Um utilizador (requester) pede dinheiro a outro (payer) pelo número MB WAY.
/// O payer recebe o pedido e pode aprovar (executa o pagamento) ou recusar.
class SupabaseMoneyRequestService {
  static final SupabaseMoneyRequestService _instance =
      SupabaseMoneyRequestService._internal();
  factory SupabaseMoneyRequestService() => _instance;
  SupabaseMoneyRequestService._internal();

  SupabaseClient get _sb => SupabaseConfig.client;

  String? get _uid => _sb.auth.currentUser?.id;

  /// Resolve o user_id associado a um número MB WAY (ou null).
  Future<String?> _userIdByPhone(String phone) async {
    final normalized = SupabaseMbwayService.normalizarTelefone(phone);
    final row = await _sb
        .from('mbway_phones')
        .select('user_id')
        .eq('phone', normalized)
        .eq('ativo', true)
        .maybeSingle();
    return row?['user_id'] as String?;
  }

  /// Número MB WAY do próprio utilizador autenticado (onde recebe o dinheiro).
  Future<String?> _myPhone() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _sb
        .from('mbway_phones')
        .select('phone')
        .eq('user_id', uid)
        .eq('ativo', true)
        .maybeSingle();
    return row?['phone'] as String?;
  }

  /// Cria um pedido de dinheiro a [payerPhone].
  /// Lança [Exception] se o utilizador não tiver MB WAY associado.
  Future<MoneyRequest> criarPedido({
    required String requesterName,
    required String payerPhone,
    required double amount,
    String? description,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Sessão inválida');

    final myPhone = await _myPhone();
    if (myPhone == null) {
      throw Exception(
          'Precisas de associar o teu número MB WAY antes de pedir dinheiro.');
    }

    final payerNormalized = SupabaseMbwayService.normalizarTelefone(payerPhone);
    final payerUserId = await _userIdByPhone(payerPhone);

    final row = await _sb
        .from('money_requests')
        .insert({
          'requester_user_id': uid,
          'requester_name': requesterName,
          'requester_phone': myPhone,
          'payer_phone': payerNormalized,
          'payer_user_id': payerUserId,
          'amount': amount,
          'description': description,
          'status': 'PENDING',
        })
        .select()
        .single();
    return MoneyRequest.fromRow(row);
  }

  /// Pedidos recebidos (sou o pagador). [apenasPendentes] filtra os pendentes.
  Future<List<MoneyRequest>> obterRecebidos({bool apenasPendentes = false}) async {
    final uid = _uid;
    if (uid == null) return [];
    var query = _sb.from('money_requests').select().eq('payer_user_id', uid);
    if (apenasPendentes) query = query.eq('status', 'PENDING');
    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((r) => MoneyRequest.fromRow(r)).toList();
  }

  /// Pedidos que eu enviei (sou o requerente).
  Future<List<MoneyRequest>> obterEnviados() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _sb
        .from('money_requests')
        .select()
        .eq('requester_user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => MoneyRequest.fromRow(r)).toList();
  }

  /// Nº de pedidos pendentes recebidos (para badge).
  Future<int> contarPendentesRecebidos() async {
    final lista = await obterRecebidos(apenasPendentes: true);
    return lista.length;
  }

  Future<void> marcarAprovado(String id) async {
    await _sb.from('money_requests').update({
      'status': 'APPROVED',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> marcarRecusado(String id) async {
    await _sb.from('money_requests').update({
      'status': 'DECLINED',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> cancelar(String id) async {
    await _sb.from('money_requests').update({
      'status': 'CANCELLED',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
