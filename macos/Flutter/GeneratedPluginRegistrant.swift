//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import face_detection_tflite
import file_selector_macos
import shared_preferences_foundation
import sqflite_darwin

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FaceDetectionTflitePlugin.register(with: registry.registrar(forPlugin: "FaceDetectionTflitePlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
}
