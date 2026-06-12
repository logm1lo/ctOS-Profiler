import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/entities/face_entity.dart';
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
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _scanlineController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: GlitchPainter(progress: _scanlineController.value),
              );
            },
          ),
        ),

        // Layer 2: Scanline
        IgnorePointer(
          child: AnimatedBuilder(
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
        ),

        // Layer 3: Face Target HUD
        IgnorePointer(child: FaceTargetGuide(animation: _pulseController)),

        // Real-time Bounding Boxes
        if (cameraState.isInitialized && cameraState.detectedFaces.isNotEmpty)
          IgnorePointer(
            child: CustomPaint(
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
                isPoiTrackerActive: cameraState.isPoiTrackerActive,
              ),
            ),
          ),

        // Layer 4: Consolidated Status Bar (Above Slider)
        Positioned(
          bottom: 140,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('LIVE FEED', style: AppTextStyles.hudStatus(theme).copyWith(color: accentColor, fontSize: 9)),
                  if (cameraState.isPoiTrackerActive) ...[
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: accentColor.withValues(alpha: 0.3)),
                    const SizedBox(width: 8),
                    Text('POI_ACTIVE', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
              Row(
                children: [
                  Text('REC', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.red, fontSize: 9)),
                  const SizedBox(width: 4),
                  const Icon(Icons.circle, color: Colors.red, size: 6),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
