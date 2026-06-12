import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_pqc_service.dart';
import 'supabase_config.dart';
import 'trusted_server_key_service.dart';

/// Estabelecimento de canal seguro pos-quantico com o servidor BJBank.
///
/// ARQUITETURA (decisao consciente para Flutter):
///
/// O cliente Flutter NAO executa ML-KEM-768 / ML-DSA-65 localmente porque
/// nao ha implementacao Dart fiavel (a liboqs FFI nao carrega em Android).
/// Em vez disso, o cliente:
///
///   1. Bootstrap — obtem chave publica ML-DSA-65 do servidor via
///      [pqc_bootstrap] e persiste TOFU em [TrustedServerKeyService].
///   2. Handshake — gera um nonce aleatorio (32 bytes), envia ao servidor.
///      O servidor (Edge Function `pqc_handshake_flutter`) realiza:
///         a) Verifica nonce
///         b) Gera shared_secret aleatorio (32 bytes)
///         c) Assina (nonce | shared_secret_b64 | sessionId) com ML-DSA-65
///         d) Devolve { sessionId, sharedSecretBase64, signature }
///      O canal Supabase TLS protege a transmissao do segredo.
///   3. Verificacao — cliente verifica a assinatura ML-DSA-65 chamando uma
///      Edge Function dedicada `verify_dsa` (delegacao server-side da
///      verificacao, ja que nao temos ML-DSA local).
///   4. Derivacao — HKDF-SHA-256 local (PointyCastle) para derivar
///      chave AES-256 + nonceBase, usando as mesmas constantes que o
///      cliente Kotlin (`BJBank-v1|session-keys`).
///
/// NOTA ACADEMICA: a primitiva ML-KEM nao e executada client-side neste
/// caso. A confidencialidade do shared_secret depende do TLS Supabase
/// (X25519+AES-GCM) E da assinatura ML-DSA-65 (autenticacao do servidor).
/// Isto e uma decisao de implementacao Flutter, documentada como tal.
/// A app Kotlin (canonica para a tese) usa ML-KEM-768 real via BouncyCastle.
class SupabasePqcHandshakeService {
  final TrustedServerKeyService _trusted;

  SupabasePqcHandshakeService({TrustedServerKeyService? trusted})
      : _trusted = trusted ?? TrustedServerKeyService();

  SupabaseClient get _sb => SupabaseConfig.client;

  SessionKeys? _cached;
  DateTime? _cachedAt;

  /// TTL local da sessão. Server-side expira em 1h (sessions.expires_at).
  /// Aqui usamos 50 min para garantir margem — se cliente usar sessão de
  /// 59 min e servidor já a tiver invalidado, transferência falha com 410.
  /// Ver docs/PQC_ON_DEVICE_MIGRATION.md melhoria de sessão.
  static const Duration _maxAge = Duration(minutes: 50);

  /// Estabelece (ou reutiliza) uma sessao segura. Thread-safe pela natureza
  /// single-thread do Dart event loop.
  Future<SessionKeys> obterOuEstabelecer() async {
    if (_cached != null && _cachedAt != null) {
      final age = DateTime.now().difference(_cachedAt!);
      if (age < _maxAge) {
        return _cached!;
      }
      // Sessão expirou localmente — descartar e refazer handshake.
      // Listeners (SupabaseTransferService) podem limpar estado dependente
      // (e.g. serial monotónico por sessão) ao detectar sessionId novo.
      debugPrint('Sessao expirou localmente (idade=${age.inMinutes}min), refazendo handshake');
      _cached = null;
      _cachedAt = null;
    }

    // 1. Bootstrap se for a primeira vez.
    if (!await _trusted.temChavePublica()) {
      await _executarBootstrap();
    }

    // 2. Handshake.
    final response = await _executarHandshake();

    // 3. Verificar assinatura ML-DSA-65 do servidor (server-side delegado).
    await _verificarAssinatura(response);

    // 4. Derivar chaves de sessao via HKDF-SHA-256.
    final session = _derivarSessionKeys(
      ikm: response.sharedSecret,
      sessionId: response.sessionId,
    );

    _cached = session;
    _cachedAt = DateTime.now();
    return session;
  }

  Future<void> invalidar() async {
    _cached = null;
    _cachedAt = null;
  }

  // ====================================================================
  // Passo 1: Bootstrap — obter e fixar a chave publica ML-DSA do servidor
  // ====================================================================
  Future<void> _executarBootstrap() async {
    final response = await _sb.functions.invoke('pqc_bootstrap');
    final data = response.data as Map<String, dynamic>;
    final b64 = data['serverDsaPublicBase64'] as String?;
    if (b64 == null || b64.isEmpty) {
      throw HandshakeException('pqc_bootstrap nao devolveu serverDsaPublicBase64');
    }
    await _trusted.definirChavePublica(base64Decode(b64));
    debugPrint('PqcHandshake: bootstrap concluido');
  }

