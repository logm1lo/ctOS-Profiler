import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class GlitchPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  GlitchPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (_random.nextDouble() > 0.1) return; // Only draw glitch occasionally

    final paint = Paint()..style = PaintingStyle.fill;

    int numGlitches = _random.nextInt(5) + 2;

    for (int i = 0; i < numGlitches; i++) {
      final glitchWidth = _random.nextDouble() * size.width * 0.4;
      final glitchHeight = _random.nextDouble() * 10 + 2;
      final x = _random.nextDouble() * (size.width - glitchWidth);
      final y = _random.nextDouble() * size.height;

      // Randomly choose between cyan, white, or transparent
      final colorRoll = _random.nextDouble();
      if (colorRoll > 0.7) {
        paint.color = AppColors.cyanAccent.withValues(alpha: 0.3);
      } else if (colorRoll > 0.4) {
        paint.color = Colors.white.withValues(alpha: 0.1);
      } else {
        paint.color = Colors.black.withValues(alpha: 0.2);
      }

      canvas.drawRect(Rect.fromLTWH(x, y, glitchWidth, glitchHeight), paint);

      // Optional: draw a second "offset" version for RGB split feel
      if (_random.nextBool()) {
        paint.color = Colors.redAccent.withValues(alpha: 0.1);
        canvas.drawRect(Rect.fromLTWH(x + 2, y + 1, glitchWidth, glitchHeight), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GlitchPainter oldDelegate) => true;
}
