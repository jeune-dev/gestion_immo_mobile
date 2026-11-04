import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de publication : android/key.properties (jamais versionné), voir
// https://docs.flutter.dev/deployment/android#sign-the-app
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "sn.gestionimmo.gestion_immo_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Même identifiant que l'app iOS (le « _ » y est interdit) : un seul identifiant
        // pour les deux boutiques et pour Firebase. `namespace` (paquet Kotlin) ne change pas.
        applicationId = "sn.gestionimmo.gestionImmoMobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sans key.properties, la clé de debug n'est permise que sur demande
            // explicite (ALLOW_DEBUG_SIGNING=true) : une version à publier échoue.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else if (System.getenv("ALLOW_DEBUG_SIGNING") == "true") {
                logger.warn("android/key.properties absent : APK de release signée avec la clé de DEBUG.")
                signingConfigs.getByName("debug")
            } else {
                null
            }
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

// Notifications push : actives une fois android/app/google-services.json déposé.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

gradle.taskGraph.whenReady {
    val publication = allTasks.any { it.name == "assembleRelease" || it.name == "bundleRelease" }
    if (publication && !keystorePropertiesFile.exists() && System.getenv("ALLOW_DEBUG_SIGNING") != "true") {
        throw GradleException("android/key.properties est requis pour signer une version de publication.")
    }
}
