import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageCompressor {
  /// Maximum allowed size in bytes (10 KB = 10240 bytes)
  static const int maxBytes = 10 * 1024;

  /// Crops [imageBytes] according to normalized coordinates (0.0 to 1.0)
  /// and compresses the result to <= 10 KB.
  static Uint8List cropAndCompress({
    required Uint8List imageBytes,
    required double normX,
    required double normY,
    required double normWidth,
    required double normHeight,
  }) {
    img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) return compressToMax10Kb(imageBytes);

    // Calculate pixel coordinates
    int x = (normX * decoded.width).round().clamp(0, decoded.width - 1);
    int y = (normY * decoded.height).round().clamp(0, decoded.height - 1);
    int w = (normWidth * decoded.width).round().clamp(1, decoded.width - x);
    int h = (normHeight * decoded.height).round().clamp(1, decoded.height - y);

    img.Image cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    return _compressImage(cropped);
  }

  /// Compresses [imageBytes] so that the resulting JPEG is <= 10 KB.
  static Uint8List compressToMax10Kb(Uint8List imageBytes) {
    img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;
    return _compressImage(decoded);
  }

  static Uint8List _compressImage(img.Image inputImage) {
    img.Image current = inputImage;

    // A profile picture avatar under 10KB typically needs to be around 180x180 - 240x240 px
    const int maxInitialDimension = 240;
    if (current.width > maxInitialDimension || current.height > maxInitialDimension) {
      int targetW = current.width;
      int targetH = current.height;
      if (targetW > targetH) {
        targetH = (targetH * maxInitialDimension / targetW).round();
        targetW = maxInitialDimension;
      } else {
        targetW = (targetW * maxInitialDimension / targetH).round();
        targetH = maxInitialDimension;
      }
      current = img.copyResize(current, width: maxW(targetW), height: maxW(targetH));
    }

    int quality = 85;
    List<int> encoded = img.encodeJpg(current, quality: quality);

    // Progressively reduce quality
    while (encoded.length > maxBytes && quality > 20) {
      quality -= 10;
      encoded = img.encodeJpg(current, quality: quality);
    }

    // If still over 10 KB, progressively scale down dimensions
    while (encoded.length > maxBytes && current.width > 60 && current.height > 60) {
      final newW = (current.width * 0.82).round();
      final newH = (current.height * 0.82).round();
      current = img.copyResize(current, width: max(newW, 48), height: max(newH, 48));
      encoded = img.encodeJpg(current, quality: max(quality, 45));
    }

    debugPrint('Profile photo compressed to ${encoded.length} bytes (<= 10KB: ${encoded.length <= maxBytes})');
    return Uint8List.fromList(encoded);
  }

  static int maxW(int val) => val < 1 ? 1 : val;
}
