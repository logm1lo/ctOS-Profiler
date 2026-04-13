import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart' as fdt;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

import '../../core/utils/image_utils.dart';
import '../../core/utils/tflite_service.dart';
import '../../domain/entities/face_entity.dart';
import '../../domain/usecases/register_face.dart';
import '../../domain/usecases/match_face.dart';
import '../../data/datasources/face_local_datasource.dart';
import '../../data/repositories/face_repository_impl.dart';
import '../gallery/faces_provider.dart';
import 'target_profiling_screen.dart';

enum AppMode { register, match }
enum CaptureMethod { live, still }

final cameraProvider = StateNotifierProvider.autoDispose<CameraControllerNotifier, CameraState>((ref) {
  final dataSource = FaceLocalDataSource();
  final repository = FaceRepositoryImpl(dataSource);

  final notifier = CameraControllerNotifier(
    RegisterFace(repository),
    MatchFace(repository),
    ref,
  );

  return notifier;
});

class CameraState {
  final CameraController? controller;
  final bool isInitialized;
  final List<fdt.Face> detectedFaces;
  final bool isProcessing;
  final AppMode mode;
  final CaptureMethod captureMethod;
  final FaceModel modelType;
  final bool isScanning;
  final double scanProgress;
  final String scanStatus;
  final FaceEntity? matchedFace;
  final bool isFrontCamera;
  final double fps;
  final double processTime;

  CameraState({
    this.controller,
    this.isInitialized = false,
    this.detectedFaces = const [],
    this.isProcessing = false,
    this.mode = AppMode.match,
    this.captureMethod = CaptureMethod.still,
    this.modelType = FaceModel.faceNet,
    this.isScanning = false,
    this.scanProgress = 0.0,
    this.scanStatus = '',
    this.matchedFace,
    this.isFrontCamera = true,
    this.fps = 0.0,
    this.processTime = 0.0,
  });

  CameraState copyWith({
    CameraController? controller,
    bool? isInitialized,
    List<fdt.Face>? detectedFaces,
    bool? isProcessing,
    AppMode? mode,
    CaptureMethod? captureMethod,
    FaceModel? modelType,
    bool? isScanning,
    double? scanProgress,
    String? scanStatus,
    FaceEntity? matchedFace,
    bool clearMatchedFace = false,
    bool? isFrontCamera,
    double? fps,
    double? processTime,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      detectedFaces: detectedFaces ?? this.detectedFaces,
      isProcessing: isProcessing ?? this.isProcessing,
      mode: mode ?? this.mode,
      captureMethod: captureMethod ?? this.captureMethod,
      modelType: modelType ?? this.modelType,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      scanStatus: scanStatus ?? this.scanStatus,
      matchedFace: clearMatchedFace ? null : (matchedFace ?? this.matchedFace),
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      fps: fps ?? this.fps,
      processTime: processTime ?? this.processTime,
    );
  }
}

class CameraControllerNotifier extends StateNotifier<CameraState> {
  final RegisterFace _registerFace;
  final MatchFace _matchFace;
  final Ref _ref;
  final TFLiteService _tfliteService = TFLiteService();
  final fdt.FaceDetector _faceDetector = fdt.FaceDetector();

  bool _isDisposed = false;
  int _frameCount = 0;
  double _lastProcessTime = 0;
  double _fps = 0;
  final Map<int, DateTime> _faceFirstSeen = {};
  final Set<int> _matchedFaceIndices = {};

  CameraControllerNotifier(this._registerFace, this._matchFace, this._ref) : super(CameraState()) {
    debugPrint('ctOS_LOG: CameraControllerNotifier instance created');
  }

