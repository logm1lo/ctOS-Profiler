import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/tflite_service.dart';
import '../shared/neon_button.dart';
import 'camera_controller_provider.dart';
import 'widgets/hud_overlay.dart';
import 'widgets/scan_progress_overlay.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).initialize();
    });
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
                  onTap: () => ref.read(cameraProvider.notifier).setCaptureMethod(CaptureMethod.live),
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
                  onTap: () => ref.read(cameraProvider.notifier).setCaptureMethod(CaptureMethod.still),
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

  @override
  Widget build(BuildContext context) {
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

          // HUD Layer
          const HudOverlay(),

          // Scan Progress Overlay
          if (cameraState.isScanning)
            ScanProgressOverlay(
              progress: cameraState.scanProgress,
              status: cameraState.scanStatus,
              result: cameraState.matchedFace != null
                  ? 'MATCH: ${cameraState.matchedFace!.name.toUpperCase()}'
                  : (cameraState.scanStatus == 'DONE' ? 'NO MATCH FOUND' : null),
            ),

          // Top Controls (Mode & Model)
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: cameraState.mode == AppMode.match ? 'MODE: MATCH' : 'MODE: REG',
                    onPressed: () => ref.read(cameraProvider.notifier).toggleMode(),
                    isSecondary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeonButton(
                    label: cameraState.modelType == FaceModel.faceNet ? 'MODEL: FACENET' : 'MODEL: MOBILE',
                    onPressed: () => ref.read(cameraProvider.notifier).toggleModel(),
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ),

          // Mode Selection & Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCaptureMethodSlider(cameraState, theme),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _IconButton(
                      icon: Icons.image,
                      onPressed: () {
                        ref.read(cameraProvider.notifier).pickAndProcess(context);
                      },
                    ),
                    _ShutterButton(
                      onPressed: () {
                        ref.read(cameraProvider.notifier).captureAndProcess(context);
                      },
                    ),
                    _IconButton(
                      icon: Icons.flip_camera_android,
                      onPressed: () {
                        ref.read(cameraProvider.notifier).toggleCamera();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: accentColor, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
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

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: isHack ? BoxShape.rectangle : BoxShape.circle,
          border: Border.all(color: accentColor, width: 4),
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
                  'HACK',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 2,
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
