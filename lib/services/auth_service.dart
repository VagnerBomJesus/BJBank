import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

/// Authentication Result
class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.success(UserModel user) => AuthResult(
        success: true,
        user: user,
      );

  factory AuthResult.failure(String message) => AuthResult(
        success: false,
        errorMessage: message,
      );
}

/// Authentication Service for BJBank
/// Handles Firebase Auth operations
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirestoreService _firestoreService = FirestoreService();

  /// Get current Firebase user
  static User? get currentUser => _auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register with email and password
  static Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Erro ao criar conta');
      }

      // Update display name
      await credential.user!.updateDisplayName(name);

      // Create user document in Firestore
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email.trim(),
        name: name,
        phone: phone,
        emailVerified: false,
        status: UserStatus.active,
      );

      await _firestoreService.createUser(userModel);

      // Create default account for user with unique IBAN and card
      await _firestoreService.createDefaultAccount(
        credential.user!.uid,
        userName: name,
      );

      // Send email verification
      await credential.user!.sendEmailVerification();

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('Register error: $e');
      return AuthResult.failure('Erro ao criar conta: $e');
    }
  }

  /// Login with email and password
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Erro ao fazer login');
      }

      // Get user data from Firestore
      final userModel = await _firestoreService.getUser(credential.user!.uid);

      if (userModel == null) {
        // User exists in Auth but not in Firestore - create document
        final newUser = UserModel(
          id: credential.user!.uid,
          email: credential.user!.email ?? email,
          name: credential.user!.displayName ?? 'Utilizador',
          emailVerified: credential.user!.emailVerified,
        );
        await _firestoreService.createUser(newUser);
        return AuthResult.success(newUser);
      }

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('Login error: $e');
      return AuthResult.failure('Erro ao fazer login: $e');
    }
  }

  /// Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Send password reset email
  static Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Erro ao enviar email: $e');
    }
  }

  /// Resend email verification
  static Future<AuthResult> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('Utilizador não autenticado');
      }
      await user.sendEmailVerification();
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult.failure('Erro ao enviar verificação: $e');
    }
  }

  /// Check if email is verified
  static Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }

  /// Update user profile
  static Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('Utilizador não autenticado');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      return AuthResult(success: true);
    } catch (e) {
      return AuthResult.failure('Erro ao atualizar perfil: $e');
    }
  }

  /// Change password
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return AuthResult.failure('Utilizador não autenticado');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Erro ao alterar senha: $e');
    }
  }

  /// Delete account
  static Future<AuthResult> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return AuthResult.failure('Utilizador não autenticado');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete Firestore data
      await _firestoreService.deleteUserData(user.uid);

      // Delete Auth account
      await user.delete();

      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Erro ao eliminar conta: $e');
    }
  }

  /// Get Portuguese error messages
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Utilizador não encontrado';
      case 'wrong-password':
        return 'Palavra-passe incorreta';
      case 'email-already-in-use':
        return 'Este email já está registado';
      case 'invalid-email':
        return 'Email inválido';
      case 'weak-password':
        return 'Palavra-passe demasiado fraca (mínimo 6 caracteres)';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'user-disabled':
        return 'Conta desativada';
      case 'too-many-requests':
        return 'Demasiadas tentativas. Tente novamente mais tarde';
      case 'network-request-failed':
        return 'Erro de ligação. Verifique a sua internet';
      case 'invalid-credential':
        return 'Credenciais inválidas';
      case 'requires-recent-login':
        return 'Por favor, faça login novamente';
      default:
        return 'Erro de autenticação: $code';
    }
  }
}
