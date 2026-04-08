plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.logm1lo.ctos"
    compileSdk = 35
    ndkVersion = "25.1.8937393"

    // Ensure generated plugin registration is included
    sourceSets {
        getByName("main") {
            java.srcDirs(
                "src/main/kotlin",
                "src/main/java",
                "${project.layout.buildDirectory.get()}/generated/source/codegen"
            )
        }
    }

    defaultConfig {
        applicationId = "com.logm1lo.ctos"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../"
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)

    // Manually include Flutter plugin dependencies
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
                // Check if the project exists in the current build
                if (findProject(":$name") != null) {
                    implementation(project(":$name"))
                }
            }
        }
    }
}
