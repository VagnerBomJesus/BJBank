import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bjbank.ipg"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.bjbank.ipg"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Resolver conflito de META-INF entre BouncyCastle (bcprov + bcutil) e
    // jspecify — todos trazem META-INF/versions/9/OSGI-INF/MANIFEST.MF
    // (apenas relevante para OSGi, não é usado no Android).
    packaging {
        resources {
            excludes += setOf(
                "META-INF/versions/9/OSGI-INF/MANIFEST.MF",
                "META-INF/versions/9/OSGI-INF/**",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // BouncyCastle 1.80 (Dezembro 2024) traz ML-DSA-65 (FIPS 204) e ML-KEM-768
    // (FIPS 203) consolidados nos packages org.bouncycastle.pqc.crypto.mldsa
    // e mlkem. Versões 1.78/1.79 podem ter o package em locais diferentes —
    // 1.80 é a primeira release onde a API low-level está estável.
    // Ver docs/PQC_REMAINING_CRITICAL_ISSUES.md.
    implementation("org.bouncycastle:bcprov-jdk18on:1.80")
    implementation("org.bouncycastle:bcutil-jdk18on:1.80")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
}

// Forçar uma só versão de BC para evitar conflitos com transitivas
configurations.all {
    resolutionStrategy {
        force("org.bouncycastle:bcprov-jdk18on:1.80")
        force("org.bouncycastle:bcutil-jdk18on:1.80")
    }
}
