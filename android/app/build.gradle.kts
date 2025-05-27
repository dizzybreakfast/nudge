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
        ndkVersion = "27.0.12077973"
        applicationId = "com.protoqor.nudge"
        minSdk = 24
        targetSdk = 35
        versionCode = 2
        versionName = "N1.0.1"
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
            keyAlias = "nudge-key"
            keyPassword = "Fire7610"
            storeFile = file("release-key.jks")
            storePassword = "Fire7610"
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
