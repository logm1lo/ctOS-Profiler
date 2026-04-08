pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        properties.getProperty("flutter.sdk")
    }

    if (flutterSdkPath != null) {
        includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") apply false
    id("com.android.application") version "8.3.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
    }
}

rootProject.name = "ctOS"
include(":app")

// Manually include Flutter plugins
val flutterProjectRoot = rootDir
val pluginsFile = File(flutterProjectRoot, ".flutter-plugins-dependencies")
if (pluginsFile.exists()) {
    val json = groovy.json.JsonSlurper().parseText(pluginsFile.readText()) as? Map<*, *>
    val plugins = json?.get("plugins") as? Map<*, *>
    val androidPlugins = plugins?.get("android") as? List<*>
    
    androidPlugins?.forEach { 
        val plugin = it as? Map<*, *>
        val name = plugin?.get("name") as? String
        val path = plugin?.get("path") as? String
        if (name != null && path != null) {
            val androidPath = File(path, "android")
            val rootBuildGradle = File(path, "build.gradle")
            val rootBuildGradleKts = File(path, "build.gradle.kts")
            
            if (androidPath.exists() && (File(androidPath, "build.gradle").exists() || File(androidPath, "build.gradle.kts").exists())) {
                include(":$name")
                project(":$name").projectDir = androidPath
            } else if (rootBuildGradle.exists() || rootBuildGradleKts.exists()) {
                include(":$name")
                project(":$name").projectDir = File(path)
            } else {
                println("Skipping plugin $name because no Android Gradle project was found at $path")
            }
        }
    }
}
