import 'package:flutter/foundation.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart' as fdt;
import 'package:image/image.dart' as img;

enum FaceModel { faceNet, mobileFaceNet }

class TFLiteService {
  fdt.FaceDetector? _detector;
  FaceModel _currentModel = FaceModel.faceNet;

  Future<void> initialize({required bool isFrontCamera}) async {
    if (_detector != null) {
      _detector!.dispose();
    }
    _detector = fdt.FaceDetector();
    
    // Using front/back camera specific models for detection
    final model = isFrontCamera 
        ? fdt.FaceDetectionModel.frontCamera 
        : fdt.FaceDetectionModel.backCamera;
    
    await _detector!.initialize(model: model);
  }

  Future<void> loadModel(FaceModel model) async {
    _currentModel = model;
    // Note: The face_detection_tflite package version 5.x 
    // handles model loading internally based on initialization.
    // We keep track of the selected model type for matching logic.
  }

  Future<List<fdt.Face>> detectFaces(Uint8List bytes) async {
    if (_detector == null) return [];
    try {
      return await _detector!.detectFaces(bytes, mode: fdt.FaceDetectionMode.full);
    } catch (e) {
      debugPrint('ctOS_LOG: detectFaces error: $e');
      return [];
    }
  }

  Future<List<double>> getEmbedding(fdt.Face face, Uint8List originalBytes) async {
    if (_detector == null) return [];
    
    try {
      final embedding = await _detector!.getFaceEmbedding(face, originalBytes);
      return embedding;
    } catch (e) {
      debugPrint('ctOS_LOG: getFaceEmbedding error: $e');
      return [];
    }
  }

  FaceModel get currentModel => _currentModel;

  void dispose() {
    _detector?.dispose();
    _detector = null;
  }
}
