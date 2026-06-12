package com.bjbank.ipg

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Registar plugin PQC nativo (BouncyCastle ML-DSA-65 + ML-KEM-768).
        // Resolve os 3 problemas críticos: chave privada no dispositivo,
        // PFS via KEM local, verificação ML-DSA local (sem trust circular).
        // Ver docs/PQC_REMAINING_CRITICAL_ISSUES.md.
        flutterEngine.plugins.add(PqcPlugin())
    }
}
