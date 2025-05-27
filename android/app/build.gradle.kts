plugins {
    id("org.jetbrains.kotlin.android")
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    // id("com.google.gms.google-services")
}

android {
    namespace = "com.protoqor.nudge"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.protoqor.nudge"
        minSdk = 24
        targetSdk = 35
        versionCode = 2
        versionName = "N1.0.1"
    }

    compileOptions {
        // Java 17 compatibility
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // Kotlin JVM target
    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("NUDGE_KEY_ALIAS") ?: "nudge-key"
            keyPassword = System.getenv("NUDGE_KEY_PASSWORD") ?: "Fire7610"
            storeFile = file(System.getenv("NUDGE_STORE_FILE") ?: "release-key.jks")
            storePassword = System.getenv("NUDGE_STORE_PASSWORD") ?: "Fire7610"
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
