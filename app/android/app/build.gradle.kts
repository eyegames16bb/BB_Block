import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// EYE GAMES — Release signing (bkz. android/key.properties, asla Git'e eklenmez).
// Dosya yoksa (ör. key.properties'i henüz almamış bir CI/geliştirici ortamı)
// `hasReleaseSigning` false kalır: debug build'ler bundan tamamen etkilenmeden
// çalışmaya devam eder, release signingConfig'i ise hiç OLUŞTURULMAZ — Gradle
// bu durumda release build'i debug key'e SESSİZCE düşürmek yerine imzasız
// bırakır (bkz. buildTypes.release aşağıda), böylece kazara debug-imzalı bir
// release artifact üretilmesi mimari olarak imkansız hale gelir.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.bbblock.bb_block"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bbblock.bb_block"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // EYE GAMES upload-key ile imzalanır — debug signing'e ASLA
            // düşülmez. key.properties/keystore mevcut değilse bu build type
            // imzasız kalır (release/bundleRelease başarısız olur), Play
            // Store'a debug-imzalı bir artifact gitmesi hiçbir koşulda
            // mümkün değildir.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            // R8/ProGuard + resource shrinking — önceden hiç açık değildi,
            // yayınlanan APK/AAB minify/obfuscate edilmeden gidiyordu
            // (MASTER_AUDIT_REPORT.md madde A3/G3). Kod-taraflı obfuscation
            // (`--obfuscate --split-debug-info`) ayrı bir `flutter build`
            // komut satırı bayrağı — Codemagic workflow'u (Aşama 12)
            // release build'i her zaman bu bayraklarla tetikleyecek şekilde
            // kurulacak.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
