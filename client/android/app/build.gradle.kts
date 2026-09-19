import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("keystore-release.properties")
if (releasePropertiesFile.exists()) {
    releaseProperties.load(FileInputStream(releasePropertiesFile))
}

android {
    namespace = "cloud.phylum.drive"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "cloud.phylum.drive"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        base {
            archivesName = "phylum-" + versionName
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseProperties["keyAlias"] as String
            keyPassword = releaseProperties["keyPassword"] as String
            storeFile = releaseProperties["storeFile"]?.let { file(it) }
            storePassword = releaseProperties["storePassword"] as String
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-DEV"
        }
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

flutter {
    source = "../.."
}

// project(':receive_sharing_intent').afterEvaluate {
//     project(':receive_sharing_intent').android {
//         compileOptions {
//             sourceCompatibility JavaVersion.VERSION_1_8
//             targetCompatibility JavaVersion.VERSION_1_8
//         }
//         kotlinOptions {
//             jvmTarget = JavaVersion.VERSION_1_8
//         }
//     }
// }

// project(':irondash_engine_context').afterEvaluate {
//     project(':irondash_engine_context').android {
//         compileSdkVersion flutter.compileSdkVersion
//     }
// }

// project(':super_native_extensions').afterEvaluate {
//     project(':super_native_extensions').android {
//         compileSdkVersion flutter.compileSdkVersion
//     }
// }