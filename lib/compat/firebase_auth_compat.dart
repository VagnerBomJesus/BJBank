// firebase_auth_compat.dart — stub para `package:firebase_auth/firebase_auth.dart`.
// App usa Supabase Auth (ver SupabaseAuthService). Este shim existe para
// codigo legacy continuar a compilar; em runtime devolve null/no-op.
import 'package:flutter/foundation.dart';

class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final bool emailVerified;
  User._({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.emailVerified = false,
  });

  Future<void> updateDisplayName(String? name) async {}
  Future<void> updatePhotoURL(String? url) async {}
  Future<void> sendEmailVerification() async {}
  Future<void> reload() async {}
  Future<void> updatePassword(String newPassword) async {}
  Future<void> updateEmail(String newEmail) async {}
  Future<void> delete() async {}
  Future<UserCredential> reauthenticateWithCredential(AuthCredential _) async =>
      UserCredential._(this);
  Future<String?> getIdToken([bool forceRefresh = false]) async => null;
}

class UserCredential {
  final User? user;
  UserCredential._(this.user);
}

class AuthCredential {
  final String providerId;
  const AuthCredential._(this.providerId);
}

class EmailAuthProvider {
  static AuthCredential credential({
    required String email,
    required String password,
  }) =>
      const AuthCredential._('password');
}

class FirebaseAuthException implements Exception {
  final String code;
  final String? message;
  FirebaseAuthException({required this.code, this.message});
  @override
  String toString() => 'FirebaseAuthException($code): $message';
}

class FirebaseAuth {
  static final FirebaseAuth instance = FirebaseAuth._();
  FirebaseAuth._();

  User? get currentUser => null;
  Stream<User?> authStateChanges() => Stream<User?>.value(null);
  Stream<User?> idTokenChanges() => Stream<User?>.value(null);
  Stream<User?> userChanges() => Stream<User?>.value(null);

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('[firebase_auth_compat] sign-in no-op (usa SupabaseAuthService)');
    return UserCredential._(null);
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('[firebase_auth_compat] sign-up no-op (usa SupabaseAuthService)');
    return UserCredential._(null);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    debugPrint('[firebase_auth_compat] reset no-op (usa SupabaseAuthService)');
  }

  Future<void> signOut() async {}
  Future<void> setLanguageCode(String? code) async {}
}
