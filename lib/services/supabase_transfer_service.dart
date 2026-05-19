import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'supabase_pqc_handshake_service.dart';

/// Servico de transferencias com cripto pos-quantica end-to-end.
///
/// Fluxo:
///   1. [obterOuEstabelecer] handshake (cached enquanto valido)
///   2. Construir payload canonico (bytes identicos ao cliente Kotlin)
///   3. Assinar payload com ML-DSA-65 via Edge Function `flutter_sign_transfer`
///   4. Envelope = [4B payloadLen][payload][4B sigLen][signature]
///   5. Cifrar envelope com AES-256-GCM (PointyCastle local)
///      - chave: SessionKeys.chaveCifragem
///      - iv: derivado de nonceBase XOR txId
///      - AAD: sessionId UTF-8
///   6. POST para Edge Function `executar_transferencia`
///   7. Servidor decifra, verifica assinatura, chama RPC atomica
///
/// Substitui o `TransferService` antigo (Firebase Firestore direto).
class SupabaseTransferService {
  static final SupabaseTransferService _instance =
      SupabaseTransferService._internal();
  factory SupabaseTransferService() => _instance;
  SupabaseTransferService._internal();

  final SupabasePqcHandshakeService _handshake = SupabasePqcHandshakeService();
  SupabaseClient get _sb => SupabaseConfig.client;

