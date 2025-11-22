import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class WatermarkService {
  /// Add watermark to image bytes and return the watermarked image bytes
  static Future<Uint8List> addWatermarkToImage(Uint8List imageBytes, {
    String watermarkText = 'StyleMemory',
    double opacity = 0.75, // More visible and bold default opacity
    WatermarkPosition position = WatermarkPosition.bottomLeft,
    double fontSize = 32, // Larger for better visibility
    Color textColor = Colors.white,
  }) async {
    try {
      // Decode the original image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate font size as percentage of image height for consistent visual height
      final imageHeight = originalImage.height;
      final responsiveFontSize = (imageHeight * 0.06).round().clamp(12, 80);

      // Draw watermark text directly on the original image (no compositing needed)
      _drawWatermarkDirectly(
        originalImage,
        watermarkText,
        responsiveFontSize,
        textColor,
        opacity,
        position,
      );

      // Encode back to JPEG
      final watermarkedBytes = Uint8List.fromList(img.encodeJpg(originalImage, quality: 85));

      return watermarkedBytes;
    } catch (e) {
      // Return original image if watermarking fails
      debugPrint('Failed to add watermark: $e');
      return imageBytes;
    }
  }

  /// Draw watermark text directly on the original image to avoid transparency issues
  static void _drawWatermarkDirectly(
    img.Image originalImage,
    String text,
    int fontSize,
    Color color,
    double opacity,
    WatermarkPosition position,
  ) {
    // Handle multi-line text (for salon info)
    final lines = text.split('\n');
    final lineHeight = (fontSize * 1.1).round();
    final maxLineWidth = lines.map((line) => (line.length * fontSize * 0.6).round()).reduce((a, b) => a > b ? a : b);

    // Calculate total dimensions for multi-line text
    final totalWidth = maxLineWidth;
    final totalHeight = lines.length * lineHeight;

    // Calculate position for watermark
    final (baseX, baseY) = _calculateWatermarkPosition(
      position,
      originalImage.width,
      originalImage.height,
      totalWidth,
      totalHeight,
    );

    // Draw each line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final y = baseY + (i * lineHeight);

      // Draw shadow for each line
      img.drawString(
        originalImage,
        line,
        font: img.arial24,
        x: baseX + 2,
        y: y + 2,
        color: img.ColorRgba8(0, 0, 0, (120 * opacity).round()), // More visible shadow
      );

      // Draw main text for each line
      img.drawString(
        originalImage,
        line,
        font: img.arial24,
        x: baseX,
        y: y,
        color: img.ColorRgba8(255, 255, 255, (255 * opacity).round()), // Bold white text
      );
    }
  }

  /// Calculate watermark position based on the specified position
  static (int x, int y) _calculateWatermarkPosition(
    WatermarkPosition position,
    int imageWidth,
    int imageHeight,
    int watermarkWidth,
    int watermarkHeight,
  ) {
    const padding = 20; // Padding from edges

    switch (position) {
      case WatermarkPosition.topLeft:
        return (padding, padding);
      case WatermarkPosition.topRight:
        return (imageWidth - watermarkWidth - padding, padding);
      case WatermarkPosition.bottomLeft:
        return (padding, imageHeight - watermarkHeight - padding);
      case WatermarkPosition.bottomRight:
        return (
          imageWidth - watermarkWidth - padding,
          imageHeight - watermarkHeight - padding,
        );
      case WatermarkPosition.center:
        return (
          (imageWidth - watermarkWidth) ~/ 2,
          (imageHeight - watermarkHeight) ~/ 2,
        );
    }
  }

  /// Add watermark to a file and save to a new file
  static Future<File> addWatermarkToFile(
    File sourceFile,
    File outputFile, {
    String watermarkText = 'StyleMemory',
    double opacity = 0.75, // More visible and bold default opacity
    WatermarkPosition position = WatermarkPosition.bottomLeft,
    double fontSize = 32, // Larger for better visibility
    Color textColor = Colors.white,
  }) async {
    final imageBytes = await sourceFile.readAsBytes();
    final watermarkedBytes = await addWatermarkToImage(
      imageBytes,
      watermarkText: watermarkText,
      opacity: opacity,
      position: position,
      fontSize: fontSize,
      textColor: textColor,
    );

    await outputFile.writeAsBytes(watermarkedBytes);
    return outputFile;
  }

}

/// Watermark position options
enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}