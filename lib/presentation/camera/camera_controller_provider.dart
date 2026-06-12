import 'dart:io';
import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart' as fdt;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

import 'package:geolocator/geolocator.dart';

import '../../core/utils/image_utils.dart';
import '../../core/utils/tflite_service.dart';
import '../../core/utils/similarity.dart';
import '../../core/utils/osint_service.dart';
import '../../core/providers/settings_provider.dart';
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
  final bool isPoiTrackerActive;

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
    this.isPoiTrackerActive = false,
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
    bool? isPoiTrackerActive,
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
      isPoiTrackerActive: isPoiTrackerActive ?? this.isPoiTrackerActive,
    );
  }
}

class CameraControllerNotifier extends StateNotifier<CameraState> {
  static const String TAG = "CameraControllerNotifier";
  final RegisterFace _registerFace;
  final MatchFace _matchFace;
  final Ref _ref;
  final TFLiteService _tfliteService = TFLiteService();
  final OSINTService _osintService = OSINTService();

  bool _isDisposed = false;
  int _frameCount = 0;
  double _lastProcessTime = 0;
  double _fps = 0;
  DateTime? _lastFrameTime;
  final Map<int, DateTime> _faceFirstSeen = {};
  final Set<int> _matchedFaceIndices = {};

  CameraControllerNotifier(this._registerFace, this._matchFace, this._ref) : super(CameraState()) {
    developer.log('ctOS_TRACE: CameraControllerNotifier instance created', name: TAG);
  }

  Future<void> initialize() async {
    developer.log('[initialize] → Entry', name: TAG);
    if (_isDisposed) {
      developer.log('[initialize] → Exit: Already disposed', name: TAG);
      return;
    }
    if (state.isInitialized || state.controller != null) {
      developer.log('[initialize] → Exit: Already initialized', name: TAG);
      return;
    }

    try {
      final cameras = await availableCameras();
      developer.log('[initialize] → Status: Found ${cameras.length} devices', name: TAG);
      if (_isDisposed || !mounted || cameras.isEmpty) {
        developer.log('[initialize] → Exit: Initialization aborted (disposed or no cameras)', name: TAG);
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

      developer.log('[initialize] → Status: Initializing controller', name: TAG);
      await controller.initialize();
      if (_isDisposed || !mounted) {
        developer.log('[initialize] → Status: Disposing controller after late abortion', name: TAG);
        await controller.dispose();
        return;
      }

      developer.log('[initialize] → Status: Controller initialized, loading TFLite models', name: TAG);
      await _tfliteService.loadModel(state.modelType);
      await _tfliteService.initialize(isFrontCamera: controller.description.lensDirection == CameraLensDirection.front);

      if (_isDisposed || !mounted) {
        developer.log('[initialize] → Status: Disposing controller after model loading abortion', name: TAG);
        await controller.dispose();
        return;
      }

      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        isFrontCamera: controller.description.lensDirection == CameraLensDirection.front,
      );

      developer.log('[initialize] → Status: Starting image stream', name: TAG);
      if (!_isDisposed && controller.value.isInitialized) {
        controller.startImageStream((image) => _processCameraImage(image));
      }
      developer.log('[initialize] → Exit: Initialization successful', name: TAG);
    } catch (e) {
      developer.log('[initialize] → Error: $e', name: TAG, error: e);
    }
  }

