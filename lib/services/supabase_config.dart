import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuracao e inicializacao do cliente Supabase.
///
/// A URL e a anon key podem ser sobrepostas em build-time via:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Por defeito, usa o projeto BJBank ja deployado (jdybjrpmybkmmfdlwrzp).
class SupabaseConfig {
  /// URL do projeto Supabase BJBank.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jdybjrpmybkmmfdlwrzp.supabase.co',
  );

  /// Anon key publica (RLS protege os dados).
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkeWJqcnBteWJrbW1mZGx3cnpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5MzcyNjUsImV4cCI6MjA5NDUxMzI2NX0.'
        'LEpITNNwwx27tiyige2nosc62g3xfI1eXXLwMMH7mSg',
  );

  /// Inicializa o cliente. Idempotente.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
    debugPrint('Supabase initialized: $url');
  }

  /// Cliente partilhado.
  static SupabaseClient get client => Supabase.instance.client;
}
