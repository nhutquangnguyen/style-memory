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

      // Calculate font size as percentage of image width for consistent screen appearance
      // This ensures watermark looks the same size when viewed on phone screens regardless of image resolution
      final fontSizeByWidth = (originalImage.width * 0.04).round();

      // Draw watermark text directly on the original image (no compositing needed)
      _drawWatermarkDirectly(
        originalImage,
        watermarkText,
        fontSizeByWidth,
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
    // Calculate scaling factor based on desired fontSize vs arial24 base size
    const baseFontSize = 24; // img.arial24 is 24px
    final scaleFactor = fontSize / baseFontSize;

    // Handle multi-line text (for salon info)
    final lines = text.split('\n');
    final baseLineHeight = (baseFontSize * 1.1).round();
    final baseCharWidth = (baseFontSize * 0.6).round();
    final baseMaxLineWidth = lines.map((line) => line.length * baseCharWidth).reduce((a, b) => a > b ? a : b);

    // Calculate dimensions at base size
    final baseWidth = baseMaxLineWidth;
    final baseHeight = lines.length * baseLineHeight;

    // Create a temporary canvas for the watermark at base size with proper transparency
    final watermarkCanvas = img.Image(
      width: baseWidth + 10, // Add padding
      height: baseHeight + 10,
      numChannels: 4, // RGBA for transparency support
    );

    // Fill with transparent pixels
    img.fill(watermarkCanvas, color: img.ColorRgba8(0, 0, 0, 0));

    // Draw text on the temporary canvas at base size
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final y = 5 + (i * baseLineHeight); // 5px padding

      // Draw shadow
      img.drawString(
        watermarkCanvas,
        line,
        font: img.arial24,
        x: 7, // 5px padding + 2px shadow offset
        y: y + 2,
        color: img.ColorRgba8(0, 0, 0, (120 * opacity).round()),
      );

      // Draw main text
      img.drawString(
        watermarkCanvas,
        line,
        font: img.arial24,
        x: 5, // 5px padding
        y: y,
        color: img.ColorRgba8(255, 255, 255, (255 * opacity).round()),
      );
    }

    // Scale the watermark canvas if needed while preserving transparency
    final scaledWatermark = scaleFactor != 1.0
        ? img.copyResize(
            watermarkCanvas,
            width: (watermarkCanvas.width * scaleFactor).round(),
            height: (watermarkCanvas.height * scaleFactor).round(),
            interpolation: img.Interpolation.linear,
            backgroundColor: img.ColorRgba8(0, 0, 0, 0), // Keep transparent background
          )
        : watermarkCanvas;

    // Calculate position for scaled watermark
    final (baseX, baseY) = _calculateWatermarkPosition(
      position,
      originalImage.width,
      originalImage.height,
      scaledWatermark.width,
      scaledWatermark.height,
    );

    // Composite the scaled watermark onto the original image with proper transparency
    img.compositeImage(
      originalImage,
      scaledWatermark,
      dstX: baseX,
      dstY: baseY,
      blend: img.BlendMode.alpha, // Use alpha blending for transparency
    );
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