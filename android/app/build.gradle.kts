plugins {
    id("org.jetbrains.kotlin.android")
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    // id("com.google.gms.google-services")
}

android {
    namespace = "com.example.nudge"
    compileSdk = 35

    defaultConfig {
        ndkVersion = "25.1.8937393"
        applicationId = "com.example.nudge"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "N.010.001"
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = "release"
            keyPassword = "nudge.app"
            storeFile = file("release-key.jks")
            storePassword = "nudge.app"
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

dependencies {
    // implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
    // implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
