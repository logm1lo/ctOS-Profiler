import 'package:flutter/material.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart' as fdt;
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/entities/face_entity.dart';

class FaceBBoxPainter extends CustomPainter {
  final List<fdt.Face> faces;
  final Size absoluteImageSize;
  final FaceEntity? matchedFace;
  final bool isFrontCamera;
  final Color? accentColor;
  final bool privacyMode;

  FaceBBoxPainter(
    this.faces,
    this.absoluteImageSize, {
    this.matchedFace,
    this.isFrontCamera = true,
    this.accentColor,
    this.privacyMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final activeColor = accentColor ?? AppColors.cyanAccent;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = activeColor;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = activeColor;

    final blurPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (final face in faces) {
      final rect = _scaleRect(face.boundingBox, size, absoluteImageSize);

      if (privacyMode && matchedFace == null) {
        canvas.drawRect(rect, blurPaint);
      }

      canvas.drawRect(rect, paint);

      // Draw corners with neon glow
      _drawNeonCorners(canvas, rect, activeColor);

      // Draw mesh if available
      if (face.mesh != null) {
        _drawFaceMesh(canvas, face.mesh!, size, absoluteImageSize, activeColor);
      } else {
        // Draw landmarks as backup
        for (final landmark in face.landmarks.values) {
          final pos = _scalePoint(landmark, size, absoluteImageSize);
          canvas.drawCircle(pos, 2, dotPaint);
        }
      }
    }
  }

  void _drawFaceMesh(Canvas canvas, fdt.FaceMesh mesh, Size size, Size absoluteImageSize, Color color) {
    final meshPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = color.withOpacity(0.4);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.6);

    // Scaling all points first
    final List<Offset> points = mesh.points.map((p) => _scalePoint(p, size, absoluteImageSize)).toList();

    // Draw dots
    for (var point in points) {
      canvas.drawCircle(point, 1, dotPaint);
    }

    // Draw some connections for a wireframe look
    // MediaPipe face mesh has a specific topology.
    // To keep it performant and look "Watch Dogs" / ctOS style,
    // we'll draw lines between some key points and around the eyes/mouth.

    if (points.length >= 468) {
      // 1. Draw the face outline (silhouette)
      final outlineIndices = [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 10];
      _drawPath(canvas, points, outlineIndices, meshPaint, closePath: true);

      // 2. Draw Left Eye
      final leftEyeIndices = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246, 33];
      _drawPath(canvas, points, leftEyeIndices, meshPaint);

      // 3. Draw Right Eye
      final rightEyeIndices = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398, 362];
      _drawPath(canvas, points, rightEyeIndices, meshPaint);

      // 4. Draw Lips
      final lipIndices = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 308, 324, 318, 402, 317, 14, 87, 178, 88, 95, 61];
      _drawPath(canvas, points, lipIndices, meshPaint);

      // 5. Draw some "hacker-style" connection lines across the face for that wireframe look
      final crossLines = [
        [10, 151, 9, 8, 168, 6, 197, 195, 5, 4, 1, 19, 94, 2, 164, 0, 11, 12, 13, 14, 15, 16, 17, 18, 200, 199, 175, 152], // Vertical center line
        [234, 93, 132, 58, 172, 136, 150, 149, 176, 148, 152, 377, 400, 378, 379, 365, 397, 288, 361, 323, 454], // Jaw/Lower cheek line
      ];

      for (var line in crossLines) {
        _drawPath(canvas, points, line, meshPaint);
      }

      // 6. Draw Irises (requires FaceDetectionMode.full)
      if (points.length >= 478) {
        final leftIrisIndices = [468, 469, 470, 471, 472];
        final rightIrisIndices = [473, 474, 475, 476, 477];

        final irisPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withOpacity(0.8);

        for (int i in [...leftIrisIndices, ...rightIrisIndices]) {
           canvas.drawCircle(points[i], 1.5, irisPaint);
        }
      }
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points, List<int> indices, Paint paint, {bool closePath = false}) {
    final path = Path();
    bool first = true;
    for (int index in indices) {
      if (index < points.length) {
        if (first) {
          path.moveTo(points[index].dx, points[index].dy);
          first = false;
        } else {
          path.lineTo(points[index].dx, points[index].dy);
        }
      }
    }
    if (closePath) path.close();
    canvas.drawPath(path, paint);
  }

  void _drawNeonCorners(Canvas canvas, Rect rect, Color color) {
    final neonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const len = 20.0;
    // Top Left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(len, 0), neonPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, len), neonPaint);
    // Top Right
    canvas.drawLine(rect.topRight, rect.topRight - const Offset(len, 0), neonPaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, len), neonPaint);
    // Bottom Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(len, 0), neonPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft - const Offset(0, len), neonPaint);
    // Bottom Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight - const Offset(len, 0), neonPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight - const Offset(0, len), neonPaint);
  }

  Rect _scaleRect(fdt.BoundingBox bbox, Size size, Size absoluteImageSize) {
    // The camera preview is often letterboxed or pillarboxed.
    // We need to account for how the 'aspectRatio' logic in CameraPreview works.

    double scaleX, scaleY;
    double offsetX = 0;
    double offsetY = 0;

    final double screenRatio = size.width / size.height;
    final double imageRatio = absoluteImageSize.width / absoluteImageSize.height;

    if (screenRatio > imageRatio) {
      // Screen is wider than image (pillarboxed vertically or scaled to fit width)
      scaleX = size.width / absoluteImageSize.width;
      scaleY = scaleX;
      offsetY = (size.height - absoluteImageSize.height * scaleY) / 2;
    } else {
      // Screen is taller than image (letterboxed horizontally or scaled to fit height)
      scaleY = size.height / absoluteImageSize.height;
      scaleX = scaleY;
      offsetX = (size.width - absoluteImageSize.width * scaleX) / 2;
    }

    double width = bbox.width * scaleX;
    double height = bbox.height * scaleY;
    double left = bbox.topLeft.x * scaleX + offsetX;
    double top = bbox.topLeft.y * scaleY + offsetY;

    if (isFrontCamera) {
      left = size.width - left - width;
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  Offset _scalePoint(fdt.Point point, Size size, Size absoluteImageSize) {
    final double screenRatio = size.width / size.height;
    final double imageRatio = absoluteImageSize.width / absoluteImageSize.height;

    double scale, offsetX = 0, offsetY = 0;
    if (screenRatio > imageRatio) {
      scale = size.width / absoluteImageSize.width;
      offsetY = (size.height - absoluteImageSize.height * scale) / 2;
    } else {
      scale = size.height / absoluteImageSize.height;
      offsetX = (size.width - absoluteImageSize.width * scale) / 2;
    }

    double x = point.x * scale + offsetX;
    double y = point.y * scale + offsetY;

    if (isFrontCamera) {
      x = size.width - x;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(FaceBBoxPainter oldDelegate) => true;
}

