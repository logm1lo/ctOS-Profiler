import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  static img.Image convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final outImg = img.Image(width: width, height: height, numChannels: 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x >> 1) + uvRowStride * (y >> 1);
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        // Optimized YUV to RGB conversion
        int r = (yp + (vp - 128) * 1.402).round().clamp(0, 255);
        int g = (yp - (up - 128) * 0.344136 - (vp - 128) * 0.714136).round().clamp(0, 255);
        int b = (yp + (up - 128) * 1.772).round().clamp(0, 255);

        outImg.setPixelRgb(x, y, r, g, b);
      }
    }
    return outImg;
  }

  static Uint8List convertYUV420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvSize = width * height ~/ 2;

    final nv21 = Uint8List(ySize + uvSize);

    // Y plane
    nv21.setRange(0, ySize, image.planes[0].bytes);

    // UV plane
    final vPlane = image.planes[2].bytes;
    final uPlane = image.planes[1].bytes;
    
    // In NV21, UV data is interleaved as V, U, V, U...
    // This is a simplified version and might need adjustment based on strides
    int compositeIndex = ySize;
    for (int i = 0; i < uPlane.length; i += image.planes[1].bytesPerPixel!) {
      nv21[compositeIndex++] = vPlane[i];
      nv21[compositeIndex++] = uPlane[i];
    }

    return nv21;
  }

  static img.Image cropFace(img.Image image, double x, double y, double width, double height) {
    return img.copyCrop(image, x: x.toInt(), y: y.toInt(), width: width.toInt(), height: height.toInt());
  }

  static img.Image resize(img.Image image, int width, int height) {
    return img.copyResize(image, width: width, height: height);
  }

  static Float32List preprocess(img.Image image, int inputSize) {
    var input = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(input.buffer);
    int pixelIndex = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return input;
  }
}