  // ====================================================================
  // Passo 2: Handshake — dois modos consoante a plataforma.
  //
  // MODO KEM (Android com PqcPlugin disponível) — PFS pós-quântico real:
  //   1. Cliente declara clientKemCapability=true.
  //   2. Servidor gera par ML-KEM-768 efémero, persiste a privada em
  //      pending_kem_sessions (TTL 5min), devolve serverKemPub +
  //      assinatura ML-DSA sobre transcript v2.
  //   3. Cliente verifica assinatura LOCAL e faz kemEncapsulate(serverKemPub)
  //      no plugin nativo → (ciphertext, sharedSecret).
  //   4. Cliente envia ciphertext a pqc_handshake_kem_complete.
  //   5. Servidor decapsula, persiste sessão final, APAGA pending.
  //   6. sharedSecret nunca atravessou a rede em claro — HNDL falha.
  //
  // MODO LEGACY (iOS sem plugin) — comportamento original:
  //   Servidor devolve sharedSecret no JSON via TLS. HNDL aplicável.
  // ====================================================================
  Future<_HandshakeResposta> _executarHandshake() async {
    final nonce = _bytesAleatorios(32);
    final device = DevicePqcService();
    final pfsCapaz = await device.isAvailable();

    final response = await _sb.functions.invoke(
      'pqc_handshake_flutter',
      body: {
        'clientNonceBase64': base64Encode(nonce),
        'clientKemCapability': pfsCapaz,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final mode = data['mode'] as String? ?? 'legacy';

    if (mode == 'kem') {
      return _processarRespostaKem(data, nonce, device);
    }
    return _HandshakeResposta(
      modo: 'legacy',
      sessionId: data['sessionId'] as String,
      sharedSecret: base64Decode(data['sharedSecretBase64'] as String),
      serverDsaPublic: base64Decode(data['serverDsaPublicBase64'] as String),
      signature: base64Decode(data['signatureBase64'] as String),
      clientNonce: nonce,
      serverKemPublic: null,
    );
  }

  /// Modo PFS: decapsula localmente e finaliza sessão com Edge Function
  /// `pqc_handshake_kem_complete`. O sharedSecret é calculado no dispositivo
  /// — nunca viaja em claro.
  Future<_HandshakeResposta> _processarRespostaKem(
    Map<String, dynamic> data,
    Uint8List nonce,
    DevicePqcService device,
  ) async {
    final sessionId = data['sessionId'] as String;
    final serverKemPub = base64Decode(data['serverKemPublicBase64'] as String);
    final serverDsaPub = base64Decode(data['serverDsaPublicBase64'] as String);
    final signature = base64Decode(data['signatureBase64'] as String);

    // Encapsular localmente: shared_secret só existe no dispositivo
    // e (após a próxima chamada) no servidor.
    final encap = await device.kemEncapsulate(serverKemPub);

    // Finalizar handshake: envia ciphertext ao servidor para ele decapsular.
    final completeResp = await _sb.functions.invoke(
      'pqc_handshake_kem_complete',
      body: {
        'sessionId': sessionId,
        'ciphertextBase64': base64Encode(encap.ciphertext),
      },
    );
    final completeData = completeResp.data as Map<String, dynamic>;
    if (completeData['ok'] != true) {
      throw HandshakeException(
        'pqc_handshake_kem_complete falhou: ${completeData['error'] ?? "sem detalhe"}',
      );
    }

    debugPrint('PqcHandshake: modo KEM (PFS pos-quantico) concluido');
    return _HandshakeResposta(
      modo: 'kem',
      sessionId: sessionId,
      sharedSecret: encap.sharedSecret,
      serverDsaPublic: serverDsaPub,
      signature: signature,
      clientNonce: nonce,
      serverKemPublic: serverKemPub,
    );
  }

  // ====================================================================
  // Passo 3: Verificar assinatura ML-DSA do servidor (server-side)
  // ====================================================================
  Future<void> _verificarAssinatura(_HandshakeResposta r) async {
    // Pinning: confirma que serverDsaPublic bate com o pinned.
    await _trusted.verificar(r.serverDsaPublic);

    // Transcript depende do modo:
    //   KEM:    clientNonce || serverKemPub || serverDsaPublic || sessionId
    //   LEGACY: clientNonce || sharedSecret || serverDsaPublic || sessionId
    final Uint8List transcript;
    if (r.modo == 'kem' && r.serverKemPublic != null) {
      transcript = _construirTranscript(
        clientNonce: r.clientNonce,
        material: r.serverKemPublic!,
        serverDsaPublic: r.serverDsaPublic,
        sessionId: r.sessionId,
      );
    } else {
      transcript = _construirTranscript(
        clientNonce: r.clientNonce,
        material: r.sharedSecret,
        serverDsaPublic: r.serverDsaPublic,
        sessionId: r.sessionId,
      );
    }

    // Preferência: verificação LOCAL via PqcPlugin nativo.
    // Resolve Problema 3 (verify_dsa circular) de
    // docs/PQC_REMAINING_CRITICAL_ISSUES.md.
    final device = DevicePqcService();
    if (await device.isAvailable()) {
      final ok = await device.verifyDsa(
        publicKey: r.serverDsaPublic,
        message: transcript,
        signature: r.signature,
      );
      if (!ok) {
        throw HandshakeException(
          'Assinatura ML-DSA do servidor invalida (verificacao local)',
        );
      }
      return;
    }

    // Fallback (iOS sem plugin Swift ou erro nativo): delega ao servidor.
    debugPrint('verify_dsa em fallback server-side (trust circular)');
    final result = await _sb.functions.invoke(
      'verify_dsa',
      body: {
        'publicKeyBase64': base64Encode(r.serverDsaPublic),
        'messageBase64': base64Encode(transcript),
        'signatureBase64': base64Encode(r.signature),
      },
    );
    final data = result.data as Map<String, dynamic>;
    if (data['valid'] != true) {
      throw HandshakeException(
        'Assinatura ML-DSA do servidor invalida (possivel MitM)',
      );
    }
  }

  // ====================================================================
  // Transcript canonico — bytes identicos aos produzidos pelo servidor.
  // ====================================================================
  /// [material] = sharedSecret no modo legacy ou serverKemPub no modo KEM.
  /// Em ambos os modos o servidor assina sobre este transcript canónico.
  Uint8List _construirTranscript({
    required Uint8List clientNonce,
    required Uint8List material,
    required Uint8List serverDsaPublic,
    required String sessionId,
  }) {
    final sid = utf8.encode(sessionId);
    final total = 4 * 4 +
        clientNonce.length +
        material.length +
        serverDsaPublic.length +
        sid.length;
    final buf = Uint8List(total);
    final view = ByteData.view(buf.buffer);
    var off = 0;
    off = _writeChunk(buf, view, off, clientNonce);
    off = _writeChunk(buf, view, off, material);
    off = _writeChunk(buf, view, off, serverDsaPublic);
    off = _writeChunk(buf, view, off, sid);
    return buf.sublist(0, off);
  }

  int _writeChunk(Uint8List buf, ByteData view, int off, List<int> data) {
    view.setInt32(off, data.length, Endian.big);
    off += 4;
    buf.setRange(off, off + data.length, data);
    return off + data.length;
  }

  // ====================================================================
  // Passo 4: HKDF-SHA-256 local — PointyCastle
  // ====================================================================
  SessionKeys _derivarSessionKeys({
    required Uint8List ikm,
    required String sessionId,
  }) {
    final hkdf = pc.HKDFKeyDerivator(pc.SHA256Digest());
    final salt = Uint8List.fromList(utf8.encode(sessionId));
    final info = Uint8List.fromList(utf8.encode('BJBank-v1|session-keys'));
    hkdf.init(pc.HkdfParameters(ikm, 44, salt, info));
    final out = Uint8List(44);
    hkdf.deriveKey(null, 0, out, 0);
    return SessionKeys(
      sessionId: sessionId,
      chaveCifragem: out.sublist(0, 32),
      nonceBase: out.sublist(32, 44),
    );
  }

  /// CSPRNG do SO (Random.secure). Substitui Fortuna mal semeado
  /// que misturava `microsecondsSinceEpoch | identityHashCode(this)`.
  /// Ver docs/PQC_ON_DEVICE_MIGRATION.md Fase 0.1.
  Uint8List _bytesAleatorios(int n) {
    final rng = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }
}

class SessionKeys {
  final String sessionId;
  final Uint8List chaveCifragem; // 32 bytes (AES-256)
  final Uint8List nonceBase;     // 12 bytes (base do IV GCM)

  SessionKeys({
    required this.sessionId,
    required this.chaveCifragem,
    required this.nonceBase,
  });
}

class _HandshakeResposta {
  /// 'kem' (PFS pós-quântico via ML-KEM on-device) ou 'legacy' (TLS-only).
  final String modo;
  final String sessionId;
  final Uint8List sharedSecret;
  final Uint8List serverDsaPublic;
  final Uint8List signature;
  final Uint8List clientNonce;

  /// Em modo KEM, pubkey ML-KEM-768 efémera do servidor sobre a qual o
  /// cliente fez encapsulate. É o que o servidor assinou (em vez do
  /// sharedSecret, que nunca atravessa a rede em claro).
  final Uint8List? serverKemPublic;

  _HandshakeResposta({
    required this.modo,
    required this.sessionId,
    required this.sharedSecret,
    required this.serverDsaPublic,
    required this.signature,
    required this.clientNonce,
    required this.serverKemPublic,
  });
}

class HandshakeException implements Exception {
  final String message;
  HandshakeException(this.message);
  @override
  String toString() => 'HandshakeException: $message';
}
