// firebase_core_compat.dart — stub para `package:firebase_core/firebase_core.dart`.
// Devolve no-ops. App migrou para Supabase, ver supabase_config.dart.
import 'package:flutter/foundation.dart';

class FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
  });
}

class FirebaseApp {
  final String name;
  final FirebaseOptions options;
  FirebaseApp._(this.name, this.options);
}

class Firebase {
  static final Map<String, FirebaseApp> _apps = {};

  static Future<FirebaseApp> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    debugPrint('[firebase_core_compat] initializeApp no-op (Supabase em uso)');
    final app = FirebaseApp._(
      name ?? '[DEFAULT]',
      options ??
          const FirebaseOptions(
            apiKey: 'stub',
            appId: 'stub',
            messagingSenderId: 'stub',
            projectId: 'stub',
          ),
    );
    _apps[app.name] = app;
    return app;
  }

  static FirebaseApp app([String? name]) =>
      _apps[name ?? '[DEFAULT]'] ??
      (throw StateError('Firebase nao inicializado'));

  static List<FirebaseApp> get apps => _apps.values.toList();
}
