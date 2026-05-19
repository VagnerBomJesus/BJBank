// ============================================================================
// auth_service.dart — PROXY para Supabase Auth.
// ============================================================================
//
// Este ficheiro era um wrapper sobre Firebase Auth. Apos migracao para
// Supabase, mantemos a mesma API publica (`AuthService.login`, `register`,
// `logout`, `currentUserId`, `updateProfile`, `changePassword`,
// `deleteAccount`, `sendPasswordReset`) mas internamente delegamos
// para o `SupabaseAuthService` + `SupabaseConfig.client`.
//
// Isto permite que as screens legacy continuem a funcionar sem alteracoes,
// e ao mesmo tempo todas as operacoes vao para o Supabase real.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_config.dart';

/// Resultado de operacao de autenticacao.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.success(UserModel user) =>
      AuthResult(success: true, user: user);
  factory AuthResult.failure(String message) =>
      AuthResult(success: false, errorMessage: message);
}

/// Servico de autenticacao — agora delega a Supabase Auth.
class AuthService {
  static SupabaseClient get _sb => SupabaseConfig.client;

  /// Utilizador autenticado em formato compativel (placeholder simples).
  static User? get currentUser => _sb.auth.currentUser;

  /// ID do utilizador autenticado (uid no Supabase).
  static String? get currentUserId => _sb.auth.currentUser?.id;

  /// True se ha sessao ativa.
  static bool get isLoggedIn => _sb.auth.currentUser != null;

  /// Stream de mudancas de autenticacao.
  static Stream<User?> get authStateChanges =>
      _sb.auth.onAuthStateChange.map((e) => e.session?.user);

