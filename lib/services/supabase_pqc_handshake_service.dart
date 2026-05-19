import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Estabelece (ou reutiliza) uma sessao segura. Thread-safe pela natureza
  /// single-thread do Dart event loop.
  Future<SessionKeys> obterOuEstabelecer() async {
    if (_cached != null) return _cached!;

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
    return session;
  }

  Future<void> invalidar() async {
    _cached = null;
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
  // Passo 2: Handshake — cliente envia nonce, servidor devolve segredo
  // ====================================================================
  Future<_HandshakeResposta> _executarHandshake() async {
    // Para reutilizar a Edge Function pqc_handshake do Kotlin (que espera
    // clientKemPublicBase64), enviamos 32 bytes aleatorios. O servidor faz
    // ml_kem768.encapsulate sobre eles. O ciphertext devolvido nao tem
    // valor para o Flutter (nao temos decap), mas o shared_secret e
    // implicitamente partilhado via a chave de sessao derivada do mesmo
    // material no servidor — para isto precisamos da versao Flutter da
    // edge function. Alternativa simples: usar pqc_handshake e deixar o
    // servidor incluir o sharedSecret cifrado AES sob a public key do
    // proprio cliente. Mas para Flutter MVP, o servidor devolve o
    // sharedSecret no JSON (canal TLS Supabase) ao lado de sessionId e
    // signature. Implementacao em pqc_handshake_flutter.
    final nonce = _bytesAleatorios(32);
    final response = await _sb.functions.invoke(
      'pqc_handshake_flutter',
      body: {
        'clientNonceBase64': base64Encode(nonce),
      },
    );
    final data = response.data as Map<String, dynamic>;
    return _HandshakeResposta(
      sessionId: data['sessionId'] as String,
      sharedSecret: base64Decode(data['sharedSecretBase64'] as String),
      serverDsaPublic: base64Decode(data['serverDsaPublicBase64'] as String),
      signature: base64Decode(data['signatureBase64'] as String),
      clientNonce: nonce,
    );
  }

  // ====================================================================
  // Passo 3: Verificar assinatura ML-DSA do servidor (server-side)
  // ====================================================================
  Future<void> _verificarAssinatura(_HandshakeResposta r) async {
    // Pinning: confirma que serverDsaPublic bate com o pinned.
    await _trusted.verificar(r.serverDsaPublic);

    // Constroi transcript canonico (igual ao servidor)
    final transcript = _construirTranscript(
      clientNonce: r.clientNonce,
      sharedSecret: r.sharedSecret,
      serverDsaPublic: r.serverDsaPublic,
      sessionId: r.sessionId,
    );

    // Delega verificacao ML-DSA-65 ao servidor via Edge Function dedicada.
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
  Uint8List _construirTranscript({
    required Uint8List clientNonce,
    required Uint8List sharedSecret,
    required Uint8List serverDsaPublic,
    required String sessionId,
  }) {
    final sid = utf8.encode(sessionId);
    final total = 4 * 4 +
        clientNonce.length +
        sharedSecret.length +
        serverDsaPublic.length +
        sid.length;
    final buf = Uint8List(total);
    final view = ByteData.view(buf.buffer);
    var off = 0;
    off = _writeChunk(buf, view, off, clientNonce);
    off = _writeChunk(buf, view, off, sharedSecret);
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

  Uint8List _bytesAleatorios(int n) {
    final secure = pc.SecureRandom('Fortuna')
      ..seed(pc.KeyParameter(_seed()));
    return secure.nextBytes(n);
  }

  Uint8List _seed() {
    // Mistura DateTime + hash para seed Fortuna.
    final raw = utf8.encode(
      '${DateTime.now().microsecondsSinceEpoch}|${identityHashCode(this)}',
    );
    final d = pc.SHA256Digest();
    return Uint8List.fromList(d.process(Uint8List.fromList(raw)));
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
  final String sessionId;
  final Uint8List sharedSecret;
  final Uint8List serverDsaPublic;
  final Uint8List signature;
  final Uint8List clientNonce;

  _HandshakeResposta({
    required this.sessionId,
    required this.sharedSecret,
    required this.serverDsaPublic,
    required this.signature,
    required this.clientNonce,
  });
}

class HandshakeException implements Exception {
  final String message;
  HandshakeException(this.message);
  @override
  String toString() => 'HandshakeException: $message';
}
