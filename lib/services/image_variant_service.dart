import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'image_quality_service.dart';

enum ImageVariant {
  thumb(64, 'thumb'),
  small(200, 'small'),
  medium(400, 'medium'),
  large(800, 'large'),
  original(-1, 'original');

  const ImageVariant(this.maxSize, this.suffix);

  final int maxSize;
  final String suffix;

  /// Get the best variant for a given display width
  static ImageVariant getBestVariant(int displayWidth) {
    if (displayWidth <= 64) return ImageVariant.thumb;
    if (displayWidth <= 200) return ImageVariant.small;
    if (displayWidth <= 400) return ImageVariant.medium;
    if (displayWidth <= 800) return ImageVariant.large;
    return ImageVariant.original;
  }

  /// Get all variants that should be generated
  static List<ImageVariant> get generateVariants => [
    ImageVariant.thumb,
    ImageVariant.small,
    ImageVariant.medium,
    ImageVariant.large,
  ];
}

class ProcessedImageVariant {
  final ImageVariant variant;
  final Uint8List data;
  final int width;
  final int height;
  final int fileSize;

  ProcessedImageVariant({
    required this.variant,
    required this.data,
    required this.width,
    required this.height,
    required this.fileSize,
  });
}

class ImageVariantService {
  /// Process an image and create all necessary variants
  static Future<List<ProcessedImageVariant>> processImageVariants(
    Uint8List originalImageBytes,
  ) async {
    final variants = <ProcessedImageVariant>[];

    // Decode original image
    img.Image? originalImage = img.decodeImage(originalImageBytes);
    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Get quality setting
    final quality = await ImageQualityService.getJpegQuality();
    final isRawQuality = quality >= 95;

    // Add original variant (unprocessed for RAW quality, or processed for others)
    if (isRawQuality) {
      variants.add(ProcessedImageVariant(
        variant: ImageVariant.original,
        data: originalImageBytes,
        width: originalImage.width,
        height: originalImage.height,
        fileSize: originalImageBytes.length,
      ));
    } else {
      // Process original to ensure it meets quality standards
      final processedOriginal = _processImageVariant(
        originalImage,
        ImageVariant.original,
        quality,
      );
      variants.add(processedOriginal);
    }

    // Generate all other variants
    for (final variant in ImageVariant.generateVariants) {
      final processedVariant = _processImageVariant(
        originalImage,
        variant,
        quality,
      );
      variants.add(processedVariant);
    }

    return variants;
  }

  /// Process a single image variant
  static ProcessedImageVariant _processImageVariant(
    img.Image originalImage,
    ImageVariant variant,
    int quality,
  ) {
    img.Image processedImage;

    if (variant == ImageVariant.original) {
      // For original, apply max dimensions but keep aspect ratio
      processedImage = _resizeToMaxDimensions(
        originalImage,
        1024, // Max width
        1024, // Max height
      );
    } else {
      // For variants, create square thumbnails or maintain aspect ratio
      if (variant == ImageVariant.thumb) {
        // Thumbs are square crops for consistency
        processedImage = img.copyResizeCropSquare(
          originalImage,
          size: variant.maxSize,
        );
      } else {
        // Other variants maintain aspect ratio
        processedImage = _resizeToMaxDimensions(
          originalImage,
          variant.maxSize,
          variant.maxSize,
        );
      }
    }

    // Encode with appropriate quality
    final variantQuality = variant == ImageVariant.thumb ? 75 : quality;
    final encodedData = img.encodeJpg(processedImage, quality: variantQuality);

    return ProcessedImageVariant(
      variant: variant,
      data: Uint8List.fromList(encodedData),
      width: processedImage.width,
      height: processedImage.height,
      fileSize: encodedData.length,
    );
  }

  /// Resize image to fit within max dimensions while maintaining aspect ratio
  static img.Image _resizeToMaxDimensions(
    img.Image image,
    int maxWidth,
    int maxHeight,
  ) {
    if (image.width <= maxWidth && image.height <= maxHeight) {
      return image; // No resize needed
    }

    final aspectRatio = image.width / image.height;
    int newWidth, newHeight;

    if (aspectRatio > 1) {
      // Landscape
      newWidth = maxWidth;
      newHeight = (maxWidth / aspectRatio).round();

      if (newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = (maxHeight * aspectRatio).round();
      }
    } else {
      // Portrait or square
      newHeight = maxHeight;
      newWidth = (maxHeight * aspectRatio).round();

      if (newWidth > maxWidth) {
        newWidth = maxWidth;
        newHeight = (maxWidth / aspectRatio).round();
      }
    }

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Create a specific variant from original image bytes
  static Future<ProcessedImageVariant> createSingleVariant(
    Uint8List originalImageBytes,
    ImageVariant variant,
  ) async {
    img.Image? originalImage = img.decodeImage(originalImageBytes);
    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    final quality = await ImageQualityService.getJpegQuality();
    return _processImageVariant(originalImage, variant, quality);
  }

  /// Get the file size estimate for all variants combined
  static int estimateTotalVariantSize(int originalSize) {
    // Rough estimates based on typical compression ratios
    const sizeMultipliers = {
      ImageVariant.thumb: 0.02,   // ~2% of original
      ImageVariant.small: 0.08,   // ~8% of original
      ImageVariant.medium: 0.25,  // ~25% of original
      ImageVariant.large: 0.65,   // ~65% of original
      ImageVariant.original: 1.0, // 100% of original
    };

    double totalSize = 0;
    for (final variant in ImageVariant.values) {
      totalSize += originalSize * (sizeMultipliers[variant] ?? 1.0);
    }

    return totalSize.round();
  }
}