  Future<void> toggleCamera() async {
    developer.log('[toggleCamera] → Entry', name: TAG);
    final cameras = await availableCameras();
    if (!mounted || cameras.length < 2) {
      developer.log('[toggleCamera] → Exit: Not enough cameras available', name: TAG);
      return;
    }

    final currentDescription = state.controller?.description;
    final newDescription = cameras.firstWhere(
      (camera) => camera.lensDirection != currentDescription?.lensDirection,
      orElse: () => cameras.first,
    );

    if (state.controller != null) {
      try {
        developer.log('[toggleCamera] → Status: Disposing old controller', name: TAG);
        if (state.controller!.value.isStreamingImages) {
          await state.controller!.stopImageStream();
        }
        await state.controller!.dispose();
      } catch (e) {
        developer.log('[toggleCamera] → Warning: Error disposing old camera: $e', name: TAG);
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

      final isFrontCamera = newDescription.lensDirection == CameraLensDirection.front;
      developer.log('[toggleCamera] → Status: Re-initializing face detector (isFront=$isFrontCamera)', name: TAG);
      await _tfliteService.initialize(isFrontCamera: isFrontCamera);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      state = state.copyWith(
        controller: controller,
        isFrontCamera: isFrontCamera,
      );
      controller.startImageStream((image) => _processCameraImage(image));
      developer.log('[toggleCamera] → Exit: Camera toggled successfully', name: TAG);
    } catch (e) {
      developer.log('[toggleCamera] → Error: $e', name: TAG, error: e);
    }
  }

  void toggleMode() {
    developer.log('[toggleMode] → Entry: current=${state.mode}', name: TAG);
    state = state.copyWith(
      mode: state.mode == AppMode.match ? AppMode.register : AppMode.match,
      clearMatchedFace: true,
    );
    developer.log('[toggleMode] → Exit: new=${state.mode}', name: TAG);
  }

  void setMode(AppMode mode, {bool clearMatchedFace = true}) {
    developer.log('[setMode] → Entry: mode=$mode', name: TAG);
    state = state.copyWith(
      mode: mode,
      clearMatchedFace: clearMatchedFace,
    );
  }

  void setCaptureMethod(CaptureMethod method) {
    developer.log('[setCaptureMethod] → Entry: method=$method', name: TAG);
    state = state.copyWith(captureMethod: method);
  }

  Future<void> toggleModel() async {
    developer.log('[toggleModel] → Entry: current=${state.modelType}', name: TAG);
    final nextModel = state.modelType == FaceModel.faceNet ? FaceModel.mobileFaceNet : FaceModel.faceNet;
    await _tfliteService.loadModel(nextModel);
    state = state.copyWith(modelType: nextModel);
    developer.log('[toggleModel] → Exit: new=${state.modelType}', name: TAG);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed || !mounted || state.controller == null || state.isProcessing || state.isScanning) return;

    final now = DateTime.now();
    // Adaptive throttling: allow processing if last frame was more than 150ms ago
    if (_lastFrameTime != null && now.difference(_lastFrameTime!).inMilliseconds < 150) {
      return;
    }
    _lastFrameTime = now;

    // developer.log('[_processCameraImage] → Processing frame ${_frameCount++}', name: TAG);
    final stopwatch = Stopwatch()..start();
    state = state.copyWith(isProcessing: true);

    try {
      final Map<String, dynamic> args = {
        'planes': image.planes.map((p) => {
          'bytes': p.bytes,
          'bytesPerRow': p.bytesPerRow,
          'bytesPerPixel': p.bytesPerPixel,
        }).toList(),
        'width': image.width,
        'height': image.height,
        'format': image.format.group.name,
        'isFrontCamera': state.isFrontCamera,
      };

      final result = await compute(_heavyImageProcessing, args);

      if (_isDisposed || !mounted) return;

      final Uint8List bytes = result['bytes'] as Uint8List;
      final faces = await _tfliteService.detectFaces(bytes);
      
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
      }

      if (state.captureMethod == CaptureMethod.live && faces.isNotEmpty) {
        _handleLiveMatching(faces, bytes);
      } else if (faces.isEmpty) {
        _faceFirstSeen.clear();
        _matchedFaceIndices.clear();
      }
    } catch (e) {
      developer.log('[_processCameraImage] → Error: $e', name: TAG, error: e);
      if (!_isDisposed && mounted) {
        state = state.copyWith(isProcessing: false);
      }
    }
  }

  static Future<Map<String, dynamic>> _heavyImageProcessing(Map<String, dynamic> args) async {
    final List<dynamic> planesData = args['planes'];
    final int width = args['width'];
    final int height = args['height'];
    final bool isFrontCamera = args['isFrontCamera'];

    final int uvRowStride = planesData[1]['bytesPerRow'];
    final int uvPixelStride = planesData[1]['bytesPerPixel'] ?? 1;
    final Uint8List yBytes = planesData[0]['bytes'];
    final Uint8List uBytes = planesData[1]['bytes'];
    final Uint8List vBytes = planesData[2]['bytes'];

    final outImg = img.Image(width: width, height: height, numChannels: 3);

    for (int y = 0; y < height; y++) {
      final int yOffset = y * width;
      final int uvYOffset = uvRowStride * (y >> 1);

      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x >> 1) + uvYOffset;
        final int index = yOffset + x;

        if (index >= yBytes.length || uvIndex >= uBytes.length || uvIndex >= vBytes.length) continue;

        final int yp = yBytes[index];
        final int up = uBytes[uvIndex] - 128;
        final int vp = vBytes[uvIndex] - 128;

        final int r = (yp + (vp * 1.402)).round().clamp(0, 255);
        final int g = (yp - (up * 0.344136) - (vp * 0.714136)).round().clamp(0, 255);
        final int b = (yp + (up * 1.772)).round().clamp(0, 255);

        outImg.setPixelRgb(x, y, r, g, b);
      }
    }

    final img.Image rotated = img.copyRotate(outImg, angle: isFrontCamera ? 270 : 90);
    final bytes = Uint8List.fromList(img.encodeJpg(rotated, quality: 85));

    return {'bytes': bytes};
  }

  Future<void> _handleLiveMatching(List<fdt.Face> faces, Uint8List imageBytes) async {
    final now = DateTime.now();
    final Map<int, DateTime> newFaceFirstSeen = {};
    final Set<int> newMatchedIndices = {};

    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final center = _getCenter(face.boundingBox);

      int? matchedPrevIndex;
      double minDistance = 100.0;

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
            _performLiveMatch(face, imageBytes);
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

  Future<void> _performLiveMatch(fdt.Face face, Uint8List imageBytes) async {
    developer.log('[_performLiveMatch] → Entry', name: TAG);
    try {
      if (!mounted) return;
      final embedding = await _tfliteService.getEmbedding(face, imageBytes);

      if (!mounted) return;
      final match = await _matchFace.execute(embedding, state.modelType.name);

      if (mounted && state.controller != null) {
        if (match == null) {
          developer.log('[_performLiveMatch] → No match found', name: TAG);
          state = state.copyWith(matchedFace: null, scanStatus: 'NEW TARGET DETECTED', clearMatchedFace: true);
        } else {
          developer.log('[_performLiveMatch] → Match detected: ${match.name}', name: TAG);
          final isPoi = match.isPoi;
          state = state.copyWith(
            matchedFace: match,
            scanStatus: isPoi ? 'POI_TARGET_LOCKED: ${match.name.toUpperCase()}' : 'MATCH FOUND',
            clearMatchedFace: false
          );
          _onFaceMatched(match, imageBytes);
        }
      }
    } catch (e) {
      developer.log('[_performLiveMatch] → Error: $e', name: TAG, error: e);
    }
  }

  Future<void> _onFaceMatched(FaceEntity face, Uint8List imageBytes) async {
    developer.log('[_onFaceMatched] → Entry: face=${face.name}, isPoi=${face.isPoi}', name: TAG);
    if (state.isPoiTrackerActive && face.isPoi && face.id != null) {
      developer.log('[_onFaceMatched] → Status: Triggering POI alert sequence', name: TAG);
      // 1. Haptic Feedback
      Future.delayed(Duration.zero, () async {
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
      });

      // 2. GPS Stamping
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 2),
        );
        developer.log('[_onFaceMatched] → Status: GPS stamp acquired (${position.latitude}, ${position.longitude})', name: TAG);
      } catch (e) {
        developer.log('[_onFaceMatched] → Warning: GPS capture failed: $e', name: TAG);
      }

      // 3. Media Capture (Save current frame)
      String? mediaPath;
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'poi_alert_${face.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = p.join(directory.path, 'alerts', fileName);

        final alertsDir = Directory(p.join(directory.path, 'alerts'));
        if (!await alertsDir.exists()) await alertsDir.create(recursive: true);

        final file = File(path);
        await file.writeAsBytes(imageBytes);
        mediaPath = path;
        developer.log('[_onFaceMatched] → Status: Evidence frame saved at $mediaPath', name: TAG);
      } catch (e) {
        developer.log('[_onFaceMatched] → Warning: Evidence frame capture failed: $e', name: TAG);
      }

      // 4. Save Alert to Database
      final dataSource = FaceLocalDataSource();
      await dataSource.insertPoiAlert(
        face.id!,
        position?.latitude ?? 0.0,
        position?.longitude ?? 0.0,
        mediaPath,
      );

      state = state.copyWith(scanStatus: 'POI_TARGET_LOCKED: ${face.name.toUpperCase()}');
      developer.log('[_onFaceMatched] → Exit: POI event logged for ${face.name}', name: TAG);
    }
  }

  void togglePoiTracker() {
    developer.log('[togglePoiTracker] → Entry: current=${state.isPoiTrackerActive}', name: TAG);
    state = state.copyWith(isPoiTrackerActive: !state.isPoiTrackerActive);
    developer.log('[togglePoiTracker] → Exit: new=${state.isPoiTrackerActive}', name: TAG);
  }

  Future<void> enrollFace(BuildContext context) async {
    developer.log('[enrollFace] → Entry', name: TAG);
    if (state.detectedFaces.isEmpty) {
      developer.log('[enrollFace] → Exit: No face detected to enroll', name: TAG);
      state = state.copyWith(scanStatus: 'NO FACE DETECTED FOR ENROLLMENT');
      return;
    }

    state = state.copyWith(isScanning: true, scanStatus: 'CAPTURING BIOMETRICS');

    try {
      final image = await state.controller?.takePicture();
      if (image != null && mounted) {
        developer.log('[enrollFace] → Status: Capture successful, analyzed path: ${image.path}', name: TAG);
        state = state.copyWith(mode: AppMode.register);
        await _processFile(File(image.path), context);
      }
    } catch (e) {
      developer.log('[enrollFace] → Error: $e', name: TAG, error: e);
      if (mounted) {
        state = state.copyWith(isScanning: false, scanStatus: 'ENROLL_ERROR: $e');
      }
    }
  }

  Future<void> performDeepSearch(BuildContext context, {FaceEntity? targetOverride}) async {
    final target = targetOverride ?? state.matchedFace;
    developer.log('[performDeepSearch] → Entry: targetName=${target?.name}', name: TAG);

    if (target == null) {
      developer.log('[performDeepSearch] → Exit: No target identified for search', name: TAG);
      return;
    }

    state = state.copyWith(
      isScanning: true,
      scanProgress: 0.1,
      scanStatus: 'DEEP OSINT SEARCH',
    );

    try {
      Uint8List? photoBytes = target.photoBytes;
      if (photoBytes == null && target.photoPath.isNotEmpty) {
        final file = File(target.photoPath);
        if (await file.exists()) {
          photoBytes = await file.readAsBytes();
        }
      }

      if (photoBytes == null && target.id == null) {
        developer.log('[performDeepSearch] → Status: Capturing fresh frame for unknown target', name: TAG);
        final image = await state.controller?.takePicture();
        if (image != null) {
          photoBytes = await File(image.path).readAsBytes();
        }
      }

      if (photoBytes == null) {
        developer.log('[performDeepSearch] → Error: Biometric data retrieval failed', name: TAG);
        throw 'UNABLE_TO_RETRIEVE_BIOMETRIC_DATA';
      }

      final settings = _ref.read(settingsProvider);
      final result = await _osintService.performDeepSearch(
        photoBytes,
        settings.osintApiKey,
        testingMode: settings.osintTestingMode,
        onProgress: (p) {
          if (mounted) {
            String status = 'SEARCHING';
            if (p < 0.2) status = 'UPLOADING BIOMETRICS';
            else if (p < 0.6) status = 'OSINT_POLLING';
            else if (p < 0.9) status = 'USERNAME_ENUMERATION';
            else status = 'FINALIZING';

            state = state.copyWith(scanProgress: p, scanStatus: status);
          }
        },
      );

      developer.log('[performDeepSearch] → Status: Search returned results, updating profile', name: TAG);

      final updatedFace = FaceEntity(
        id: target.id,
        name: target.id == null ? (result['aliases']?.first ?? 'UNKNOWN_RESOLVED') : target.name,
        embeddings: target.embeddings,
        modelUsed: target.modelUsed,
        photoPath: target.photoPath,
        photoBytes: photoBytes,
        timestamp: target.timestamp,
        age: target.age,
        occupation: target.occupation,
        incomeLevel: target.incomeLevel,
        riskScore: target.riskScore,
        personalityTraits: target.personalityTraits,
        birthDate: target.birthDate,
        height: target.height,
        weight: target.weight,
        hobby: result['hobby'] ?? target.hobby,
        secret: result['secret'] ?? target.secret,
        recentHistory: List<String>.from(result['recent_history'] ?? target.recentHistory ?? []),
        socialLinks: List<String>.from(result['social_links'] ?? []),
        aliases: List<String>.from(result['aliases'] ?? []),
        digitalFootprintSummary: result['summary'] ?? '',
        isPoi: target.isPoi,
      );

      if (updatedFace.id != null) {
        await _saveFaceInternal(updatedFace, resetScanning: false);
      }

      if (mounted) {
        state = state.copyWith(
          isScanning: true,
          scanProgress: 1.0,
          scanStatus: 'SEARCH COMPLETE',
          matchedFace: updatedFace,
        );
      }

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) state = state.copyWith(isScanning: false);
      developer.log('[performDeepSearch] → Exit: Cycle complete', name: TAG);
    } catch (e) {
      developer.log('[performDeepSearch] → Error: $e', name: TAG, error: e);
      if (mounted) {
        state = state.copyWith(isScanning: true, scanProgress: 1.0, scanStatus: 'OSINT ERROR: $e');
      }
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) state = state.copyWith(isScanning: false);
    }
  }

  Future<void> queryUnknownFace(BuildContext context) async {
    developer.log('[queryUnknownFace] → Entry', name: TAG);
    if (state.detectedFaces.isEmpty) return;

    final tempFace = FaceEntity(
      name: 'UNKNOWN',
      embeddings: [],
      modelUsed: state.modelType.name,
      photoPath: '',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await performDeepSearch(context, targetOverride: tempFace);
  }


  Future<void> captureAndProcess(BuildContext context, {String? initialStatus, bool clearMatchedFace = true}) async {
    developer.log('[captureAndProcess] → Entry', name: TAG);
    if (state.isScanning) return;

    state = state.copyWith(
      isScanning: true,
      scanProgress: 0.1,
      scanStatus: initialStatus ?? 'CAPTURING',
      clearMatchedFace: clearMatchedFace,
    );

    try {
      if (state.controller == null || !state.controller!.value.isInitialized) throw 'Camera not ready';

      final XFile photo = await state.controller!.takePicture();
      if (context.mounted) {
        await _processFile(File(photo.path), context);
      }
    } catch (e) {
      developer.log('[captureAndProcess] → Error: $e', name: TAG, error: e);
      if (context.mounted) {
        state = state.copyWith(isScanning: false, scanStatus: 'ERROR: $e');
      }
    }
  }

  Future<void> pickAndProcess(BuildContext context) async {
    developer.log('[pickAndProcess] → Entry', name: TAG);
    if (state.isScanning) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      developer.log('[pickAndProcess] → Exit: Picker canceled', name: TAG);
      return;
    }

    state = state.copyWith(
      isScanning: true,
      scanProgress: 0.1,
      scanStatus: 'LOADING IMAGE',
      clearMatchedFace: true,
    );

    try {
      if (context.mounted) await _processFile(File(image.path), context);
    } catch (e) {
      developer.log('[pickAndProcess] → Error: $e', name: TAG, error: e);
      if (context.mounted) {
        state = state.copyWith(isScanning: false, scanStatus: 'ERROR: $e');
      }
    }
  }

  Future<void> saveFace(FaceEntity face) => _saveFaceInternal(face);

  Future<void> _saveFaceInternal(FaceEntity face, {bool resetScanning = true}) async {
    developer.log('[_saveFaceInternal] → Entry: faceName=${face.name}', name: TAG);
    final dataSource = FaceLocalDataSource();
    final repository = FaceRepositoryImpl(dataSource);

    try {
      if (face.id != null) {
        developer.log('[_saveFaceInternal] → Status: Updating existing profile ID=${face.id}', name: TAG);
        final existingFaces = await repository.getAllFaces();
        final existing = existingFaces.firstWhere((f) => f.id == face.id);

        bool isNewEmbedding = true;
        for (var emb in existing.embeddings) {
          if (emb.length == face.embeddings.first.length) {
            double sim = SimilarityUtils.cosineSimilarity(face.embeddings.first, emb);
            if (sim > 0.99) {
              isNewEmbedding = false;
              break;
            }
          }
        }

        final mergedEmbeddings = isNewEmbedding
            ? (List<List<double>>.from(existing.embeddings)..addAll(face.embeddings))
            : existing.embeddings;

        final updatedFace = FaceEntity(
          id: face.id,
          name: face.name,
          embeddings: mergedEmbeddings,
          modelUsed: face.modelUsed,
          photoPath: face.photoPath,
          photoBytes: face.photoBytes,
          timestamp: face.timestamp,
          age: face.age,
          occupation: face.occupation,
          incomeLevel: face.incomeLevel,
          riskScore: face.riskScore,
          personalityTraits: face.personalityTraits,
          birthDate: face.birthDate,
          height: face.height,
          weight: face.weight,
          socialLinks: face.socialLinks,
          aliases: face.aliases,
          digitalFootprintSummary: face.digitalFootprintSummary,
          isPoi: face.isPoi,
        );
        await repository.updateFace(updatedFace);
      } else {
        developer.log('[_saveFaceInternal] → Status: Registering new target', name: TAG);
        await _registerFace.execute(face);
      }

      _ref.read(facesProvider.notifier).refresh();

      if (mounted && resetScanning) {
        state = state.copyWith(isScanning: false, scanStatus: 'REGISTERED');
      }
      developer.log('[_saveFaceInternal] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[_saveFaceInternal] → Error: $e', name: TAG, error: e);
      if (mounted && resetScanning) {
        state = state.copyWith(isScanning: false, scanStatus: 'SAVE_ERROR');
      }
    }
  }


  Future<void> _processFile(File file, BuildContext context) async {
    developer.log('[_processFile] → Entry: path=${file.path}', name: TAG);
    state = state.copyWith(scanProgress: 0.3, scanStatus: 'ANALYZING');

    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw 'Failed to decode image';

    final faces = await _tfliteService.detectFaces(bytes);
    if (faces.isEmpty) {
      developer.log('[_processFile] → Error: No face detected in file', name: TAG);
      throw 'No face detected in capture';
    }

    final face = faces.first;
    state = state.copyWith(scanProgress: 0.6, scanStatus: 'EXTRACTING FEATURES');

    final embedding = await _tfliteService.getEmbedding(face, bytes);
    state = state.copyWith(scanProgress: 0.8, scanStatus: 'MATCHING');

    if (state.mode == AppMode.match) {
      final match = await _matchFace.execute(embedding, state.modelType.name);
      developer.log('[_processFile] → Match outcome: ${match?.name ?? "No Match"}', name: TAG);
      if (mounted) state = state.copyWith(scanProgress: 1.0, scanStatus: 'DONE', matchedFace: match);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) state = state.copyWith(isScanning: false);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = p.join(directory.path, fileName);
      final permanentFile = await file.copy(permanentPath);

      if (mounted) state = state.copyWith(isScanning: false);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetProfilingScreen(
              imageFile: permanentFile,
              face: face,
              embedding: embedding,
              existingFace: state.matchedFace,
            ),
          ),
        );
      }
    }
  }



  Future<void> stop({bool isDisposing = false}) async {
    developer.log('[stop] → Entry: isDisposing=$isDisposing', name: TAG);
    if (_isDisposed) return;
    _isDisposed = true;

    final controller = state.controller;

    if (!isDisposing && mounted) {
      try {
        state = state.copyWith(controller: null, isInitialized: false);
      } catch (e) {
        developer.log('[stop] → Error updating state: $e', name: TAG);
      }
    }

    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
        await controller.dispose();
        developer.log('[stop] → Status: Hardware controller disposed', name: TAG);
      } catch (e) {
        developer.log('[stop] → Error disposing controller: $e', name: TAG);
      }
    }

    _tfliteService.dispose();
    developer.log('[stop] → Exit: System shutdown complete', name: TAG);
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    stop(isDisposing: true);
    super.dispose();
  }
}
