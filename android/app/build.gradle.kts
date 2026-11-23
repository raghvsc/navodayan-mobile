import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    val appKeystorePropertiesFile = file("key.properties")
    if (appKeystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(appKeystorePropertiesFile))
    }
}

android {
    namespace = "org.navodayan.app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "navodayan_upload"
            keyPassword = keystoreProperties["keyPassword"] as String? ?: "Navodayan@2026!Store"
            val keyStoreFileName = keystoreProperties["storeFile"] as String? ?: "upload-keystore.jks"
            val resolvedStoreFile = if (file(keyStoreFileName).exists()) {
                file(keyStoreFileName)
            } else if (rootProject.file(keyStoreFileName).exists()) {
                rootProject.file(keyStoreFileName)
            } else {
                file("upload-keystore.jks")
            }
            storeFile = resolvedStoreFile
            storePassword = keystoreProperties["storePassword"] as String? ?: "Navodayan@2026!Store"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.navodayan.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            // 16 KB page size support requirement for Android 15/16 and Google Play
            useLegacyPackaging = false
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
