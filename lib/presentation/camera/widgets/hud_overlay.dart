import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../camera_controller_provider.dart';
import 'face_bbox_painter.dart';
import 'face_target_guide.dart';
import 'scanline_painter.dart';
import 'glitch_painter.dart';
import 'glitchy_button.dart';

class HudOverlay extends ConsumerStatefulWidget {
  const HudOverlay({super.key});

  @override
  ConsumerState<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends ConsumerState<HudOverlay> with TickerProviderStateMixin {
  late AnimationController _scanlineController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanlineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);

    return Stack(
      children: [
        // Layer 1: Glitch effect
        AnimatedBuilder(
          animation: _scanlineController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: GlitchPainter(progress: _scanlineController.value),
            );
          },
        ),

        // Layer 2: Scanline
        AnimatedBuilder(
          animation: _scanlineController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: ScanlinePainter(
                progress: _scanlineController.value,
                color: AppColors.getScanLine(theme),
              ),
            );
          },
        ),

        // Layer 3: Face Target HUD
        FaceTargetGuide(animation: _pulseController),

        // Register Target Button (Center Screen)
        if (cameraState.scanStatus == 'NEW TARGET DETECTED')
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 200),
              child: GlitchyButton(
                onPressed: () => _registerNewTarget(context, ref),
                label: 'REGISTER TARGET?',
              ),
            ),
          ),

        // Match Info (Center Screen)
        if (cameraState.matchedFace != null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: (theme == AppTheme.neonBlack ? Colors.black : Colors.white).withValues(alpha: 0.7),
                border: Border.all(color: accentColor, width: 1.5),
              ),
              child: Text(
                'MATCH: ${cameraState.matchedFace!.name.toUpperCase()}',
                style: AppTextStyles.hudStatus(theme).copyWith(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

        // Real-time Bounding Boxes
        if (cameraState.isInitialized && cameraState.detectedFaces.isNotEmpty)
          CustomPaint(
            size: Size.infinite,
            painter: FaceBBoxPainter(
              cameraState.detectedFaces,
              Size(
                cameraState.controller!.value.previewSize!.height,
                cameraState.controller!.value.previewSize!.width,
              ),
              matchedFace: cameraState.matchedFace,
              isFrontCamera: cameraState.isFrontCamera,
              accentColor: accentColor,
              privacyMode: settings.privacyMode,
            ),
          ),

        // Layer 4: Status Text
        Positioned(
          bottom: 120,
          left: 20,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('LIVE FEED', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor)),
            ],
          ),
        ),
        Positioned(
          bottom: 120,
          right: 20,
          child: Row(
            children: [
              Text('REC', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.red)),
              const SizedBox(width: 4),
              const Icon(Icons.circle, color: Colors.red, size: 12),
            ],
          ),
        ),

        // Top Bar
        Positioned(
          top: 50,
          left: 60,
          right: 60,
          child: Column(
            children: [
              Text(
                'CAPTURE TARGET',
                style: AppTextStyles.title(theme).copyWith(fontSize: 18, color: accentColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                width: double.infinity,
                color: accentColor.withValues(alpha: 0.5),
              ),
              if (settings.showDiagnostics) ...[
                const SizedBox(height: 8),
                Text(
                  'FPS: ${cameraState.fps.toStringAsFixed(1)} | PROC: ${cameraState.processTime.toInt()}ms',
                  style: AppTextStyles.hudStatus(theme).copyWith(fontSize: 10, color: accentColor.withValues(alpha: 0.7)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _registerNewTarget(BuildContext context, WidgetRef ref) async {
    final cameraState = ref.read(cameraProvider);
    if (cameraState.detectedFaces.isEmpty) return;

    // Set mode to register before capturing
    ref.read(cameraProvider.notifier).setMode(AppMode.register);

    // To register, we need a high-quality capture
    await ref.read(cameraProvider.notifier).captureAndProcess(context);
  }
}
