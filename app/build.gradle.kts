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
        
        // SAFE SIZE REDUCTION: Only include English resources. 
        // This strips hundreds of unused localized strings from libraries.
        resourceConfigurations += "en"
    }

    buildTypes {
        release {
            // SAFE SIZE REDUCTION: Enable shrinking but use "safe" ProGuard rules.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        jniLibs {
            // Extract native libraries to the filesystem. 
            // This is required for OpenCV to perform directory-based lookups for native symbols.
            useLegacyPackaging = true
        }
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    androidResources {
        // Do not compress TFLite models. This allows them to be memory-mapped
        // directly from the APK, which reduces memory usage at runtime.
        noCompress += "tflite"
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
    implementation(libs.play.feature.delivery)
    implementation(libs.play.core.common)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)

    // Include Flutter plugin dependencies
    val flutterProjectRoot = rootDir
    val pluginsFile = File(flutterProjectRoot, ".flutter-plugins-dependencies")
    if (pluginsFile.exists()) {
        val json = groovy.json.JsonSlurper().parseText(pluginsFile.readText()) as? Map<*, *>
        val plugins = json?.get("plugins") as? Map<*, *>
        val androidPlugins = plugins?.get("android") as? List<*>
        
        androidPlugins?.forEach { 
            val plugin = it as? Map<*, *>
            val name = plugin?.get("name") as? String
            if (name != null) {
                if (findProject(":$name") != null) {
                    implementation(project(":$name"))
                }
            }
        }
    }
}
