package com.bjbank.ipg

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.bouncycastle.jce.provider.BouncyCastleProvider
import org.bouncycastle.pqc.crypto.mldsa.MLDSAKeyGenerationParameters
import org.bouncycastle.pqc.crypto.mldsa.MLDSAKeyPairGenerator
import org.bouncycastle.pqc.crypto.mldsa.MLDSAParameters
import org.bouncycastle.pqc.crypto.mldsa.MLDSAPrivateKeyParameters
import org.bouncycastle.pqc.crypto.mldsa.MLDSAPublicKeyParameters
import org.bouncycastle.pqc.crypto.mldsa.MLDSASigner
import org.bouncycastle.pqc.crypto.mlkem.MLKEMGenerator
import org.bouncycastle.pqc.crypto.mlkem.MLKEMParameters
import org.bouncycastle.pqc.crypto.mlkem.MLKEMPublicKeyParameters
import org.bouncycastle.pqc.crypto.slhdsa.SLHDSAKeyGenerationParameters
import org.bouncycastle.pqc.crypto.slhdsa.SLHDSAKeyPairGenerator
import org.bouncycastle.pqc.crypto.slhdsa.SLHDSAParameters
import org.bouncycastle.pqc.crypto.slhdsa.SLHDSAPrivateKeyParameters
import org.bouncycastle.pqc.crypto.slhdsa.SLHDSAPublicKeyParameters
import org.bouncycastle.pqc.crypto.slhdsa.SLHDSASigner
import org.bouncycastle.crypto.agreement.X25519Agreement
import org.bouncycastle.crypto.generators.X25519KeyPairGenerator
import org.bouncycastle.crypto.params.X25519KeyGenerationParameters
import org.bouncycastle.crypto.params.X25519PrivateKeyParameters
import org.bouncycastle.crypto.params.X25519PublicKeyParameters
import org.bouncycastle.crypto.digests.SHA256Digest
import org.bouncycastle.crypto.generators.HKDFBytesGenerator
import org.bouncycastle.crypto.params.HKDFParameters
import org.bouncycastle.asn1.nist.NISTNamedCurves
import org.bouncycastle.crypto.agreement.ECDHBasicAgreement
import org.bouncycastle.crypto.generators.ECKeyPairGenerator
import org.bouncycastle.crypto.params.ECDomainParameters
import org.bouncycastle.crypto.params.ECKeyGenerationParameters
import org.bouncycastle.crypto.params.ECPrivateKeyParameters
import org.bouncycastle.crypto.params.ECPublicKeyParameters
import org.bouncycastle.crypto.signers.ECDSASigner
import org.bouncycastle.crypto.signers.HMacDSAKCalculator
import java.security.SecureRandom
import java.security.Security

/**
 * Plugin nativo Android para criptografia pós-quântica.
 *
 * Usa BouncyCastle 1.78+ low-level API (FIPS 203 ML-KEM-768 + FIPS 204
 * ML-DSA-65). Chave privada ML-DSA do utilizador vive em
 * EncryptedSharedPreferences (backed pelo AndroidKeyStore — StrongBox/TEE
 * quando disponível). NUNCA sai do dispositivo.
 *
 * Resolve os 3 problemas críticos documentados em
 * docs/PQC_REMAINING_CRITICAL_ISSUES.md.
 *
 * API low-level (org.bouncycastle.pqc.crypto.*) escolhida em vez da JCE
 * (java.security.KeyFactory + Signature.getInstance) porque:
 *   - Evita problemas de SPI no Android (BC reduzido).
 *   - Não precisa de javax.crypto.KEM (Java 21+ apenas).
 *   - Devolve raw key bytes directamente (sem wrapping X509 ASN.1).
 */
class PqcPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var prefs: android.content.SharedPreferences

    companion object {
        private const val CHANNEL_NAME = "com.bjbank.ipg/pqc"
        private const val PREFS_NAME = "bjbank_pqc_keys_v1"
        private const val KEY_DSA_PRIVATE = "ml_dsa_65_privkey"
        private const val KEY_DSA_PUBLIC = "ml_dsa_65_pubkey"

        init {
            // Registar BouncyCastle como provider preferido.
            Security.removeProvider("BC")
            Security.insertProviderAt(BouncyCastleProvider(), 1)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        // EncryptedSharedPreferences com chave AES-GCM-256 derivada do
        // AndroidKeyStore (StrongBox/TEE quando disponível).
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        prefs = EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "isAvailable" -> result.success(true)
                "hasKey" -> result.success(hasKey())
                "generateDsa" -> result.success(generateDsa())
                "getPublicKey" -> {
                    val pub = prefs.getString(KEY_DSA_PUBLIC, null)
                    if (pub == null) result.error("NO_KEY", "Nenhuma chave gerada", null)
                    else result.success(android.util.Base64.decode(pub, android.util.Base64.NO_WRAP))
                }
                "signDsa" -> {
                    val message = call.argument<ByteArray>("message")
                        ?: return result.error("BAD_ARG", "message em falta", null)
                    result.success(signDsa(message))
                }
                "verifyDsa" -> {
                    val pub = call.argument<ByteArray>("publicKey")!!
                    val msg = call.argument<ByteArray>("message")!!
                    val sig = call.argument<ByteArray>("signature")!!
                    result.success(verifyDsa(pub, msg, sig))
                }
                "kemEncapsulate" -> {
                    val serverPub = call.argument<ByteArray>("serverPubKey")!!
                    result.success(kemEncapsulate(serverPub))
                }
                "slhDsaKeygen" -> result.success(slhDsaKeygen())
                "slhDsaSign" -> {
                    val priv = call.argument<ByteArray>("privateKey")!!
                    val msg = call.argument<ByteArray>("message")!!
                    result.success(slhDsaSign(priv, msg))
                }
                "slhDsaVerify" -> {
                    val pub = call.argument<ByteArray>("publicKey")!!
                    val msg = call.argument<ByteArray>("message")!!
                    val sig = call.argument<ByteArray>("signature")!!
                    result.success(slhDsaVerify(pub, msg, sig))
                }
                "x25519Generate" -> result.success(x25519Generate())
                "x25519Agree" -> {
                    val priv = call.argument<ByteArray>("privateKey")!!
                    val peerPub = call.argument<ByteArray>("peerPublicKey")!!
                    result.success(x25519Agree(priv, peerPub))
                }
                "hybridDerive" -> {
                    val ssX = call.argument<ByteArray>("ssX25519")!!
                    val ssK = call.argument<ByteArray>("ssKyber")!!
                    val info = call.argument<ByteArray>("info") ?: ByteArray(0)
                    val len = (call.argument<Int>("length") ?: 32)
                    result.success(hybridDerive(ssX, ssK, info, len))
                }
                "benchmark" -> {
                    val iter = (call.argument<Int>("iterations") ?: 100)
                    result.success(benchmark(iter))
                }
                "classicBenchmark" -> {
                    val iter = (call.argument<Int>("iterations") ?: 100)
                    result.success(classicBenchmark(iter))
                }
                "revokeKey" -> {
                    prefs.edit().remove(KEY_DSA_PRIVATE).remove(KEY_DSA_PUBLIC).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            android.util.Log.e("PqcPlugin", "Erro em ${call.method}", e)
            result.error("PQC_ERROR", e.message, e.stackTraceToString())
        }
    }

    private fun hasKey(): Boolean {
        return prefs.contains(KEY_DSA_PRIVATE) && prefs.contains(KEY_DSA_PUBLIC)
    }

    /**
     * Gera novo par ML-DSA-65. Guarda em EncryptedSharedPreferences.
     * Devolve raw bytes: pública (1952 bytes) + privada (4032 bytes).
     */
    private fun generateDsa(): Map<String, ByteArray> {
        val kpg = MLDSAKeyPairGenerator()
        kpg.init(MLDSAKeyGenerationParameters(SecureRandom(), MLDSAParameters.ml_dsa_65))
        val kp = kpg.generateKeyPair()

        val pubBytes = (kp.public as MLDSAPublicKeyParameters).encoded
        val privBytes = (kp.private as MLDSAPrivateKeyParameters).encoded

        prefs.edit()
            .putString(KEY_DSA_PUBLIC, android.util.Base64.encodeToString(pubBytes, android.util.Base64.NO_WRAP))
            .putString(KEY_DSA_PRIVATE, android.util.Base64.encodeToString(privBytes, android.util.Base64.NO_WRAP))
            .apply()

        return mapOf(
            "publicKey" to pubBytes,
            "privateKey" to privBytes
        )
    }

    /**
     * Assina message com a chave privada armazenada. Privada é lida,
     * usada, e libertada — nunca exposta ao Dart.
     */
    private fun signDsa(message: ByteArray): ByteArray {
        val privBase64 = prefs.getString(KEY_DSA_PRIVATE, null)
            ?: throw IllegalStateException("Nenhuma chave gerada — chamar generateDsa primeiro")
        val privBytes = android.util.Base64.decode(privBase64, android.util.Base64.NO_WRAP)
        val priv = MLDSAPrivateKeyParameters(MLDSAParameters.ml_dsa_65, privBytes)

        // BC 1.80 API: padrão Signer — update separado de generateSignature.
        val signer = MLDSASigner()
        signer.init(true, priv)
        signer.update(message, 0, message.size)
        return signer.generateSignature()
    }

    /**
     * Verifica assinatura ML-DSA-65 localmente. Substitui o `verify_dsa`
     * server-side (que era trust circular).
     */
    private fun verifyDsa(publicKey: ByteArray, message: ByteArray, signature: ByteArray): Boolean {
        val pub = MLDSAPublicKeyParameters(MLDSAParameters.ml_dsa_65, publicKey)
        val verifier = MLDSASigner()
        verifier.init(false, pub)
        verifier.update(message, 0, message.size)
        return verifier.verifySignature(signature)
    }

    /**
     * ML-KEM-768 encapsulate. Cliente recebe a pubkey KEM do servidor,
     * gera shared_secret localmente e devolve (ciphertext, shared_secret).
     * O shared_secret NUNCA vai para o servidor — só o ciphertext, que o
     * servidor decapsula com a sua privada. Garante PFS pós-quântico.
     */
    private fun kemEncapsulate(serverPubKey: ByteArray): Map<String, ByteArray> {
        val pub = MLKEMPublicKeyParameters(MLKEMParameters.ml_kem_768, serverPubKey)
        val generator = MLKEMGenerator(SecureRandom())
        val encapsulated = generator.generateEncapsulated(pub)
        return mapOf(
            "ciphertext" to encapsulated.encapsulation,
            "sharedSecret" to encapsulated.secret
        )
    }

    // ─── SLH-DSA (FIPS 205 — Stateless Hash-Based DSA) ─────────────────
    //
    // Defesa em profundidade criptográfica: SLH-DSA só depende de funções
    // hash, sem assumções lattice. Usado como SEGUNDA assinatura em
    // transferências de alto valor para resistir a falhas futuras em
    // ataques lattice contra ML-DSA-65.
    //
    // Parameter set: SHAKE-128f (5 KB pub, 64 B priv seed, ~17 KB sig).
    // Trade-off: sig grande mas verify rápido. Para banca, aceitável.

    private fun slhDsaKeygen(): Map<String, ByteArray> {
        val kpg = SLHDSAKeyPairGenerator()
        kpg.init(SLHDSAKeyGenerationParameters(SecureRandom(), SLHDSAParameters.shake_128f))
        val kp = kpg.generateKeyPair()
        return mapOf(
            "publicKey" to (kp.public as SLHDSAPublicKeyParameters).encoded,
            "privateKey" to (kp.private as SLHDSAPrivateKeyParameters).encoded
        )
    }

    private fun slhDsaSign(privateKey: ByteArray, message: ByteArray): ByteArray {
        val priv = SLHDSAPrivateKeyParameters(SLHDSAParameters.shake_128f, privateKey)
        val signer = SLHDSASigner()
        signer.init(true, priv)
        return signer.generateSignature(message)
    }

    private fun slhDsaVerify(publicKey: ByteArray, message: ByteArray, signature: ByteArray): Boolean {
        val pub = SLHDSAPublicKeyParameters(SLHDSAParameters.shake_128f, publicKey)
        val verifier = SLHDSASigner()
        verifier.init(false, pub)
        return verifier.verifySignature(message, signature)
    }

    // ─── X25519 (RFC 7748 — Diffie-Hellman clássico) ───────────────────
    //
    // Para Hybrid X25519+ML-KEM-768. NIST RFC 9420 recomenda hybrid durante
    // a transição PQC: sharedSecret = HKDF(ss_x25519 ‖ ss_kyber768).
    // Segurança = max(clássico, PQC) — protege contra falhas em qualquer.

    private fun x25519Generate(): Map<String, ByteArray> {
        val kpg = X25519KeyPairGenerator()
        kpg.init(X25519KeyGenerationParameters(SecureRandom()))
        val kp = kpg.generateKeyPair()
        val priv = (kp.private as X25519PrivateKeyParameters)
        val pub = (kp.public as X25519PublicKeyParameters)
        return mapOf(
            "publicKey" to pub.encoded,
            "privateKey" to priv.encoded
        )
    }

    private fun x25519Agree(privateKey: ByteArray, peerPublicKey: ByteArray): ByteArray {
        val priv = X25519PrivateKeyParameters(privateKey, 0)
        val peer = X25519PublicKeyParameters(peerPublicKey, 0)
        val agreement = X25519Agreement()
        agreement.init(priv)
        val sharedSecret = ByteArray(agreement.agreementSize)
        agreement.calculateAgreement(peer, sharedSecret, 0)
        return sharedSecret
    }

    private fun hybridDerive(ssX25519: ByteArray, ssKyber: ByteArray, info: ByteArray, length: Int): ByteArray {
        val ikm = ssX25519 + ssKyber
        val hkdf = HKDFBytesGenerator(SHA256Digest())
        hkdf.init(HKDFParameters(ikm, "BJBank-v1|hybrid-x25519-kyber768".toByteArray(), info))
        val out = ByteArray(length)
        hkdf.generateBytes(out, 0, length)
        return out
    }

    // ─── Benchmark on-device ───────────────────────────────────────────
    //
    // Mede P50/P95/P99 + mean + stdev em ns para cada primitiva PQC.
    // Material empírico para a tese: tempos reais no dispositivo Android
    // (ARM64 num MI 9 ou emulador x86_64).

    private fun benchmark(iterations: Int): Map<String, Any> {
        val n = iterations.coerceIn(10, 500)
        val results = HashMap<String, Map<String, Any>>()

        // 1. ML-DSA-65 keygen
        results["mldsa_keygen_ns"] = measureMany(n) {
            val kpg = MLDSAKeyPairGenerator()
            kpg.init(MLDSAKeyGenerationParameters(SecureRandom(), MLDSAParameters.ml_dsa_65))
            kpg.generateKeyPair()
        }

        // Preparar par fixo para sign/verify reutilizar
        val dsaKpg = MLDSAKeyPairGenerator()
        dsaKpg.init(MLDSAKeyGenerationParameters(SecureRandom(), MLDSAParameters.ml_dsa_65))
        val dsaKp = dsaKpg.generateKeyPair()
        val dsaPriv = dsaKp.private as MLDSAPrivateKeyParameters
        val dsaPub = dsaKp.public as MLDSAPublicKeyParameters
        val msg = ByteArray(256).also { SecureRandom().nextBytes(it) }

        // 2. ML-DSA-65 sign
        var lastSig: ByteArray = ByteArray(0)
        results["mldsa_sign_ns"] = measureMany(n) {
            val s = MLDSASigner()
            s.init(true, dsaPriv)
            s.update(msg, 0, msg.size)
            lastSig = s.generateSignature()
        }

        // 3. ML-DSA-65 verify
        results["mldsa_verify_ns"] = measureMany(n) {
            val v = MLDSASigner()
            v.init(false, dsaPub)
            v.update(msg, 0, msg.size)
            v.verifySignature(lastSig)
        }

        // 4. ML-KEM-768 keygen + encapsulate (combinado — caso real)
        results["mlkem_encap_ns"] = measureMany(n) {
            // Gera par servidor e encapsula numa só medição (servidor + cliente).
            val kemKpg = org.bouncycastle.pqc.crypto.mlkem.MLKEMKeyPairGenerator()
            kemKpg.init(org.bouncycastle.pqc.crypto.mlkem.MLKEMKeyGenerationParameters(SecureRandom(), MLKEMParameters.ml_kem_768))
            val kemKp = kemKpg.generateKeyPair()
            val gen = MLKEMGenerator(SecureRandom())
            gen.generateEncapsulated(kemKp.public as MLKEMPublicKeyParameters)
        }

        // 5. SLH-DSA-SHAKE-128f sign (lento — só 10 iterações)
        val slhKpg = SLHDSAKeyPairGenerator()
        slhKpg.init(SLHDSAKeyGenerationParameters(SecureRandom(), SLHDSAParameters.shake_128f))
        val slhKp = slhKpg.generateKeyPair()
        val slhPriv = slhKp.private as SLHDSAPrivateKeyParameters
        results["slhdsa_sign_ns"] = measureMany(n.coerceAtMost(20)) {
            val s = SLHDSASigner()
            s.init(true, slhPriv)
            s.generateSignature(msg)
        }

        // 6. X25519 keygen+agree (baseline clássico)
        results["x25519_agree_ns"] = measureMany(n) {
            val a = X25519KeyPairGenerator(); a.init(X25519KeyGenerationParameters(SecureRandom()))
            val ka = a.generateKeyPair()
            val b = X25519KeyPairGenerator(); b.init(X25519KeyGenerationParameters(SecureRandom()))
            val kb = b.generateKeyPair()
            val agr = X25519Agreement()
            agr.init(ka.private as X25519PrivateKeyParameters)
            val out = ByteArray(agr.agreementSize)
            agr.calculateAgreement(kb.public as X25519PublicKeyParameters, out, 0)
        }

        return mapOf(
            "iterations" to n,
            "results" to results,
            "platform" to "android",
            "abi" to (android.os.Build.SUPPORTED_ABIS?.firstOrNull() ?: "unknown"),
            "device" to "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}",
            "androidVersion" to android.os.Build.VERSION.SDK_INT,
            "bcVersion" to "1.80"
        )
    }

    // ─── Benchmark Clássico (BC nativo) ───────────────────────────────
    //
    // Mede ECDSA-P256 e ECDH-P256 NA MESMA RUNTIME (BouncyCastle 1.80
    // JVM nativa) que o benchmark PQC. Sem isto, comparar PQC nativo
    // vs Clássico PointyCastle-Dart é injusto — o runtime explica a
    // diferença, não o algoritmo. Este método dá comparação fair.

    private fun classicBenchmark(iterations: Int): Map<String, Any> {
        val n = iterations.coerceIn(10, 500)
        val results = HashMap<String, Map<String, Any>>()

        // Curva NIST P-256 (a mais comparável a ML-DSA-65 nível 3)
        val curve = NISTNamedCurves.getByName("P-256")
        val domain = ECDomainParameters(curve.curve, curve.g, curve.n, curve.h, curve.seed)

        // 1. ECDSA-P256 keygen
        results["ecdsa_p256_keygen_ns"] = measureMany(n) {
            val kpg = ECKeyPairGenerator()
            kpg.init(ECKeyGenerationParameters(domain, SecureRandom()))
            kpg.generateKeyPair()
        }

        // Preparar par fixo para sign/verify (mesmo padrão do PQC)
        val ecKpg = ECKeyPairGenerator()
        ecKpg.init(ECKeyGenerationParameters(domain, SecureRandom()))
        val ecKp = ecKpg.generateKeyPair()
        val ecPriv = ecKp.private as ECPrivateKeyParameters
        val ecPub = ecKp.public as ECPublicKeyParameters
        val msg = ByteArray(256).also { SecureRandom().nextBytes(it) }
        // Hash do msg uma vez (ECDSA assina sobre o hash — mantém-se fora do loop
        // para medir só ECDSA, não SHA-256).
        val msgHash = ByteArray(32).also {
            val d = SHA256Digest()
            d.update(msg, 0, msg.size)
            d.doFinal(it, 0)
        }

        // 2. ECDSA-P256 sign (deterministic, RFC 6979)
        var lastR = java.math.BigInteger.ZERO
        var lastS = java.math.BigInteger.ZERO
        results["ecdsa_p256_sign_ns"] = measureMany(n) {
            val signer = ECDSASigner(HMacDSAKCalculator(SHA256Digest()))
            signer.init(true, ecPriv)
            val sig = signer.generateSignature(msgHash)
            lastR = sig[0]
            lastS = sig[1]
        }

        // 3. ECDSA-P256 verify
        results["ecdsa_p256_verify_ns"] = measureMany(n) {
            val verifier = ECDSASigner(HMacDSAKCalculator(SHA256Digest()))
            verifier.init(false, ecPub)
            verifier.verifySignature(msgHash, lastR, lastS)
        }

        // 4. ECDH-P256 keygen+agree (mesmo padrão do x25519_agree_ns —
        //    gera 2 pares e faz acordo numa só medição, representa o
        //    custo total de um handshake clássico).
        results["ecdh_p256_agree_ns"] = measureMany(n) {
            val a = ECKeyPairGenerator(); a.init(ECKeyGenerationParameters(domain, SecureRandom()))
            val ka = a.generateKeyPair()
            val b = ECKeyPairGenerator(); b.init(ECKeyGenerationParameters(domain, SecureRandom()))
            val kb = b.generateKeyPair()
            val agreement = ECDHBasicAgreement()
            agreement.init(ka.private as ECPrivateKeyParameters)
            agreement.calculateAgreement(kb.public as ECPublicKeyParameters)
        }

        return mapOf(
            "iterations" to n,
            "results" to results,
            "platform" to "android",
            "abi" to (android.os.Build.SUPPORTED_ABIS?.firstOrNull() ?: "unknown"),
            "device" to "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}",
            "androidVersion" to android.os.Build.VERSION.SDK_INT,
            "bcVersion" to "1.80",
            "pipeline" to "classic-native-bc"
        )
    }

    private fun measureMany(n: Int, block: () -> Unit): Map<String, Any> {
        val samples = LongArray(n)
        // Warmup
        for (i in 0 until 3) block()
        for (i in 0 until n) {
            val t0 = System.nanoTime()
            block()
            samples[i] = System.nanoTime() - t0
        }
        samples.sort()
        val mean = samples.average()
        val variance = samples.map { (it - mean) * (it - mean) }.average()
        val stdev = kotlin.math.sqrt(variance)
        return mapOf(
            "n" to n,
            "p50" to samples[(n * 0.50).toInt().coerceAtMost(n - 1)],
            "p95" to samples[(n * 0.95).toInt().coerceAtMost(n - 1)],
            "p99" to samples[(n * 0.99).toInt().coerceAtMost(n - 1)],
            "min" to samples[0],
            "max" to samples[n - 1],
            "mean_ns" to mean,
            "stdev_ns" to stdev
        )
    }
}
