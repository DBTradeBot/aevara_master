plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.aevara_app"

    // Keep using Flutter's compileSdk (typically 34 on stable).
    compileSdk = flutter.compileSdkVersion

    // Pin NDK to match Firebase native libs.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.aevara_app"

        // ✅ Kotlin DSL uses assignment, not "minSdkVersion ...".
        // If flutter.minSdkVersion is lower, force 23.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: replace with a real release signing config before publishing
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // debug options if needed
        }
    }
}

flutter {
    source = "../.."
}
