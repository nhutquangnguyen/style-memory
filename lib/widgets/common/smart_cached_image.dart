import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'cached_image.dart';

/// Smart image widget that automatically selects the best variant size
class SmartCachedImage extends StatelessWidget {
  final Photo photo;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartCachedImage({
    super.key,
    required this.photo,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the best variant to use based on display size
    final displayWidth = width?.toInt() ?? 400; // Default to medium if no width specified
    final imageUrl = photo.getBestVariantUrl(displayWidth);

    // Since Wasabi URLs are already full URLs, use them directly
    return CachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: placeholder ?? const Center(child: CircularProgressIndicator()),
      errorWidget: errorWidget ?? const Icon(Icons.error),
    );
  }
}

/// Avatar-specific variant that always uses thumb size
class SmartAvatarImage extends StatelessWidget {
  final Photo photo;
  final double size;
  final bool showBorder;
  final Color? borderColor;

  const SmartAvatarImage({
    super.key,
    required this.photo,
    this.size = 40,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Always use thumb variant for avatars (64px or smaller)
    final imageUrl = photo.getVariantUrl('thumb');

    Widget imageWidget = CachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: size * 0.6,
      ),
      errorWidget: Icon(
        Icons.error,
        color: Colors.red[400],
        size: size * 0.6,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? Theme.of(context).primaryColor,
                width: 2,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );
  }
}

/// Card-specific variant optimized for list views
class SmartCardImage extends StatelessWidget {
  final Photo photo;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SmartCardImage({
    super.key,
    required this.photo,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Use small or medium variant for card views (200-400px)
    final displayWidth = width?.toInt() ?? 200;
    final imageUrl = photo.getBestVariantUrl(displayWidth);

    // Since Wasabi URLs are already full URLs, use them directly
    return CachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: const Icon(
          Icons.error,
          color: Colors.red,
        ),
      ),
    );
  }
}

/// Utility class for image variant information
class ImageVariantInfo {
  static String getVariantDisplayName(String variantKey) {
    switch (variantKey) {
      case 'thumb':
        return 'Thumbnail (64px)';
      case 'small':
        return 'Small (200px)';
      case 'medium':
        return 'Medium (400px)';
      case 'large':
        return 'Large (800px)';
      case 'original':
        return 'Original';
      default:
        return 'Unknown';
    }
  }

  static IconData getVariantIcon(String variantKey) {
    switch (variantKey) {
      case 'thumb':
        return Icons.photo_size_select_small;
      case 'small':
        return Icons.photo_size_select_actual;
      case 'medium':
        return Icons.photo_size_select_large;
      case 'large':
        return Icons.photo;
      case 'original':
        return Icons.high_quality;
      default:
        return Icons.image;
    }
  }
}