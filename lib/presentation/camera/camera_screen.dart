import 'dart:io';
import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/tflite_service.dart';
import '../shared/neon_button.dart';
import 'camera_controller_provider.dart';
import 'widgets/hud_overlay.dart';
import 'widgets/scan_progress_overlay.dart';
import 'widgets/glitchy_button.dart';
import '../../domain/entities/face_entity.dart';
import 'target_profiling_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  static const String TAG = "CameraScreen";

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('[initState] → Status: Requesting camera hardware initialization', name: TAG);
      ref.read(cameraProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    super.dispose();
  }

  Widget _buildCaptureMethodSlider(CameraState state, AppTheme theme) {
    final accentColor = AppColors.getAccent(theme);
    return Container(
      width: 240,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: accentColor, width: 1),
        color: (theme == AppTheme.neonBlack ? Colors.black : Colors.white).withValues(alpha: 0.5),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: state.captureMethod == CaptureMethod.live
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: 120,
              height: 40,
              color: accentColor.withValues(alpha: 0.3),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    developer.log('[CaptureMode] → Switching to LIVE_SCAN', name: TAG);
                    ref.read(cameraProvider.notifier).setCaptureMethod(CaptureMethod.live);
                  },
                  child: Center(
                    child: Text(
                      'LIVE SCAN',
                      style: AppTextStyles.hudStatus(theme).copyWith(
                        fontSize: 10,
                        color: state.captureMethod == CaptureMethod.live ? (theme == AppTheme.neonBlack ? Colors.white : Colors.black) : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    developer.log('[CaptureMode] → Switching to STILL_CAP', name: TAG);
                    ref.read(cameraProvider.notifier).setCaptureMethod(CaptureMethod.still);
                  },
                  child: Center(
                    child: Text(
                      'STILL CAP',
                      style: AppTextStyles.hudStatus(theme).copyWith(
                        fontSize: 10,
                        color: state.captureMethod == CaptureMethod.still ? (theme == AppTheme.neonBlack ? Colors.white : Colors.black) : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _registerNewTarget(BuildContext context, WidgetRef ref) async {
    developer.log('[_registerNewTarget] → Entry', name: TAG);
    final cameraState = ref.read(cameraProvider);
    if (cameraState.detectedFaces.isEmpty) {
      developer.log('[_registerNewTarget] → Exit: No faces in frame, aborting', name: TAG);
      return;
    }
    ref.read(cameraProvider.notifier).setMode(AppMode.register);
    await ref.read(cameraProvider.notifier).captureAndProcess(context);
    developer.log('[_registerNewTarget] → Exit', name: TAG);
  }

  void _refineTarget(BuildContext context, WidgetRef ref) async {
    developer.log('[_refineTarget] → Entry', name: TAG);
    final cameraState = ref.read(cameraProvider);
    if (cameraState.matchedFace == null) {
      developer.log('[_refineTarget] → Exit: No matched target to refine', name: TAG);
      return;
    }
    ref.read(cameraProvider.notifier).setMode(AppMode.register, clearMatchedFace: false);
    await ref.read(cameraProvider.notifier).captureAndProcess(
      context,
      initialStatus: 'REFINING PROFILE',
      clearMatchedFace: false,
    );
    developer.log('[_refineTarget] → Exit', name: TAG);
  }

  void _performDeepSearch(BuildContext context, WidgetRef ref, FaceEntity? target) async {
    developer.log('[_performDeepSearch] → Entry: targetName=${target?.name}', name: TAG);
    await ref.read(cameraProvider.notifier).performDeepSearch(context, targetOverride: target);
    developer.log('[_performDeepSearch] → Exit', name: TAG);
  }

  @override
  Widget build(BuildContext context) {
    // developer.log('[build] → Entry', name: TAG);
    final cameraState = ref.watch(cameraProvider);
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);

    return Scaffold(
      backgroundColor: AppColors.getBackground(theme),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Camera Preview
          if (cameraState.isInitialized && cameraState.controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / cameraState.controller!.value.aspectRatio,
                child: CameraPreview(cameraState.controller!),
              ),
            )
          else
            Center(
              child: CircularProgressIndicator(color: accentColor),
            ),

          // HUD Layer (Visuals + Non-interactive overlays)
          const HudOverlay(),

          // Interactive Target Overlays (Banner + Buttons)
          if (cameraState.scanStatus == 'NEW TARGET DETECTED')
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlitchyButton(
                      onPressed: () => _registerNewTarget(context, ref),
                      label: 'REGISTER TARGET?',
                    ),
                    const SizedBox(height: 12),
                    GlitchyButton(
                      onPressed: () {
                         developer.log('[Interaction] → Requesting deep OSINT for unknown face', name: TAG);
                         ref.read(cameraProvider.notifier).queryUnknownFace(context);
                      },
                      label: 'UNRESOLVED_ID: QUERY?',
                    ),
                  ],
                ),
              ),
            ),

          if (cameraState.matchedFace != null && !cameraState.isScanning)
            Positioned(
              bottom: 240,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme == AppTheme.watchDogs
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.getSurface(theme).withValues(alpha: 0.8),
                      border: Border.all(color: accentColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 10)
                      ]
                    ),
                    child: Text(
                      'MATCH: ${cameraState.matchedFace!.name.toUpperCase()}',
                      style: AppTextStyles.hudStatus(theme).copyWith(
                        color: theme == AppTheme.watchDogs ? Colors.black : accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GlitchyButton(
                          onPressed: () => _refineTarget(context, ref),
                          label: 'REFINE PROFILE?',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlitchyButton(
                          onPressed: () => _performDeepSearch(context, ref, cameraState.matchedFace),
                          label: 'DEEP SEARCH',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Scan Progress Overlay
          if (cameraState.isScanning)
            ScanProgressOverlay(
              progress: cameraState.scanProgress,
              status: cameraState.scanStatus,
              result: cameraState.matchedFace != null
                  ? 'MATCH: ${cameraState.matchedFace!.name.toUpperCase()}'
                  : (cameraState.scanStatus == 'DONE' ? 'NO MATCH FOUND' : null),
            ),

          // Top Header & Diagnostics
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'CAPTURE TARGET',
                  style: AppTextStyles.title(theme).copyWith(fontSize: 18, color: accentColor),
                  textAlign: TextAlign.center,
                ),
                if (settings.showDiagnostics) ...[
                  const SizedBox(height: 8),
                  Text(
                    'FPS: ${cameraState.fps.toStringAsFixed(1)} | PROC: ${cameraState.processTime.toInt()}ms',
                    style: AppTextStyles.hudStatus(theme).copyWith(fontSize: 10, color: accentColor.withValues(alpha: 0.7)),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  width: 200,
                  color: accentColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // Top Horizontal Controls - Clean Icon-based UX
          Positioned(
            top: 105,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TidyIconButton(
                  icon: cameraState.mode == AppMode.match ? Icons.person_search : Icons.person_add,
                  label: cameraState.mode == AppMode.match ? 'MATCH' : 'ENROLL',
                  onPressed: () {
                    developer.log('[ModeControl] → Toggling app mode', name: TAG);
                    ref.read(cameraProvider.notifier).toggleMode();
                  },
                  isActive: false,
                ),
                const SizedBox(width: 16),
                _TidyIconButton(
                  icon: Icons.memory,
                  label: cameraState.modelType == FaceModel.faceNet ? 'FACENET' : 'MOBILE',
                  onPressed: () {
                    developer.log('[ModelControl] → Toggling TFLite backend', name: TAG);
                    ref.read(cameraProvider.notifier).toggleModel();
                  },
                  isActive: false,
                ),
                const SizedBox(width: 16),
                _TidyIconButton(
                  icon: cameraState.isPoiTrackerActive ? Icons.radar : Icons.radio_button_off,
                  label: 'POI',
                  onPressed: () {
                    developer.log('[TrackerControl] → Toggling automated POI response', name: TAG);
                    ref.read(cameraProvider.notifier).togglePoiTracker();
                    HapticFeedback.mediumImpact();
                  },
                  isActive: cameraState.isPoiTrackerActive,
                  activeColor: Colors.redAccent,
                ),
              ],
            ),
          ),

          // Mode Selection & Bottom Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCaptureMethodSlider(cameraState, theme),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _IconButton(
                        icon: Icons.history,
                        onPressed: () {
                           developer.log('[Interaction] → History access requested', name: TAG);
                        },
                      ),
                      _IconButton(
                        icon: Icons.image,
                        onPressed: () {
                          developer.log('[Interaction] → File picker requested', name: TAG);
                          ref.read(cameraProvider.notifier).pickAndProcess(context);
                        },
                      ),
                      _ShutterButton(
                        onPressed: () {
                          developer.log('[HardwareControl] → Shutter triggered', name: TAG);
                          ref.read(cameraProvider.notifier).captureAndProcess(context);
                        },
                      ),
                      _IconButton(
                        icon: Icons.flip_camera_android,
                        onPressed: () {
                          developer.log('[HardwareControl] → Switching sensor lens', name: TAG);
                          ref.read(cameraProvider.notifier).toggleCamera();
                        },
                      ),
                      _IconButton(
                        icon: Icons.settings,
                        onPressed: () {
                           developer.log('[Interaction] → Secondary settings requested', name: TAG);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: 45,
            right: 15,
            child: IconButton(
              icon: Icon(Icons.close, color: accentColor, size: 28),
              onPressed: () {
                developer.log('[Interaction] → Terminal screen closure', name: TAG);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TidyIconButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;

  const _TidyIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final baseAccent = AppColors.getAccent(theme);
    final color = isActive ? (activeColor ?? baseAccent) : baseAccent;

    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.hudStatus(theme).copyWith(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoiToggle extends ConsumerWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _PoiToggle({required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.redAccent.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.1),
          border: Border.all(color: isActive ? Colors.redAccent : accentColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute icon and text
          children: [
            Icon(
              isActive ? Icons.radar : Icons.radio_button_off,
              color: isActive ? Colors.redAccent : accentColor,
              size: 14,
            ),
            Text(
              'POI TRACKER',
              style: AppTextStyles.hudStatus(theme).copyWith(
                fontSize: 9,
                color: isActive ? Colors.redAccent : accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends ConsumerWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final accentColor = AppColors.getAccent(settings.theme);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: accentColor, width: 1),
        color: accentColor.withValues(alpha: 0.1),
      ),
      child: IconButton(
        icon: Icon(icon, color: accentColor),
        onPressed: onPressed,
      ),
    );
  }
}

class _ShutterButton extends ConsumerWidget {
  final VoidCallback onPressed;

  const _ShutterButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final accentColor = AppColors.getAccent(settings.theme);
    final isHack = settings.shutterStyle == ShutterStyle.hack;
    final cameraState = ref.watch(cameraProvider);
    final isRegister = cameraState.mode == AppMode.register;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70, // Reduced from 80
        height: 70, // Reduced from 80
        decoration: BoxDecoration(
          shape: isHack ? BoxShape.rectangle : BoxShape.circle,
          border: Border.all(color: accentColor, width: 3),
          boxShadow: [
            if (settings.theme == AppTheme.neonBlack)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: isHack
              ? Text(
                  isRegister ? 'ENROLL' : 'HACK',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                )
              : Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                ),
        ),
      ),
    );
  }
}
