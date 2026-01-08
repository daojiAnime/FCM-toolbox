import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// 签名配置优先级：
// 1. 环境变量（CI/CD workflow）
// 2. key.properties 文件（本地开发）
// 3. debug 签名（fallback）

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// 检查是否有环境变量签名配置（CI 环境）
val hasEnvSigning = System.getenv("KEYSTORE_PASSWORD") != null
// 检查是否有 key.properties 文件签名配置（本地环境）
val hasFileSigning = keystorePropertiesFile.exists()

android {
    namespace = "io.github.daojianime.ccmonitor"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        // 启用 core library desugaring (ota_update 等插件需要)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "io.github.daojianime.ccmonitor"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            when {
                // CI 环境：使用环境变量
                hasEnvSigning -> {
                    storeFile = file(System.getenv("KEYSTORE_FILE") ?: "release.keystore")
                    storePassword = System.getenv("KEYSTORE_PASSWORD")
                    keyAlias = System.getenv("KEY_ALIAS") ?: "release"
                    keyPassword = System.getenv("KEY_PASSWORD")
                }
                // 本地环境：使用 key.properties
                hasFileSigning -> {
                    storeFile = file(keystoreProperties["storeFile"] as String)
                    storePassword = keystoreProperties["storePassword"] as String
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasEnvSigning || hasFileSigning -> signingConfigs.getByName("release")
                else -> signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring (Java 8+ API 在旧 Android 版本上的支持)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
