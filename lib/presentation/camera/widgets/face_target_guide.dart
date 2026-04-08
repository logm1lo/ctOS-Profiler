import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/settings_provider.dart';

class FaceTargetGuide extends ConsumerWidget {
  final Animation<double> animation;

  const FaceTargetGuide({super.key, required this.animation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.theme;
    final accentColor = AppColors.getAccent(theme);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            Center(
              child: CustomPaint(
                size: const Size(280, 380),
                painter: TargetOvalPainter(
                  opacity: animation.value,
                  color: accentColor,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'POSITION FACE HERE',
                  style: AppTextStyles.hudStatus(theme).copyWith(
                    color: accentColor.withOpacity(animation.value),
                  ),
                ),
              ),
            ),
            // Corners
            _buildCorner(Alignment.topLeft, 0, accentColor),
            _buildCorner(Alignment.topRight, pi / 2, accentColor),
            _buildCorner(Alignment.bottomLeft, -pi / 2, accentColor),
            _buildCorner(Alignment.bottomRight, pi, accentColor),
          ],
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment, double angle, Color color) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Transform.rotate(
          angle: angle,
          child: CustomPaint(
            size: const Size(40, 40),
            painter: CornerPainter(opacity: animation.value, color: color),
          ),
        ),
      ),
    );
  }
}

class TargetOvalPainter extends CustomPainter {
  final double opacity;
  final Color color;

  TargetOvalPainter({required this.opacity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Dashed oval
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    _drawDashedOval(canvas, rect, paint);
  }

  void _drawDashedOval(Canvas canvas, Rect rect, Paint paint) {
    const double dashWidth = 10;
    const double dashSpace = 5;
    double startAngle = 0;
    while (startAngle < 2 * pi) {
      canvas.drawArc(rect, startAngle, dashWidth / 100, false, paint);
      startAngle += (dashWidth + dashSpace) / 100;
    }
  }

  @override
  bool shouldRepaint(covariant TargetOvalPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}

class CornerPainter extends CustomPainter {
  final double opacity;
  final Color color;

  CornerPainter({required this.opacity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);

    // Glow effect
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CornerPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}
