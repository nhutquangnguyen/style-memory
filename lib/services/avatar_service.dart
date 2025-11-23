import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'photo_service.dart';
import 'wasabi_service.dart';

class AvatarService {
  static const int avatarSize = 200; // Square avatar size
  static const int avatarQuality = 85; // Avatar compression quality

  // Cache for presigned URLs to prevent regeneration on widget rebuilds
  static final Map<String, _CachedUrl> _urlCache = {};
  static const Duration _cacheExpiry = Duration(hours: 20); // Cache for 20 hours (less than 24hr presigned URL expiry)

  /// Pick an avatar image from gallery or camera
  static Future<XFile?> pickAvatarImage({
    required bool fromCamera,
  }) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: avatarSize.toDouble(),
        maxHeight: avatarSize.toDouble(),
        imageQuality: avatarQuality,
        preferredCameraDevice: CameraDevice.front, // Front camera for selfies
      );

      return image;
    } catch (e) {
      throw Exception('Failed to pick avatar image: $e');
    }
  }

  /// Process and upload avatar image to Wasabi storage
  static Future<String> uploadAvatar({
    required Uint8List imageBytes,
    required String userId,
    required String clientId,
  }) async {
    try {
      // Create a square thumbnail for avatar
      final processedBytes = await PhotoService.createThumbnail(
        imageBytes,
        thumbnailSize: avatarSize,
      );

      // Create avatar storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final avatarPath = 'avatars/$userId/${clientId}_$timestamp.jpg';

      // Upload to Wasabi
      await WasabiService.uploadPhotoFromBytes(
        processedBytes,
        'jpg',
        customPath: avatarPath,
      );

      // Return the wasabi-prefixed path for database storage
      return 'wasabi:$avatarPath';
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Delete avatar from Wasabi storage
  static Future<bool> deleteAvatar(String avatarUrl) async {
    try {
      if (avatarUrl.startsWith('wasabi:')) {
        final objectName = avatarUrl.substring(7); // Remove 'wasabi:' prefix
        return await WasabiService.deletePhoto('https://s3.ap-southeast-1.wasabisys.com/style-memory-photos/$objectName');
      } else if (avatarUrl.startsWith('https://s3.') && avatarUrl.contains('wasabisys.com')) {
        // Legacy Wasabi URL format
        return await WasabiService.deletePhoto(avatarUrl);
      }

      return false; // Not a Wasabi URL
    } catch (e) {
      return false;
    }
  }

  /// Get presigned URL for avatar display with caching
  static Future<String?> getAvatarUrl(String avatarPath) async {
    try {
      // Check cache first
      final cached = _urlCache[avatarPath];
      if (cached != null && !cached.isExpired) {
        return cached.url;
      }

      String? presignedUrl;

      if (avatarPath.startsWith('wasabi:')) {
        final objectName = avatarPath.substring(7); // Remove 'wasabi:' prefix
        presignedUrl = await WasabiService.getPresignedUrl(
          objectName,
          expiry: const Duration(hours: 24), // Longer expiry for avatars
        );
      } else if (avatarPath.startsWith('https://s3.') && avatarPath.contains('wasabisys.com')) {
        // Legacy Wasabi URL - extract object name and generate presigned URL
        final uri = Uri.parse(avatarPath);
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
        _urlCache[avatarPath] = _CachedUrl(presignedUrl, DateTime.now());

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

  /// Clear all cached URLs (useful for testing or when avatar is updated)
  static void clearCache() {
    _urlCache.clear();
  }
}

/// Helper class for caching presigned URLs
class _CachedUrl {
  final String url;
  final DateTime createdAt;

  _CachedUrl(this.url, this.createdAt);

  bool get isExpired => DateTime.now().difference(createdAt) > AvatarService._cacheExpiry;
}