  // ====================================================================
  // Sign-up
  // ====================================================================
  static Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _sb.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nome_completo': name,
          if (phone != null) 'phone': phone,
        },
      );
      final u = response.user;
      if (u == null) {
        return AuthResult.failure(
          'Conta criada. Confirma o email para continuar.',
        );
      }
      // Trigger SQL (`on_auth_user_created`) cria automaticamente a linha
      // em public.users + conta inicial em public.accounts com IBAN PT.
      final model = UserModel(
        id: u.id,
        email: email.trim(),
        name: name,
        phone: phone,
        emailVerified: u.emailConfirmedAt != null,
        createdAt: DateTime.tryParse(u.createdAt),
      );
      return AuthResult.success(model);
    } on AuthException catch (e) {
      return AuthResult.failure(_humanize(e.message));
    } catch (e) {
      debugPrint('register erro: $e');
      return AuthResult.failure('Erro ao criar conta: $e');
    }
  }

  // ====================================================================
  // Sign-in
  // ====================================================================
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final u = response.user;
      if (u == null) {
        return AuthResult.failure('Erro ao iniciar sessao.');
      }
      final model = UserModel(
        id: u.id,
        email: u.email ?? email,
        name: (u.userMetadata?['nome_completo'] as String?) ?? email,
        emailVerified: u.emailConfirmedAt != null,
        createdAt: DateTime.tryParse(u.createdAt),
      );
      return AuthResult.success(model);
    } on AuthException catch (e) {
      return AuthResult.failure(_humanize(e.message));
    } catch (e) {
      debugPrint('login erro: $e');
      return AuthResult.failure('Erro ao iniciar sessao: $e');
    }
  }

  // ====================================================================
  // Sign-out
  // ====================================================================
  static Future<void> logout() async {
    await _sb.auth.signOut();
  }

  // ====================================================================
  // Password reset
  // ====================================================================
  static Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _sb.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'bjbank://reset',
      );
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult.failure(_humanize(e.message));
    } catch (e) {
      return AuthResult.failure('Erro ao enviar email: $e');
    }
  }

  // ====================================================================
  // Resend email verification — Supabase nao expoe directamente; usa
  // resetPasswordForEmail como workaround / no-op.
  // ====================================================================
  static Future<AuthResult> resendEmailVerification() async {
    try {
      final u = _sb.auth.currentUser;
      if (u == null) {
        return AuthResult.failure('Utilizador nao autenticado');
      }
      // Nao ha API directa em Supabase para reenviar verificacao no Flutter
      // SDK. Em alternativa, o utilizador pode pedir reset que envia novo
      // email para confirmar.
      debugPrint('resendEmailVerification: not supported by Supabase SDK');
      return AuthResult(
        success: false,
        errorMessage: 'Nao suportado. Reinicia o registo se necessario.',
      );
    } catch (e) {
      return AuthResult.failure('Erro: $e');
    }
  }

  static Future<bool> isEmailVerified() async {
    final u = _sb.auth.currentUser;
    return u != null && u.emailConfirmedAt != null;
  }

  // ====================================================================
  // Update profile (nome / foto) — Supabase usa user_metadata
  // ====================================================================
  static Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final attrs = <String, dynamic>{};
      if (displayName != null) attrs['nome_completo'] = displayName;
      if (photoURL != null) attrs['photo_url'] = photoURL;
      if (attrs.isNotEmpty) {
        await _sb.auth.updateUser(UserAttributes(data: attrs));
      }
      // Sincroniza tambem em public.users
      final uid = _sb.auth.currentUser?.id;
      if (uid != null) {
        final patch = <String, dynamic>{};
        if (displayName != null) patch['nome_completo'] = displayName;
        if (patch.isNotEmpty) {
          await _sb.from('users').update(patch).eq('id', uid);
        }
      }
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult.failure(_humanize(e.message));
    } catch (e) {
      return AuthResult.failure('Erro ao atualizar perfil: $e');
    }
  }

  // ====================================================================
  // Change password (Supabase aceita updateUser com nova password sem
  // re-autenticar; ainda assim validamos a password actual primeiro).
  // ====================================================================
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final email = _sb.auth.currentUser?.email;
      if (email == null) {
        return AuthResult.failure('Utilizador nao autenticado');
      }
      // Re-autentica com a password actual.
      try {
        await _sb.auth.signInWithPassword(email: email, password: currentPassword);
      } on AuthException {
        return AuthResult.failure('Palavra-passe actual incorreta.');
      }
      await _sb.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult.failure(_humanize(e.message));
    } catch (e) {
      return AuthResult.failure('Erro ao alterar palavra-passe: $e');
    }
  }

  // ====================================================================
  // Delete account — Supabase Flutter SDK nao expoe deleteUser ao cliente
  // (so via service_role). Marca como "pedido eliminado" e fazemos
  // sign-out; eliminacao real deve ser feita por uma Edge Function.
  // ====================================================================
  static Future<AuthResult> deleteAccount(String password) async {
    try {
      final email = _sb.auth.currentUser?.email;
      if (email == null) {
        return AuthResult.failure('Utilizador nao autenticado');
      }
      try {
        await _sb.auth.signInWithPassword(email: email, password: password);
      } on AuthException {
        return AuthResult.failure('Palavra-passe incorreta.');
      }
      // Apaga dados do utilizador via cascade na public.users (RLS impede
      // outros utilizadores; chamada protegida pelo JWT actual).
      final uid = _sb.auth.currentUser?.id;
      if (uid != null) {
        await _sb.from('users').delete().eq('id', uid);
      }
      await _sb.auth.signOut();
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult.failure('Erro ao eliminar conta: $e');
    }
  }

  // ====================================================================
  // Humaniza mensagens de erro do Supabase para PT.
  // ====================================================================
  static String _humanize(String? raw) {
    final m = (raw ?? '').toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email ou palavra-passe incorretos.';
    }
    if (m.contains('email not confirmed')) {
      return 'Confirma o teu email antes de entrar.';
    }
    if (m.contains('user already registered')) {
      return 'Ja existe uma conta com esse email.';
    }
    if (m.contains('password should be at least')) {
      return 'Palavra-passe demasiado fraca (minimo 6 caracteres).';
    }
    if (m.contains('rate limit')) {
      return 'Demasiadas tentativas. Tente novamente mais tarde.';
    }
    return raw ?? 'Erro de autenticacao.';
  }
}
