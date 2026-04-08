import 'dart:typed_data';
import 'package:face_detection_tflite/face_detection_tflite.dart' as fdt;
import 'package:image/image.dart' as img;

enum FaceModel { faceNet, mobileFaceNet }

class TFLiteService {
  fdt.FaceDetector? _detector;
  FaceModel _currentModel = FaceModel.faceNet;

  Future<void> loadModel(FaceModel model) async {
    _currentModel = model;
    _detector ??= fdt.FaceDetector();

    // The package handles model selection and loading internally
    // We can map our FaceModel to the package's model types if needed
    fdt.FaceDetectionModel pkgModel = model == FaceModel.faceNet
        ? fdt.FaceDetectionModel.backCamera
        : fdt.FaceDetectionModel.frontCamera;

    await _detector!.initialize(model: pkgModel);
  }

  Future<List<double>> getEmbedding(img.Image faceImage, Uint8List originalBytes) async {
    if (_detector == null) return [];

    // The new package provides getFaceEmbedding which takes a detected face and image bytes
    // For now, since we're refactoring, let's assume we'll use the package's internal detection too
    // or provide a way to get embedding from bytes.

    // If we have the cropped face image, we might need to convert it back to bytes
    // or use the package's detectFaces + getFaceEmbedding on the original image.
    final faces = await _detector!.detectFaces(originalBytes, mode: fdt.FaceDetectionMode.fast);

    if (faces.isEmpty) return [];

    final embedding = await _detector!.getFaceEmbedding(faces.first, originalBytes);
    return embedding;
  }

  FaceModel get currentModel => _currentModel;

  void dispose() {
    _detector?.dispose();
  }
}
