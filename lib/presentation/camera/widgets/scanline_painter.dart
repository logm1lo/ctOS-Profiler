import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class ScanlinePainter extends CustomPainter {
  final double progress;
  final Color? color;
  final Random _random = Random();

  ScanlinePainter({required this.progress, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = color ?? AppColors.cyanAccent;
    final paint = Paint()
      ..color = baseColor.withOpacity(0.4)
      ..strokeWidth = 2.0;

    // Main scanning line
    double y = size.height * progress;

    // Add some "noise" to the main line
    if (_random.nextDouble() > 0.95) {
       // Occasional glitch offset
       y += _random.nextDouble() * 10 - 5;
    }

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // Draw multiple trailing lines with fading opacity
    for (int i = 1; i <= 8; i++) {
      double trailingY = (y - (i * 15)) % size.height;
      double opacity = (0.2 / i) * (1.0 + _random.nextDouble() * 0.2);
      paint.color = baseColor.withOpacity(opacity.clamp(0.0, 1.0));
      paint.strokeWidth = 1.0;
      canvas.drawLine(Offset(0, trailingY), Offset(size.width, trailingY), paint);
    }

    // Occasional horizontal static bursts
    if (_random.nextDouble() > 0.9) {
      final burstY = _random.nextDouble() * size.height;
      final burstHeight = _random.nextDouble() * 2;
      final burstOpacity = _random.nextDouble() * 0.2;
      canvas.drawRect(
        Rect.fromLTWH(0, burstY, size.width, burstHeight),
        Paint()..color = baseColor.withOpacity(burstOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScanlinePainter oldDelegate) {
    // We want it to repaint frequently for the noise/glitch effect
    return true;
  }
}
