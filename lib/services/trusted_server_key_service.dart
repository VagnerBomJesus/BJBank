import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pinning TOFU (Trust On First Use) da chave publica ML-DSA-65 do servidor.
///
/// Na primeira invocacao de `pqc_bootstrap`, a chave publica do servidor e
/// persistida cifrada em [FlutterSecureStorage]. Em chamadas seguintes,
/// confirma-se que a chave devolvida pelo servidor bate certo — caso
/// contrario lanca [PinningException], abortando o handshake.
///
/// Equivalente Flutter ao `TrustedServerKeyProvider.kt` da app Kotlin.
class TrustedServerKeyService {
  static const _storageKey = 'bjbank_server_ml_dsa_pub';

  final FlutterSecureStorage _storage;

  TrustedServerKeyService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Devolve a chave publica pinned ou null se ainda nao houve bootstrap.
  Future<Uint8List?> obterChavePublica() async {
    final b64 = await _storage.read(key: _storageKey);
    if (b64 == null || b64.isEmpty) return null;
    return base64Decode(b64);
  }

  Future<bool> temChavePublica() async {
    final v = await _storage.read(key: _storageKey);
    return v != null && v.isNotEmpty;
  }

  /// Persiste a chave publica (apenas usar no primeiro bootstrap ou apos
  /// rotacao deliberada).
  Future<void> definirChavePublica(Uint8List material) async {
    if (material.isEmpty) {
      throw ArgumentError('Material da chave publica nao pode estar vazio.');
    }
    await _storage.write(key: _storageKey, value: base64Encode(material));
    debugPrint('TrustedServerKeyService: pinned ${material.length} bytes');
  }

  /// Verifica que a chave recebida bate com a pinned.
  /// @throws PinningException se diferir.
  Future<void> verificar(Uint8List recebida) async {
    final pinned = await obterChavePublica();
    if (pinned == null) {
      throw PinningException(
        'Chave publica do servidor nao esta pinned. '
        'Executa bootstrap antes do handshake.',
      );
    }
    if (!_constantTimeEquals(pinned, recebida)) {
      throw PinningException(
        'Chave publica do servidor nao corresponde ao pinning. '
        'Possivel MitM ou rotacao nao autorizada.',
      );
    }
  }

  /// Remove o pinning (forca novo bootstrap no proximo handshake).
  Future<void> apagar() async {
    await _storage.delete(key: _storageKey);
  }

  /// Comparacao byte-a-byte em tempo constante para evitar timing attacks.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

class PinningException implements Exception {
  final String message;
  PinningException(this.message);
  @override
  String toString() => 'PinningException: $message';
}
