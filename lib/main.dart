import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/deep_link_handler.dart';
import 'services/supabase_config.dart';

/// Entry point do BJBank Flutter — backend Supabase com PQC real.
///
/// Inicializacao:
///   1. Supabase — Auth + Postgrest + Realtime + Edge Functions PQC
///   2. Deep links bjbank://reset e bjbank://login
///
/// As Edge Functions ja deployadas implementam ML-KEM-768 e ML-DSA-65
/// reais via @noble/post-quantum. Firebase foi removido completamente —
/// shims locais em `lib/compat/` mantem codigo legacy a compilar mas em
/// runtime fazem no-ops.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Supabase (backend unico).
  try {
    await SupabaseConfig.initialize();
    debugPrint('Supabase initialized');
  } catch (e, st) {
    debugPrint('Supabase init failed: $e\n$st');
  }

  // Deep links.
  try {
    await DeepLinkHandler.instance.initialize();
    debugPrint('DeepLinkHandler initialized');
  } catch (e) {
    debugPrint('DeepLinkHandler init failed: $e');
  }

  runApp(const BJBankApp());
}
