import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_config.dart';

/// Servico de autenticacao sobre Supabase GoTrue.
///
/// Substitui o `AuthService` antigo baseado em Firebase Auth.
/// Mantem API similar para minimizar churn nos providers/ecras.
class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  SupabaseClient get _sb => SupabaseConfig.client;

  /// Stream do utilizador autenticado (ou null se nao logado).
  Stream<UserModel?> get currentUserStream =>
      _sb.auth.onAuthStateChange.map((event) => _mapUser(event.session?.user));

  UserModel? get currentUser => _mapUser(_sb.auth.currentUser);

  /// Login com email + password.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _mapUser(response.user);
    } on AuthException catch (e) {
      debugPrint('Sign-in erro: ${e.message}');
      rethrow;
    }
  }

  /// Registo com email + password + metadata.
  Future<({UserModel? user, bool precisaConfirmarEmail})> signUp({
    required String email,
    required String password,
    required String nomeCompleto,
    String? phone,
  }) async {
    try {
      final metadata = <String, dynamic>{'nome_completo': nomeCompleto};
      if (phone != null && phone.trim().isNotEmpty) {
        metadata['phone'] = phone.trim();
      }
      final response = await _sb.auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata,
      );
      // Quando "Confirm email" esta ON no Supabase, user fica null ate confirmar.
      return (
        user: _mapUser(response.user),
        precisaConfirmarEmail: response.session == null,
      );
    } on AuthException catch (e) {
      debugPrint('Sign-up erro: ${e.message}');
      rethrow;
    }
  }

  /// Pede email de recuperacao de password (link aponta para bjbank://reset).
  Future<void> sendPasswordReset(String email) async {
    await _sb.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'bjbank://reset',
    );
  }

  /// Atualiza password do utilizador autenticado (consumido via deep link).
  Future<void> updatePassword(String novaPassword) async {
    if (novaPassword.length < 6) {
      throw ArgumentError('Password deve ter pelo menos 6 caracteres.');
    }
    await _sb.auth.updateUser(UserAttributes(password: novaPassword));
  }

  Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  UserModel? _mapUser(User? u) {
    if (u == null) return null;
    final nome = (u.userMetadata?['nome_completo'] as String?) ??
        u.email ??
        u.id;
    return UserModel(
      id: u.id,
      email: u.email ?? '',
      name: nome,
      emailVerified: u.emailConfirmedAt != null,
      createdAt: DateTime.tryParse(u.createdAt),
    );
  }
}
