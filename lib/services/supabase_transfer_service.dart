import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_pqc_service.dart';
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

  /// Versão do protocolo wire entre cliente e Edge Function.
  /// v=2 adiciona serial monotónico ao canonical + anti-replay por sessão.
  /// Ver docs/PQC_ON_DEVICE_MIGRATION.md melhoria (c).
  static const int _protocolVersion = 2;

  /// Serial monotónico por sessão. Persistido em SharedPreferences para
  /// sobreviver a app kill — se o serial só estivesse em memória, após
  /// reinício da app o cliente reiniciaria a 1 e a próxima transferência
  /// falharia com 409 (serial <= last_serial server-side) enquanto a
  /// sessão ainda estivesse válida no servidor.
  ///
  /// Cache em memória + flush imediato para SharedPreferences.
  /// Limpeza automática em [_purgeSerialAntigos] ao iniciar.
  final Map<String, int> _serialPorSessao = {};
  static const String _prefsSerialPrefix = 'bjbank_serial_';

  Future<int> _proximoSerialAsync(String sessionId) async {
    final atual = _serialPorSessao[sessionId];
    if (atual == null) {
      // Cache miss: carregar do storage (pode existir de app kill anterior).
      final prefs = await SharedPreferences.getInstance();
      _serialPorSessao[sessionId] =
          prefs.getInt('$_prefsSerialPrefix$sessionId') ?? 0;
    }
    final novo = (_serialPorSessao[sessionId] ?? 0) + 1;
    _serialPorSessao[sessionId] = novo;
    // Persistir imediatamente (operação curta).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefsSerialPrefix$sessionId', novo);
    return novo;
  }

  /// Apaga serials de sessões antigas (chamado em app start).
  /// Mantém só os últimos 5 sessionIds — o resto é lixo.
  static Future<void> purgeSerialAntigos() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith(_prefsSerialPrefix))
        .toList();
    if (keys.length <= 5) return;
    // Ordena alfabeticamente (UUIDs random — equivale a ordem de criação aprox).
    keys.sort();
    final toRemove = keys.take(keys.length - 5);
    for (final k in toRemove) {
      await prefs.remove(k);
    }
  }

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

    // 2. Payload canonico (v=2 com serial monotónico)
    //    Strings normalizadas para garantir interop com cliente Kotlin:
    //    - IBANs: trim + uppercase + remover espaços (idêntico a
    //      lookup_account_by_iban no Postgres).
    //    - Descrição: trim + colapso de whitespace.
    //    TODO: aplicar Unicode NFC quando se adicionar
    //    `package:string_unescape` ou similar — sem isto, "café" (NFC) e
    //    "café" (NFD) ainda produzem bytes diferentes em rare cases.
    final txId = _gerarUuid();
    final nonce = _bytesAleatorios(16);
    final timestampMillis = DateTime.now().millisecondsSinceEpoch;
    final serial = await _proximoSerialAsync(session.sessionId);
    final payload = _construirPayloadV2(
      txId: txId,
      origem: _normalizarIban(origemIban),
      destino: _normalizarIban(destinoIban),
      montanteStr: montante.toStringAsFixed(2),
      descricao: _normalizarTexto(descricao),
      timestampMillis: timestampMillis,
      nonce: nonce,
      serial: serial,
    );

    // 3. Assinar via Edge Function (server-managed key para Flutter)
    final assinatura = await _assinarPayload(payload);

    // 4. Envelope [len|payload|len|signature]
    final envelope = _construirEnvelope(payload, assinatura.signature);

    // 5. Cifrar AES-256-GCM
    //    IV puramente random (12 bytes Random.secure()). Antes era
    //    `nonceBase XOR txId` — reuso de txId num retry produzia mesmo
    //    IV+key e quebrava catastroficamente o GCM. IV vai em claro no
    //    body (`ivBase64`); AES-GCM autentica-o implicitamente via tag.
    //    Ver docs/PQC_ON_DEVICE_MIGRATION.md Fase 1.
    final iv = _bytesAleatorios(12);
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
          'protocolVersion': _protocolVersion,
          'serial': serial,
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

  /// v=2: igual ao v=1 mas com serial (int64 big-endian) acrescentado no final.
  /// Idêntico ao `construirPayloadTransferenciaV2` em _shared/transcript.ts.
  Uint8List _construirPayloadV2({
    required String txId,
    required String origem,
    required String destino,
    required String montanteStr,
    required String descricao,
    required int timestampMillis,
    required Uint8List nonce,
    required int serial,
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
        8 + 4 + nonce.length + 8;
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
    off += nonce.length;
    view.setInt64(off, serial, Endian.big);
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

  // ====================================================================
  // Assinatura — preferência: ML-DSA-65 LOCAL (PqcPlugin nativo Android).
  // Fallback: Edge Function `flutter_sign_transfer` (server-managed key).
  //
  // Quando local: chave privada nunca sai do dispositivo (Keystore-backed
  // EncryptedSharedPreferences). Resolve o Problema 1 de
  // docs/PQC_REMAINING_CRITICAL_ISSUES.md — não-repúdio real.
  // ====================================================================
  Future<_Assinatura> _assinarPayload(Uint8List payload) async {
    final device = DevicePqcService();
    if (await device.isAvailable() && await device.hasKey()) {
      // Caminho preferido: assinatura local.
      final sig = await device.signDsa(payload);
      final pub = await device.getPublicKey();
      return _Assinatura(signature: sig, clientDsaPublic: pub);
    }

    // Fallback: Edge Function server-managed (legado — Vagner/Maude até
    // migrarem, e iOS até ter plugin Swift).
    debugPrint(
      'DevicePqcService indisponível (plataforma=${defaultTargetPlatform.name}) — fallback server-managed',
    );
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
  /// CSPRNG do SO (`dart:math` Random.secure → /dev/urandom no Linux,
  /// SecRandomCopyBytes no iOS, getentropy no Android). Substitui
  /// Fortuna mal semeado (microsecondsSinceEpoch | identityHashCode) que
  /// tinha entropia ridícula. Ver docs/PQC_ON_DEVICE_MIGRATION.md Fase 0.1.
  Uint8List _bytesAleatorios(int n) {
    final rng = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }

  /// Normaliza IBAN para forma canónica: sem espaços, uppercase.
  /// Idêntico ao que `lookup_account_by_iban` faz server-side.
  String _normalizarIban(String iban) =>
      iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  /// Normaliza texto livre (descrição): trim + colapsar whitespace.
  /// Garante que "  pagamento  conta " == "pagamento conta" no payload
  /// assinado, evitando assinaturas diferentes para o mesmo significado.
  String _normalizarTexto(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

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
