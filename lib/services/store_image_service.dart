import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'photo_service.dart';
import 'wasabi_service.dart';

class StoreImageService {
  static const int avatarSize = 200; // Square avatar size
  static const int coverMaxWidth = 800; // Cover image max width
  static const int coverMaxHeight = 400; // Cover image max height
  static const int imageQuality = 85; // Image compression quality

  // Cache for presigned URLs to prevent regeneration
  static final Map<String, _CachedUrl> _urlCache = {};
  static const Duration _cacheExpiry = Duration(hours: 20); // Cache for 20 hours

  /// Pick avatar image from gallery or camera
  static Future<XFile?> pickAvatarImage({
    required bool fromCamera,
  }) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: avatarSize.toDouble(),
        maxHeight: avatarSize.toDouble(),
        imageQuality: imageQuality,
        preferredCameraDevice: CameraDevice.front, // Front camera for selfies
      );

      return image;
    } catch (e) {
      throw Exception('Failed to pick avatar image: $e');
    }
  }

  /// Pick cover image from gallery or camera
  static Future<XFile?> pickCoverImage({
    required bool fromCamera,
  }) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: coverMaxWidth.toDouble(),
        maxHeight: coverMaxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      return image;
    } catch (e) {
      throw Exception('Failed to pick cover image: $e');
    }
  }

  /// Process and upload store avatar image to Wasabi storage
  static Future<String> uploadStoreAvatar({
    required Uint8List imageBytes,
    required String storeId,
  }) async {
    try {
      // Create a square thumbnail for avatar
      final processedBytes = await PhotoService.createThumbnail(
        imageBytes,
        thumbnailSize: avatarSize,
      );

      // Create avatar storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final avatarPath = 'store_avatars/$storeId/avatar_$timestamp.jpg';

      // Upload to Wasabi
      await WasabiService.uploadPhotoFromBytes(
        processedBytes,
        'jpg',
        customPath: avatarPath,
      );

      // Return the wasabi-prefixed path for database storage
      return 'wasabi:$avatarPath';
    } catch (e) {
      throw Exception('Failed to upload store avatar: $e');
    }
  }

  /// Process and upload store cover image to Wasabi storage
  static Future<String> uploadStoreCover({
    required Uint8List imageBytes,
    required String storeId,
  }) async {
    try {
      // Compress cover image while maintaining aspect ratio
      final processedBytes = await PhotoService.compressImageBytes(
        imageBytes,
        quality: imageQuality,
      );

      // Create cover storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final coverPath = 'store_covers/$storeId/cover_$timestamp.jpg';

      // Upload to Wasabi
      await WasabiService.uploadPhotoFromBytes(
        processedBytes,
        'jpg',
        customPath: coverPath,
      );

      // Return the wasabi-prefixed path for database storage
      return 'wasabi:$coverPath';
    } catch (e) {
      throw Exception('Failed to upload store cover: $e');
    }
  }

  /// Delete store image from Wasabi storage
  static Future<bool> deleteStoreImage(String imagePath) async {
    try {
      if (imagePath.startsWith('wasabi:')) {
        final objectName = imagePath.substring(7); // Remove 'wasabi:' prefix
        return await WasabiService.deletePhoto('https://s3.ap-southeast-1.wasabisys.com/style-memory-photos/$objectName');
      } else if (imagePath.startsWith('https://s3.') && imagePath.contains('wasabisys.com')) {
        // Legacy Wasabi URL format
        return await WasabiService.deletePhoto(imagePath);
      }

      return false; // Not a Wasabi URL
    } catch (e) {
      return false;
    }
  }

  /// Get presigned URL for store image display with caching
  static Future<String?> getStoreImageUrl(String imagePath) async {
    try {
      // Check cache first
      final cached = _urlCache[imagePath];
      if (cached != null && !cached.isExpired) {
        return cached.url;
      }

      String? presignedUrl;

      if (imagePath.startsWith('wasabi:')) {
        final objectName = imagePath.substring(7); // Remove 'wasabi:' prefix
        presignedUrl = await WasabiService.getPresignedUrl(
          objectName,
          expiry: const Duration(hours: 24), // Longer expiry for store images
        );
      } else if (imagePath.startsWith('https://s3.') && imagePath.contains('wasabisys.com')) {
        // Legacy Wasabi URL - extract object name and generate presigned URL
        final uri = Uri.parse(imagePath);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final objectName = pathSegments.skip(1).join('/'); // Skip bucket name
          presignedUrl = await WasabiService.getPresignedUrl(
            objectName,
            expiry: const Duration(hours: 24),
          );
        }
      }

      // Cache the result if we got a URL
      if (presignedUrl != null) {
        _urlCache[imagePath] = _CachedUrl(presignedUrl, DateTime.now());

        // Clean up expired cache entries periodically
        _cleanExpiredCache();
      }

      return presignedUrl;
    } catch (e) {
      return null;
    }
  }

  /// Clean up expired cache entries
  static void _cleanExpiredCache() {
    _urlCache.removeWhere((key, cached) => cached.isExpired);
  }

  /// Clear all cached URLs (useful for testing or when images are updated)
  static void clearCache() {
    _urlCache.clear();
  }

  /// Check if image path is a store image
  static bool isStoreImage(String imagePath) {
    return imagePath.startsWith('wasabi:store_avatars/') ||
           imagePath.startsWith('wasabi:store_covers/') ||
           (imagePath.contains('store_avatars/') || imagePath.contains('store_covers/'));
  }

  /// Get image type from path
  static StoreImageType? getImageType(String imagePath) {
    if (imagePath.contains('store_avatars/') || imagePath.startsWith('wasabi:store_avatars/')) {
      return StoreImageType.avatar;
    } else if (imagePath.contains('store_covers/') || imagePath.startsWith('wasabi:store_covers/')) {
      return StoreImageType.cover;
    }
    return null;
  }
}

/// Helper class for caching presigned URLs
class _CachedUrl {
  final String url;
  final DateTime createdAt;

  _CachedUrl(this.url, this.createdAt);

  bool get isExpired => DateTime.now().difference(createdAt) > StoreImageService._cacheExpiry;
}

/// Store image types
enum StoreImageType {
  avatar,
  cover,
}

extension StoreImageTypeExtension on StoreImageType {
  String get displayName {
    switch (this) {
      case StoreImageType.avatar:
        return 'Store Avatar';
      case StoreImageType.cover:
        return 'Cover Image';
    }
  }

  String get description {
    switch (this) {
      case StoreImageType.avatar:
        return 'Square logo or profile image for your store';
      case StoreImageType.cover:
        return 'Banner image displayed at the top of your store profile';
    }
  }
}