  Future<void> initialize() async {
    debugPrint('ctOS_LOG: initialize() called');
    if (_isDisposed) {
      debugPrint('ctOS_LOG: initialize() aborted - already disposed');
      return;
    }
    if (state.isInitialized || state.controller != null) {
      debugPrint('ctOS_LOG: initialize() aborted - already initialized');
      return;
    }

    try {
      final cameras = await availableCameras();
      debugPrint('ctOS_LOG: availableCameras() found ${cameras.length} devices');
      if (_isDisposed || !mounted || cameras.isEmpty) {
        debugPrint('ctOS_LOG: initialize() aborted after availableCameras()');
        return;
      }

      final controller = CameraController(
        cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      debugPrint('ctOS_LOG: controller.initialize() starting');
      await controller.initialize();
      if (_isDisposed || !mounted) {
        debugPrint('ctOS_LOG: initialize() aborted after controller.initialize()');
        await controller.dispose();
        return;
      }
      debugPrint('ctOS_LOG: controller.initialize() success');

      debugPrint('ctOS_LOG: loading models...');
      await _tfliteService.loadModel(state.modelType);
      await _faceDetector.initialize(model: fdt.FaceDetectionModel.frontCamera);

      if (_isDisposed || !mounted) {
        debugPrint('ctOS_LOG: initialize() aborted after model loading');
        await controller.dispose();
        return;
      }

      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        isFrontCamera: controller.description.lensDirection == CameraLensDirection.front,
      );

      debugPrint('ctOS_LOG: startImageStream() starting');
      if (!_isDisposed && controller.value.isInitialized) {
        controller.startImageStream((image) => _processCameraImage(image));
      }
    } catch (e) {
      debugPrint('ctOS_LOG: CRITICAL Error during initialization: $e');
    }
  }

  Future<void> toggleCamera() async {
    final cameras = await availableCameras();
    if (!mounted || cameras.length < 2) return;

    final currentDescription = state.controller?.description;
    final newDescription = cameras.firstWhere(
      (camera) => camera.lensDirection != currentDescription?.lensDirection,
      orElse: () => cameras.first,
    );

    if (state.controller != null) {
      try {
        if (state.controller!.value.isStreamingImages) {
          await state.controller!.stopImageStream();
        }
        await state.controller!.dispose();
      } catch (e) {
        debugPrint('Error disposing old camera: $e');
      }
    }

    if (!mounted) return;

    final controller = CameraController(
      newDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Re-initialize face detector based on camera direction
      final isFrontCamera = newDescription.lensDirection == CameraLensDirection.front;
      await _faceDetector.initialize(
        model: isFrontCamera ? fdt.FaceDetectionModel.frontCamera : fdt.FaceDetectionModel.backCamera
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }

      state = state.copyWith(
        controller: controller,
        isFrontCamera: isFrontCamera,
      );
      controller.startImageStream((image) => _processCameraImage(image));
    } catch (e) {
      debugPrint('Error toggling camera: $e');
    }
  }

  void toggleMode() {
    state = state.copyWith(
      mode: state.mode == AppMode.match ? AppMode.register : AppMode.match,
      clearMatchedFace: true,
    );
  }

  void setMode(AppMode mode) {
    state = state.copyWith(
      mode: mode,
      clearMatchedFace: true,
    );
  }

  void setCaptureMethod(CaptureMethod method) {
    state = state.copyWith(captureMethod: method);
  }

  Future<void> toggleModel() async {
    final nextModel = state.modelType == FaceModel.faceNet ? FaceModel.mobileFaceNet : FaceModel.faceNet;
    await _tfliteService.loadModel(nextModel);
    state = state.copyWith(modelType: nextModel);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed || !mounted || state.controller == null || state.isProcessing || state.isScanning || _frameCount++ % 10 != 0) return;

    final stopwatch = Stopwatch()..start();
    state = state.copyWith(isProcessing: true);

    try {
      final capturedImage = ImageUtils.convertYUV420ToImage(image);

      if (_isDisposed || !mounted) return;
      img.Image rotated = img.copyRotate(capturedImage, angle: state.isFrontCamera ? 270 : 90);

      final bytes = Uint8List.fromList(img.encodeJpg(rotated));
      if (_isDisposed || !mounted) return;
      final faces = await _faceDetector.detectFaces(bytes, mode: fdt.FaceDetectionMode.full);

      stopwatch.stop();
      _lastProcessTime = stopwatch.elapsedMilliseconds.toDouble();
      _fps = 1000 / _lastProcessTime;

    if (!_isDisposed && mounted && state.controller != null) {
      state = state.copyWith(
        detectedFaces: faces,
        isProcessing: false,
        processTime: _lastProcessTime,
        fps: _fps,
      );
    } else {
      return;
    }

      if (state.captureMethod == CaptureMethod.live && faces.isNotEmpty) {
        _handleLiveMatching(faces, rotated, bytes);
      } else if (faces.isEmpty) {
        _faceFirstSeen.clear();
        _matchedFaceIndices.clear();
        if (!_isDisposed && mounted && state.matchedFace != null) {
           state = state.copyWith(clearMatchedFace: true);
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        state = state.copyWith(isProcessing: false);
      }
    }
  }

