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
            keyAlias = releaseProperties["keyAlias"] as String?
            keyPassword = releaseProperties["keyPassword"] as String?
            storeFile = releaseProperties["storeFile"]?.let { rootProject.file(it) }
            storePassword = releaseProperties["storePassword"] as String?
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-DEV"
        }
        release {
            val hasSigningConfig = signingConfigs["release"]?.storeFile != null &&
                                   signingConfigs["release"]?.keyAlias != null

            if (hasSigningConfig) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = null
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