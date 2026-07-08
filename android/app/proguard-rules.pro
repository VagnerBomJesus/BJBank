# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core (for deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# ===========================================================================
# BouncyCastle 1.80 — ML-DSA-65, ML-KEM-768, SLH-DSA, X25519 (PqcPlugin.kt)
# ===========================================================================
-keep class org.bouncycastle.** { *; }
-keep class org.bouncycastle.pqc.** { *; }
-keep class org.bouncycastle.pqc.crypto.mldsa.** { *; }
-keep class org.bouncycastle.pqc.crypto.mlkem.** { *; }
-keep class org.bouncycastle.pqc.crypto.slhdsa.** { *; }
-keep class org.bouncycastle.crypto.agreement.X25519Agreement { *; }
-keep class org.bouncycastle.crypto.generators.X25519KeyPairGenerator { *; }
-keep class org.bouncycastle.crypto.params.X25519* { *; }
-keep class org.bouncycastle.crypto.generators.HKDFBytesGenerator { *; }
-keep class org.bouncycastle.crypto.digests.SHA256Digest { *; }
-keep class org.bouncycastle.jce.provider.BouncyCastleProvider { *; }
-dontwarn org.bouncycastle.**
-dontwarn javax.naming.**

# Plugin nativo PQC do projeto
-keep class com.bjbank.ipg.PqcPlugin { *; }
-keep class com.bjbank.ipg.MainActivity { *; }

# ===========================================================================
# AndroidX Security Crypto (EncryptedSharedPreferences usado pelo PqcPlugin)
# ===========================================================================
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Tink (transitive dependency of androidx.security.crypto)
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# ===========================================================================
# Supabase / PostgREST / Realtime (HTTP + WebSocket)
# ===========================================================================
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# OkHttp (usado por supabase_flutter)
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ===========================================================================
# PointyCastle (cifra cliente AES-GCM + HKDF + ECDH/ECDSA classic)
# ===========================================================================
-keep class org.pointycastle.** { *; }
-dontwarn org.pointycastle.**

# ===========================================================================
# Reflection — manter classes que usam reflection (BC, Tink)
# ===========================================================================
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Avoid stripping enum.values()
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
