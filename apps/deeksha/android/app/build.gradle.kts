import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningFile = rootProject.file("key.properties")
val releaseSigning = Properties()
if (releaseSigningFile.isFile) {
    releaseSigningFile.inputStream().use { releaseSigning.load(it) }
}

val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.substringAfterLast(':').contains("Release", ignoreCase = true)
}
if (releaseBuildRequested) {
    check(releaseSigningFile.isFile) {
        "Release signing requires android/key.properties. See android/key.properties.example."
    }
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").forEach { key ->
        check(!releaseSigning.getProperty(key).isNullOrBlank()) {
            "Missing '$key' in android/key.properties."
        }
    }
    check(rootProject.file(releaseSigning.getProperty("storeFile")).isFile) {
        "Release signing keystore does not exist: ${releaseSigning.getProperty("storeFile")}"
    }
}

android {
    namespace = "com.twilight.deeksha"
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
        applicationId = "com.twilight.deeksha"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseSigningFile.isFile) {
                storeFile = rootProject.file(releaseSigning.getProperty("storeFile"))
                storePassword = releaseSigning.getProperty("storePassword")
                keyAlias = releaseSigning.getProperty("keyAlias")
                keyPassword = releaseSigning.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
