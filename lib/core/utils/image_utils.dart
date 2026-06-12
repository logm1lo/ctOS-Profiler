import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  static const String TAG = "ImageUtils";

  static img.Image convertYUV420ToImage(CameraImage image) {
    // developer.log('[convertYUV420ToImage] → Entry: w=${image.width}, h=${image.height}', name: TAG);
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

        int r = (yp + (vp - 128) * 1.402).round().clamp(0, 255);
        int g = (yp - (up - 128) * 0.344136 - (vp - 128) * 0.714136).round().clamp(0, 255);
        int b = (yp + (up - 128) * 1.772).round().clamp(0, 255);

        outImg.setPixelRgb(x, y, r, g, b);
      }
    }
    return outImg;
  }

  static Uint8List convertYUV420ToNv21(CameraImage image) {
    // developer.log('[convertYUV420ToNv21] → Entry', name: TAG);
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvSize = width * height ~/ 2;

    final nv21 = Uint8List(ySize + uvSize);
    nv21.setRange(0, ySize, image.planes[0].bytes);

    final vPlane = image.planes[2].bytes;
    final uPlane = image.planes[1].bytes;
    
    int compositeIndex = ySize;
    for (int i = 0; i < uPlane.length; i += image.planes[1].bytesPerPixel!) {
      nv21[compositeIndex++] = vPlane[i];
      nv21[compositeIndex++] = uPlane[i];
    }

    return nv21;
  }

  static img.Image cropFace(img.Image image, double x, double y, double width, double height) {
    developer.log('[cropFace] → Entry: bounds=($x, $y, $width, $height)', name: TAG);
    final result = img.copyCrop(image, x: x.toInt(), y: y.toInt(), width: width.toInt(), height: height.toInt());
    developer.log('[cropFace] → Exit: Created crop of size ${result.width}x${result.height}', name: TAG);
    return result;
  }

  static img.Image resize(img.Image image, int width, int height) {
    developer.log('[resize] → Entry: target=${width}x$height', name: TAG);
    final result = img.copyResize(image, width: width, height: height);
    developer.log('[resize] → Exit: Completed successfully', name: TAG);
    return result;
  }

  static Float32List preprocess(img.Image image, int inputSize) {
    developer.log('[preprocess] → Entry: inputSize=$inputSize', name: TAG);
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
    developer.log('[preprocess] → Exit: Preprocessing complete', name: TAG);
    return input;
  }
}
