import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/mbway_contact_model.dart';
import '../services/supabase_account_service.dart';
import '../services/supabase_mbway_service.dart';

/// Provider MBWay migrado para Supabase com PQC end-to-end.
class MbWayProvider extends ChangeNotifier {
  final SupabaseMbwayService _mbway = SupabaseMbwayService();
  final SupabaseAccountService _accounts = SupabaseAccountService();

  List<MbWayContact> _contacts = [];
  List<MbWayContact> _frequentContacts = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<MbWayContact>>? _contactsSub;
  String? _origemIbanCache;

  List<MbWayContact> get contacts => _contacts;
  List<MbWayContact> get frequentContacts => _frequentContacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasContacts => _contacts.isNotEmpty;

  /// `userId` mantido por compat com proxy provider em app.dart; nao usado.
  void initialize([String? userId]) {
    _contactsSub?.cancel();
    _contactsSub = _mbway.observarContactos().listen(
      (lista) {
        _contacts = lista;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Erro ao carregar contactos: $e';
        notifyListeners();
      },
    );
    _carregarFrequentes();
    _resolverOrigemIban();
  }

  Future<void> _resolverOrigemIban() async {
    final contas = await _accounts.obterContas();
    if (contas.isNotEmpty) {
      _origemIbanCache = contas.first.iban;
    }
  }

  Future<void> _carregarFrequentes() async {
    try {
      _frequentContacts = await _mbway.obterContactosFrequentes();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro frequentes: $e');
    }
  }

  Future<void> loadFrequentContacts() => _carregarFrequentes();

  /// Pagamento MBWay com cripto pos-quantica.
  Future<bool> initiateMbWayPayment({
    required String recipientPhone,
    required String recipientName,
    required double amount,
    required String description,
    String? reference,
    required String senderName,
  }) async {
    if (!SupabaseMbwayService.isValidPhoneNumber(recipientPhone)) {
      _errorMessage = 'Numero de telefone invalido';
      notifyListeners();
      return false;
    }
    if (_origemIbanCache == null) {
      await _resolverOrigemIban();
      if (_origemIbanCache == null) {
        _errorMessage = 'Nao foi possivel determinar a conta de origem.';
        notifyListeners();
        return false;
      }
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _mbway.pagar(
        origemIban: _origemIbanCache!,
        destinoPhone: recipientPhone,
        montante: amount,
        descricao: description.isEmpty ? recipientName : description,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      await _mbway.apagarContacto(contactId);
      _contacts.removeWhere((c) => c.id == contactId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro a apagar contacto: $e');
      return false;
    }
  }

  bool validatePhoneNumber(String phone) =>
      SupabaseMbwayService.isValidPhoneNumber(phone);

  String formatPhoneNumber(String phone) =>
      SupabaseMbwayService.formatPhoneNumber(phone);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshData() async {
    await _carregarFrequentes();
    await _resolverOrigemIban();
  }

  @override
  void dispose() {
    _contactsSub?.cancel();
    super.dispose();
  }
}
