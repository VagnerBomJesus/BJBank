import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Auth Provider for BJBank
/// Manages authentication state across the app
class AuthProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _userSubscription;

  UserModel? get user => _user;
  bool get isLoggedIn => AuthService.isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userId => AuthService.currentUserId;

  /// Initialize provider and listen to auth state changes
  void initialize() {
    AuthService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        _loadUser(firebaseUser.uid);
      } else {
        _userSubscription?.cancel();
        _user = null;
        notifyListeners();
      }
    });
  }

  /// Load user data from Firestore and listen for changes
  void _loadUser(String userId) {
    _userSubscription?.cancel();
    _userSubscription = _firestoreService.streamUser(userId).listen(
      (user) {
        _user = user;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming user: $error');
      },
    );
  }

  /// Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result.success) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );

    _isLoading = false;

    if (result.success) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await AuthService.logout();
    _userSubscription?.cancel();
    _user = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
