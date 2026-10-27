import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.chaquo.python")
}

val keyProps = Properties().apply {
    val f = rootProject.file("../.secrets/key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

// Set NAZZEL_STORE=1 for the Google Play build: no outside code or updates, and no sites Play does not allow.
val storeBuild = System.getenv("NAZZEL_STORE") == "1"

android {
    namespace = "app.nazzel"
    compileSdk = flutter.compileSdkVersion

    buildFeatures { buildConfig = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.nazzel"
        // MediaStore saves without storage permissions need API 29.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField("boolean", "STORE", storeBuild.toString())
        ndk { abiFilters += listOf("arm64-v8a") }
    }

    signingConfigs {
        create("release") {
            if (keyProps.isNotEmpty()) {
                storeFile = rootProject.file("../.secrets/" + keyProps["storeFile"])
                storePassword = keyProps["storePassword"] as String
                keyAlias = keyProps["keyAlias"] as String
                keyPassword = keyProps["keyPassword"] as String
            }
        }
    }

    packaging {
        // The QuickJS binary ships as libqjs.so and must be extracted to disk to be executable.
        jniLibs { useLegacyPackaging = true }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // R8 renamed ProgressCallback.onProgress, so Python could no longer find it and every download died.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

chaquopy {
    defaultConfig {
        // 3.13 is the first version with Android wheels of curl_cffi, which gives yt-dlp browser TLS impersonation.
        version = "3.13"
        buildPython(System.getenv("NAZZEL_BUILD_PYTHON") ?: "python3.13")
        pip {
            // Pinned and without dependency resolution: curl_cffi declares cffi>=2.0, but only cffi 1.17.1 has an
            // Android wheel, and the pair works together (verified with an impersonated request on a desktop build).
            options("--no-deps")
            install("yt-dlp==2026.10.21")
            install("yt-dlp-ejs==0.8.0")
            install("curl-cffi==0.16.4b1")
            install("cffi==1.17.1")
            install("pycparser")
            install("certifi")
            install("pycryptodomex==3.21.0")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