  Future<void> _handleLiveMatching(List<fdt.Face> faces, img.Image fullImage, Uint8List imageBytes) async {
    final now = DateTime.now();

    // Since we don't have Face.id, we'll use a simple spatial tracker
    // For each detected face, find if it's "close enough" to one we've seen before

    final Map<int, DateTime> newFaceFirstSeen = {};
    final Set<int> newMatchedIndices = {};

    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final center = _getCenter(face.boundingBox);

      int? matchedPrevIndex;
      double minDistance = 100.0; // Distance threshold in pixels

      for (final prevEntry in _faceFirstSeen.entries) {
        if (prevEntry.key < state.detectedFaces.length) {
          final prevFace = state.detectedFaces[prevEntry.key];
          final prevCenter = _getCenter(prevFace.boundingBox);
          final distance = (center - prevCenter).distance;

          if (distance < minDistance) {
            minDistance = distance;
            matchedPrevIndex = prevEntry.key;
          }
        }
      }

      if (matchedPrevIndex != null) {
        newFaceFirstSeen[i] = _faceFirstSeen[matchedPrevIndex]!;
        if (_matchedFaceIndices.contains(matchedPrevIndex)) {
          newMatchedIndices.add(i);
        } else {
          final duration = now.difference(newFaceFirstSeen[i]!);
          if (duration.inMilliseconds > 1000) {
            newMatchedIndices.add(i);
            _performLiveMatch(face, fullImage, imageBytes);
          }
        }
      } else {
        newFaceFirstSeen[i] = now;
      }
    }

