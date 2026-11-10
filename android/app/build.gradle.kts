plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val devAppIdSuffix = System.getenv("QO_APP_ID_SUFFIX")?.takeIf { it.isNotBlank() }

android {
    namespace = "com.tursinalabs.quranoffline"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.tursinalabs.quranoffline"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Quran Offline"
        manifestPlaceholders["appIcon"] = "@mipmap/ic_launcher"
        // Dev only: QO_APP_ID_SUFFIX=.dev installs a side-by-side build without
        // replacing the installed app, labelled "Quran Offline DEV" with a badged
        // icon (src/dev/res, from tools/make_dev_launcher_icon.py).
        devAppIdSuffix?.let {
            applicationIdSuffix = it
            manifestPlaceholders["appLabel"] = "Quran Offline DEV"
            manifestPlaceholders["appIcon"] = "@mipmap/ic_launcher_dev"
        }
    }

    if (devAppIdSuffix != null) {
        sourceSets["main"].res.srcDir("src/dev/res")
    }

    buildFeatures {
        compose = true
    }

    buildTypes {
        release {
            // Use release signing config if key.properties exists, otherwise use
            // debug. A debug-signed store build is refused below.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// A release of the store app without key.properties would be debug-signed yet
// look ready to upload. Fail those tasks instead. DEV builds (QO_APP_ID_SUFFIX)
// may stay debug-signed, and QO_ALLOW_DEBUG_SIGNING=true opts out explicitly.
val allowDebugSigning =
    devAppIdSuffix != null || System.getenv("QO_ALLOW_DEBUG_SIGNING") == "true"
// preReleaseBuild runs first in every release build (APK and AAB).
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        if (!keystorePropertiesFile.exists() && !allowDebugSigning) {
            throw GradleException(
                "android/key.properties is missing: refusing a debug-signed " +
                    "release of com.tursinalabs.quranoffline. Add key.properties, " +
                    "or set QO_ALLOW_DEBUG_SIGNING=true for a local test build.",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.work:work-runtime-ktx:2.11.2")
    implementation("com.google.android.play:integrity:1.4.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}
