import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart' as fdt;
import 'package:image/image.dart' as img;

enum FaceModel { faceNet, mobileFaceNet }

class TFLiteService {
  static const String TAG = "TFLiteService";
  fdt.FaceDetector? _detector;
  FaceModel _currentModel = FaceModel.faceNet;

  Future<void> initialize({required bool isFrontCamera}) async {
    developer.log('[initialize] → Entry: isFrontCamera=$isFrontCamera', name: TAG);
    if (_detector != null) {
      developer.log('[initialize] → Status: Disposing previous detector', name: TAG);
      _detector!.dispose();
    }
    _detector = fdt.FaceDetector();
    
    final model = isFrontCamera
        ? fdt.FaceDetectionModel.frontCamera 
        : fdt.FaceDetectionModel.backCamera;
    
    developer.log('[initialize] → Status: Initializing model type: $model', name: TAG);
    try {
      await _detector!.initialize(model: model);
      developer.log('[initialize] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[initialize] → Error: $e', name: TAG, error: e);
    }
  }

  Future<void> loadModel(FaceModel model) async {
    developer.log('[loadModel] → Entry: model=${model.name}', name: TAG);
    _currentModel = model;
    developer.log('[loadModel] → Exit: currentModel set to ${model.name}', name: TAG);
  }

  Future<List<fdt.Face>> detectFaces(Uint8List bytes) async {
    // developer.log('[detectFaces] → Entry: bytes=${bytes.length}', name: TAG); // High frequency noise
    if (_detector == null) {
      developer.log('[detectFaces] → Error: Detector not initialized', name: TAG);
      return [];
    }
    try {
      final faces = await _detector!.detectFaces(bytes, mode: fdt.FaceDetectionMode.full);
      // if (faces.isNotEmpty) developer.log('[detectFaces] → Status: Detected ${faces.length} faces', name: TAG);
      return faces;
    } catch (e) {
      developer.log('[detectFaces] → Error: $e', name: TAG, error: e);
      return [];
    }
  }

  Future<List<double>> getEmbedding(fdt.Face face, Uint8List originalBytes) async {
    developer.log('[getEmbedding] → Entry: faceBbox=${face.boundingBox}', name: TAG);
    if (_detector == null) {
      developer.log('[getEmbedding] → Error: Detector not initialized', name: TAG);
      return [];
    }
    
    try {
      final embedding = await _detector!.getFaceEmbedding(face, originalBytes);
      developer.log('[getEmbedding] → Exit: Generated ${embedding.length}-dimensional vector', name: TAG);
      return embedding;
    } catch (e) {
      developer.log('[getEmbedding] → Error: Failed to extract features: $e', name: TAG, error: e);
      return [];
    }
  }

  FaceModel get currentModel => _currentModel;

  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _detector?.dispose();
    _detector = null;
    developer.log('[dispose] → Exit: Completed successfully', name: TAG);
  }
}
