import org.gradle.api.Plugin
import org.gradle.api.Project

class FlutterMockPlugin implements Plugin<Project> {
    void apply(Project project) {
        if (project.name != "app") {
            project.extensions.create("flutter", FlutterMockExtension)
            
            project.afterEvaluate {
                project.dependencies.add("implementation", "io.flutter:flutter_embedding_debug:1.0.0-425cfb54d01a9472b3e81d9e76fd63a4a44cfbcb")
                if (project.name != "flutter_plugin_android_lifecycle") {
                    project.dependencies.add("implementation", project.project(":flutter_plugin_android_lifecycle"))
                }
                project.dependencies.add("implementation", "androidx.annotation:annotation:1.9.1")
                project.dependencies.add("implementation", "androidx.lifecycle:lifecycle-common:2.8.7")
                project.dependencies.add("implementation", "androidx.lifecycle:lifecycle-runtime:2.8.7")
                project.dependencies.add("implementation", "androidx.core:core:1.13.1")
            }
        }
    }
}

class FlutterMockExtension {
    int compileSdkVersion = 35
    int minSdkVersion = 24
    int targetSdkVersion = 35
    String ndkVersion = "25.1.8937393"

    int getCompileSdkVersion() { return compileSdkVersion }
    int getMinSdkVersion() { return minSdkVersion }
    int getTargetSdkVersion() { return targetSdkVersion }
    String getNdkVersion() { return ndkVersion }
}
