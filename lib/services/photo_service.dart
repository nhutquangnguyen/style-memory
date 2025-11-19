import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

class PhotoService {
  // Maximum dimensions for photos to optimize storage
  static const int maxWidth = 1024;
  static const int maxHeight = 1024;
  static const int quality = 85;

  /// Compresses and resizes an image file
  static Future<Uint8List> compressImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    return compressImageBytes(imageBytes);
  }

  /// Compresses and resizes image bytes
  static Future<Uint8List> compressImageBytes(Uint8List imageBytes) async {
    // Decode the image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Calculate new dimensions while maintaining aspect ratio
    int newWidth = image.width;
    int newHeight = image.height;

    if (newWidth > maxWidth || newHeight > maxHeight) {
      double aspectRatio = newWidth / newHeight;

      if (newWidth > newHeight) {
        newWidth = maxWidth;
        newHeight = (maxWidth / aspectRatio).round();
      } else {
        newHeight = maxHeight;
        newWidth = (maxHeight * aspectRatio).round();
      }
    }

    // Resize the image if needed
    if (newWidth != image.width || newHeight != image.height) {
      image = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    // Encode as JPEG with compression
    final compressedBytes = img.encodeJpg(image, quality: quality);

    return Uint8List.fromList(compressedBytes);
  }

  /// Gets the file size of compressed image
  static int getImageSize(Uint8List imageBytes) {
    return imageBytes.length;
  }

  /// Validates if the file is a valid image
  static bool isValidImage(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'bmp', 'gif'].contains(extension);
  }

  /// Gets image dimensions
  static Future<Map<String, int>> getImageDimensions(Uint8List imageBytes) async {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return {
      'width': image.width,
      'height': image.height,
    };
  }

  /// Creates a thumbnail from an image
  static Future<Uint8List> createThumbnail(
    Uint8List imageBytes, {
    int thumbnailSize = 200,
  }) async {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Create square thumbnail
    final thumbnail = img.copyResizeCropSquare(image, size: thumbnailSize);

    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));
  }
}