import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/device_pqc_onboarding_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/firestore_service.dart';

/// Provider de autenticacao migrado para Supabase.
///
/// Mantem a API publica (login, register, logout, user, isLoading, ...)
/// compativel com os ecras existentes para minimizar churn.
class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _auth = SupabaseAuthService();
  final FirestoreService _profile = FirestoreService();
  StreamSubscription<UserModel?>? _userSub;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userId => _user?.id;

  /// Subscreve mudancas de sessao (sign-in / sign-out / token refresh).
  void initialize() {
    _userSub?.cancel();
    _user = _auth.currentUser;
    if (_user != null) {
      // ignore: discarded_futures
      refreshProfile();
    }
    _userSub = _auth.currentUserStream.listen((u) {
      _user = u;
      notifyListeners();
      if (u != null) {
        // ignore: discarded_futures
        refreshProfile();
      }
    });
  }

  /// Recarrega o perfil do utilizador a partir de public.users (inclui
  /// nome, telefone, photoUrl). Necessario para mostrar avatar apos upload.
  Future<void> refreshProfile() async {
    final uid = _user?.id;
    if (uid == null) return;
    try {
      final fresh = await _profile.getUser(uid);
      if (fresh != null) {
        _user = _user?.copyWith(
          name: fresh.name.isEmpty ? _user!.name : fresh.name,
          phone: fresh.phone,
          photoUrl: fresh.photoUrl,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('refreshProfile erro: $e');
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final u = await _auth.signIn(email: email, password: password);
      _user = u;
      if (u != null) {
        // ignore: discarded_futures
        refreshProfile();
        // Auto-onboarding PQC: garante chave ML-DSA-65 local +
        // registada server-side (idempotente). Necessário para que
        // _assinarPayload use a privada nativa em vez do servidor.
        // Ver docs/PQC_REMAINING_CRITICAL_ISSUES.md.
        // ignore: discarded_futures
        _onboardPqc();
      }
      return u != null;
    } catch (e) {
      _errorMessage = _humanize(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final r = await _auth.signUp(
        email: email,
        password: password,
        nomeCompleto: name,
        phone: phone,
      );
      _user = r.user;
      if (r.precisaConfirmarEmail) {
        _errorMessage = 'Verifica o teu email para confirmar a conta.';
      }
      if (r.user != null) {
        // ignore: discarded_futures
        _onboardPqc();
      }
      return r.user != null || r.precisaConfirmarEmail;
    } catch (e) {
      _errorMessage = _humanize(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
      _errorMessage = 'Email de recuperacao enviado.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _humanize(e);
      notifyListeners();
      return false;
    }
  }

  /// Apos consumir deep link `bjbank://reset`.
  Future<bool> updatePassword(String novaPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.updatePassword(novaPassword);
      return true;
    } catch (e) {
      _errorMessage = _humanize(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    // Apagar chave PQC local (não revoga server-side — utilizador pode
    // voltar a fazer login no mesmo dispositivo e gerar par novo).
    await DevicePqcOnboardingService().clearLocal();
    _user = null;
    notifyListeners();
  }

  /// Garante par ML-DSA-65 local + pubkey registada no servidor.
  /// Chamado fire-and-forget após login/signup. Idempotente.
  Future<void> _onboardPqc() async {
    try {
      final r = await DevicePqcOnboardingService().ensureKey();
      debugPrint('PQC onboarding: ${r.status.name}${r.detail != null ? " — ${r.detail}" : ""}');
    } catch (e) {
      // Não bloqueia login. Próxima transferência cai no fallback server-managed.
      debugPrint('PQC onboarding falhou (será re-tentado): $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _humanize(Object e) {
    final s = e.toString();
    if (s.contains('Invalid login credentials')) {
      return 'Email ou palavra-passe incorretos.';
    }
    if (s.contains('Email not confirmed')) {
      return 'Confirma o teu email antes de entrar.';
    }
    if (s.contains('User already registered')) {
      return 'Ja existe uma conta com esse email.';
    }
    return s;
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
