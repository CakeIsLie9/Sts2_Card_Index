plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Base64

android {
    namespace = "com.example.card_index"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.card_index"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // txt에서 Base64를 읽어 진짜 바이너리 key.jks 파일로 자동 변환 생성
    val b64File = file("key_base64.txt")
    val jksFile = file("key.jks")

    if (b64File.exists()) {
        val decodedBytes = Base64.getDecoder().decode(b64File.readText().trim())
        jksFile.writeBytes(decodedBytes)
    }

    signingConfigs {
        create("release") {
            keyAlias = "mykey"
            keyPassword = "password123"
            storePassword = "password123"
            storeFile = jksFile
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