  /// Executa transferencia segura.
  ///
  /// @return o txId (UUID) em caso de sucesso.
  /// @throws TransferException em caso de erro.
  Future<String> executar({
    required String origemIban,
    required String destinoIban,
    required double montante,
    required String descricao,
  }) async {
    if (montante <= 0) throw TransferException('Montante invalido.');
    if (origemIban.isEmpty || destinoIban.isEmpty) {
      throw TransferException('IBANs obrigatorios.');
    }

    // 1. Sessao PQC
    final session = await _handshake.obterOuEstabelecer();

    // 2. Payload canonico
    final txId = _gerarUuid();
    final nonce = _bytesAleatorios(16);
    final timestampMillis = DateTime.now().millisecondsSinceEpoch;
    final payload = _construirPayload(
      txId: txId,
      origem: origemIban,
      destino: destinoIban,
      montanteStr: montante.toStringAsFixed(2),
      descricao: descricao,
      timestampMillis: timestampMillis,
      nonce: nonce,
    );

    // 3. Assinar via Edge Function (server-managed key para Flutter)
    final assinatura = await _assinarPayload(payload);

    // 4. Envelope [len|payload|len|signature]
    final envelope = _construirEnvelope(payload, assinatura.signature);

    // 5. Cifrar AES-256-GCM
    final iv = _derivarIv(session.nonceBase, txId);
    final aad = Uint8List.fromList(utf8.encode(session.sessionId));
    final ciphertext = _aesGcmCifrar(
      key: session.chaveCifragem,
      iv: iv,
      plaintext: envelope,
      aad: aad,
    );

    // 6. POST para Edge Function executar_transferencia
    try {
      final response = await _sb.functions.invoke(
        'executar_transferencia',
        body: {
          'sessionId': session.sessionId,
          'ivBase64': base64Encode(iv),
          'envelopeBase64': base64Encode(ciphertext),
          'clientDsaPublicBase64': base64Encode(assinatura.clientDsaPublic),
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['error'] != null) {
        throw TransferException(data['error'] as String);
      }
      debugPrint('Transferencia executada: $txId');
      return txId;
    } on FunctionException catch (e) {
      throw TransferException('Edge Function erro: ${e.details}');
    }
  }

  // ====================================================================
  // Payload canonico — bytes IDENTICOS aos do cliente Kotlin
  // (ver SupabaseTransferRepository.canonical())
  // ====================================================================
  Uint8List _construirPayload({
    required String txId,
    required String origem,
    required String destino,
    required String montanteStr,
    required String descricao,
    required int timestampMillis,
    required Uint8List nonce,
  }) {
    final enc = utf8.encoder;
    final parts = [
      enc.convert(txId),
      enc.convert(origem),
      enc.convert(destino),
      enc.convert(montanteStr),
      enc.convert(descricao),
    ];
    final total = parts.fold<int>(0, (s, p) => s + 4 + p.length) +
        8 + 4 + nonce.length;
    final buf = Uint8List(total);
    final view = ByteData.view(buf.buffer);
    var off = 0;
    for (final p in parts) {
      view.setInt32(off, p.length, Endian.big);
      off += 4;
      buf.setRange(off, off + p.length, p);
      off += p.length;
    }
    view.setInt64(off, timestampMillis, Endian.big);
    off += 8;
    view.setInt32(off, nonce.length, Endian.big);
    off += 4;
    buf.setRange(off, off + nonce.length, nonce);
    return buf;
  }

  Uint8List _construirEnvelope(Uint8List payload, Uint8List signature) {
    final buf = Uint8List(4 + payload.length + 4 + signature.length);
    final view = ByteData.view(buf.buffer);
    view.setInt32(0, payload.length, Endian.big);
    buf.setRange(4, 4 + payload.length, payload);
    view.setInt32(4 + payload.length, signature.length, Endian.big);
    buf.setRange(
      4 + payload.length + 4,
      4 + payload.length + 4 + signature.length,
      signature,
    );
    return buf;
  }

  /// IV = nonceBase XOR txId UTF-8 (identico ao cliente Kotlin).
  Uint8List _derivarIv(Uint8List base, String txId) {
    final txBytes = utf8.encode(txId);
    final iv = Uint8List(12);
    for (var i = 0; i < 12; i++) {
      iv[i] = base[i] ^ txBytes[i % txBytes.length];
    }
    return iv;
  }

  // ====================================================================
  // Assinatura — delega ML-DSA-65 ao servidor (Flutter sem PQC local)
  // ====================================================================
  Future<_Assinatura> _assinarPayload(Uint8List payload) async {
    final response = await _sb.functions.invoke(
      'flutter_sign_transfer',
      body: {'payloadBase64': base64Encode(payload)},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['signatureBase64'] == null) {
      throw TransferException(
        'flutter_sign_transfer falhou: ${data['error'] ?? "sem detalhe"}',
      );
    }
    return _Assinatura(
      signature: base64Decode(data['signatureBase64'] as String),
      clientDsaPublic: base64Decode(data['clientDsaPublicBase64'] as String),
    );
  }

  // ====================================================================
  // AES-256-GCM via PointyCastle
  // ====================================================================
  Uint8List _aesGcmCifrar({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List plaintext,
    required Uint8List aad,
  }) {
    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(
        true,
        pc.AEADParameters(
          pc.KeyParameter(key),
          128, // tag bits
          iv,
          aad,
        ),
      );
    return cipher.process(plaintext);
  }

  // ====================================================================
  // Helpers
  // ====================================================================
  Uint8List _bytesAleatorios(int n) {
    final rng = pc.SecureRandom('Fortuna')..seed(pc.KeyParameter(_seed()));
    return rng.nextBytes(n);
  }

  Uint8List _seed() {
    final raw = utf8.encode(
      '${DateTime.now().microsecondsSinceEpoch}|${identityHashCode(this)}',
    );
    return Uint8List.fromList(
      pc.SHA256Digest().process(Uint8List.fromList(raw)),
    );
  }

  String _gerarUuid() {
    final r = _bytesAleatorios(16);
    // RFC 4122 v4
    r[6] = (r[6] & 0x0f) | 0x40;
    r[8] = (r[8] & 0x3f) | 0x80;
    String hex(int i) => r[i].toRadixString(16).padLeft(2, '0');
    return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
        '${hex(4)}${hex(5)}-'
        '${hex(6)}${hex(7)}-'
        '${hex(8)}${hex(9)}-'
        '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
  }
}

class _Assinatura {
  final Uint8List signature;
  final Uint8List clientDsaPublic;
  _Assinatura({required this.signature, required this.clientDsaPublic});
}

class TransferException implements Exception {
  final String message;
  TransferException(this.message);
  @override
  String toString() => 'TransferException: $message';
}