    _faceFirstSeen.clear();
    _faceFirstSeen.addAll(newFaceFirstSeen);
    _matchedFaceIndices.clear();
    _matchedFaceIndices.addAll(newMatchedIndices);
  }

  Offset _getCenter(fdt.BoundingBox bbox) {
    return Offset(bbox.topLeft.x + bbox.width / 2, bbox.topLeft.y + bbox.height / 2);
  }

  Future<void> _performLiveMatch(fdt.Face face, img.Image fullImage, Uint8List imageBytes) async {
    try {
      final bbox = face.boundingBox;
      img.Image cropped = ImageUtils.cropFace(fullImage, bbox.topLeft.x, bbox.topLeft.y, bbox.width, bbox.height);

      if (!mounted) return;
      final embedding = await _tfliteService.getEmbedding(cropped, imageBytes);

      if (!mounted) return;
      final match = await _matchFace.execute(embedding, state.modelType.name);

      if (mounted && state.controller != null) {
        if (match == null) {
          state = state.copyWith(matchedFace: null, scanStatus: 'NEW TARGET DETECTED', clearMatchedFace: true);
        } else {
          state = state.copyWith(matchedFace: match, scanStatus: 'MATCH FOUND', clearMatchedFace: false);
        }
      }
    } catch (e) {
      debugPrint('Live match error: $e');
    }
  }


  Future<void> captureAndProcess(BuildContext context) async {
    if (state.isScanning) return;

    state = state.copyWith(
      isScanning: true,
      scanProgress: 0.1,
      scanStatus: 'CAPTURING',
      clearMatchedFace: true,
    );

    try {
      if (state.controller == null || !state.controller!.value.isInitialized) {
        throw 'Camera not ready';
      }

      final XFile photo = await state.controller!.takePicture();
      if (context.mounted) {
        await _processFile(File(photo.path), context);
      }
    } catch (e) {
      if (context.mounted) {
        state = state.copyWith(isScanning: false, scanStatus: 'ERROR: $e');
      }
    }
  }

  Future<void> pickAndProcess(BuildContext context) async {
    if (state.isScanning) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    state = state.copyWith(
      isScanning: true,
      scanProgress: 0.1,
      scanStatus: 'LOADING IMAGE',
      clearMatchedFace: true,
    );

    try {
      if (context.mounted) {
        await _processFile(File(image.path), context);
      }
    } catch (e) {
      if (context.mounted) {
        state = state.copyWith(isScanning: false, scanStatus: 'ERROR: $e');
      }
    }
  }

  Future<void> saveFace(FaceEntity face) async {
    final dataSource = FaceLocalDataSource();
    final repository = FaceRepositoryImpl(dataSource);

    if (face.id != null) {
      await repository.updateFace(face);
    } else {
      await _registerFace.execute(face);
    }
    
    if (!mounted) return;

    _ref.invalidate(facesProvider);
    
    if (mounted) {
      try {
        state = state.copyWith(isScanning: false, scanStatus: 'REGISTERED');
      } catch (e) {
        debugPrint('ctOS_LOG: Ignored state update in saveFace after dispose: $e');
      }
    }
  }


  Future<void> _processFile(File file, BuildContext context) async {
    state = state.copyWith(scanProgress: 0.3, scanStatus: 'ANALYZING');

    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw 'Failed to decode image';

    // Use the first detected face from the captured image for accuracy
    final faces = await _faceDetector.detectFaces(bytes, mode: fdt.FaceDetectionMode.full);
    if (faces.isEmpty) throw 'No face detected in capture';

    final face = faces.first;
    final bbox = face.boundingBox;

    img.Image cropped = ImageUtils.cropFace(image, bbox.topLeft.x, bbox.topLeft.y, bbox.width, bbox.height);
    state = state.copyWith(scanProgress: 0.6, scanStatus: 'ENCODING');

    // Use the new service to get embedding
    final embedding = await _tfliteService.getEmbedding(cropped, bytes);
    state = state.copyWith(scanProgress: 0.8, scanStatus: 'MATCHING');

    if (state.mode == AppMode.match) {
      final match = await _matchFace.execute(embedding, state.modelType.name);
      if (mounted) {
        state = state.copyWith(scanProgress: 1.0, scanStatus: 'DONE', matchedFace: match);
      }
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        state = state.copyWith(isScanning: false);
      }
    } else {
      // Move file to permanent storage
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = p.join(directory.path, fileName);
      final permanentFile = await file.copy(permanentPath);

      // Register Mode - Navigate to profiling screen
      if (mounted) {
        state = state.copyWith(isScanning: false);
      }
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetProfilingScreen(
              imageFile: permanentFile,
              face: face,
              embedding: embedding,
            ),
          ),
        );
      }
    }
  }



  Future<void> stop({bool isDisposing = false}) async {
    debugPrint('ctOS_LOG: stop() called (isDisposing: $isDisposing)');
    if (_isDisposed) {
      debugPrint('ctOS_LOG: stop() already called once. Skipping.');
      return;
    }
    _isDisposed = true;

    final controller = state.controller;

    // 1. Immediately nullify state to prevent new frames/logic, 
    // but only if we're not already in the middle of disposing the notifier.
    if (!isDisposing && mounted) {
      try {
        state = state.copyWith(controller: null, isInitialized: false);
      } catch (e) {
        debugPrint('ctOS_LOG: Could not update state during stop: $e');
      }
    }

    if (controller != null) {
      // 2. Decisively dispose the hardware
      debugPrint('ctOS_LOG: Disposing camera hardware...');
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
        await controller.dispose();
        debugPrint('ctOS_LOG: Camera hardware disposed successfully.');
      } catch (e) {
        debugPrint('ctOS_LOG: Error disposing camera controller: $e');
      }
    }

    _faceDetector.dispose();
    _tfliteService.dispose();
    debugPrint('ctOS_LOG: stop() completed');
  }

  @override
  void dispose() {
    debugPrint('ctOS_LOG: CameraControllerNotifier.dispose() called');
    stop(isDisposing: true);
    super.dispose();
  }
}
