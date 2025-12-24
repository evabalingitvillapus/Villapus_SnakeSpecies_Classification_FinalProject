pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localPropertiesFile = file("local.properties")
            if (localPropertiesFile.exists()) {
                localPropertiesFile.inputStream().use { properties.load(it) }
            }

            // Ensure Android SDK path is set (sdk.dir) using common env vars or a sensible default
            val androidSdkProp = properties.getProperty("sdk.dir")
            val androidSdkEnv = System.getenv("ANDROID_SDK_ROOT") ?: System.getenv("ANDROID_HOME")
            val userHome = System.getProperty("user.home")
            val osName = System.getProperty("os.name").lowercase()
            val androidSdkDefault = when {
                osName.contains("win") -> "$userHome\\AppData\\Local\\Android\\Sdk"
                osName.contains("mac") -> "$userHome/Library/Android/sdk"
                else -> "$userHome/Android/Sdk"
            }
            val androidSdkPath = androidSdkProp ?: androidSdkEnv ?: if (file(androidSdkDefault).exists()) androidSdkDefault else null

            if (androidSdkPath != null && androidSdkProp == null) {
                properties.setProperty("sdk.dir", androidSdkPath)
                localPropertiesFile.outputStream().use { properties.store(it, null) }
            }

            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
