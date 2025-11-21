import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minio/minio.dart';
import 'package:uuid/uuid.dart';

class WasabiService {
  static late Minio _minio;
  static late String _bucketName;
  static late String _region;
  static late String _endpoint;
  static bool _isInitialized = false;

  // Initialize Wasabi client
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final accessKey = dotenv.env['WASABI_ACCESS_KEY_ID'];
      final secretKey = dotenv.env['WASABI_SECRET_ACCESS_KEY'];
      final bucketName = dotenv.env['WASABI_BUCKET_NAME'];
      final region = dotenv.env['WASABI_REGION'];
      final endpoint = dotenv.env['WASABI_ENDPOINT'];

      if (accessKey == null ||
          secretKey == null ||
          bucketName == null ||
          region == null ||
          endpoint == null) {
        throw Exception('Wasabi configuration missing in environment variables');
      }

      // Extract host from endpoint URL
      final uri = Uri.parse(endpoint);
      final endpointHost = uri.host;
      final port = uri.port == 443 ? null : uri.port;
      final useSSL = uri.scheme == 'https';

      _minio = Minio(
        endPoint: endpointHost,
        accessKey: accessKey,
        secretKey: secretKey,
        useSSL: useSSL,
        port: port,
      );

      _bucketName = bucketName;
      _region = region;
      _endpoint = endpoint;
      _isInitialized = true;

      debugPrint('WasabiService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize WasabiService: $e');
      rethrow;
    }
  }

  // Check if bucket exists and create if necessary
  static Future<void> _ensureBucket() async {
    if (!_isInitialized) await initialize();

    try {
      final exists = await _minio.bucketExists(_bucketName);
      if (!exists) {
        await _minio.makeBucket(_bucketName);
        debugPrint('Created bucket: $_bucketName');
      }
    } catch (e) {
      debugPrint('Error ensuring bucket exists: $e');
      rethrow;
    }
  }

  // Upload photo from XFile
  static Future<String> uploadPhoto(XFile photo, {String? customPath}) async {
    try {
      await _ensureBucket();

      // Generate unique filename
      final uuid = const Uuid();
      final fileId = uuid.v4();
      final extension = photo.path.split('.').last.toLowerCase();
      final fileName = customPath ?? 'photos/$fileId.$extension';

      // Read file bytes
      final bytes = await photo.readAsBytes();

      // Upload to Wasabi
      await _minio.putObject(
        _bucketName,
        fileName,
        Stream.fromIterable([bytes]),
        size: bytes.length,
        metadata: {
          'Content-Type': _getContentType(extension),
        },
      );

      // Return public URL
      final publicUrl = '$_endpoint/$_bucketName/$fileName';
      debugPrint('Photo uploaded successfully: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('Failed to upload photo to Wasabi: $e');
      rethrow;
    }
  }

  // Upload photo from File
  static Future<String> uploadPhotoFromFile(File photo, {String? customPath}) async {
    try {
      await _ensureBucket();

      // Generate unique filename
      final uuid = const Uuid();
      final fileId = uuid.v4();
      final extension = photo.path.split('.').last.toLowerCase();
      final fileName = customPath ?? 'photos/$fileId.$extension';

      // Read file bytes
      final bytes = await photo.readAsBytes();

      // Upload to Wasabi
      await _minio.putObject(
        _bucketName,
        fileName,
        Stream.fromIterable([bytes]),
        size: bytes.length,
        metadata: {
          'Content-Type': _getContentType(extension),
        },
      );

      // Return public URL
      final publicUrl = '$_endpoint/$_bucketName/$fileName';
      debugPrint('Photo uploaded successfully: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('Failed to upload photo to Wasabi: $e');
      rethrow;
    }
  }

  // Upload photo from bytes
  static Future<String> uploadPhotoFromBytes(
    Uint8List bytes,
    String extension, {
    String? customPath,
  }) async {
    try {
      await _ensureBucket();

      // Generate unique filename
      final uuid = const Uuid();
      final fileId = uuid.v4();
      final fileName = customPath ?? 'photos/$fileId.$extension';

      // Upload to Wasabi
      await _minio.putObject(
        _bucketName,
        fileName,
        Stream.fromIterable([bytes]),
        size: bytes.length,
        metadata: {
          'Content-Type': _getContentType(extension),
        },
      );

      // Return public URL
      final publicUrl = '$_endpoint/$_bucketName/$fileName';
      debugPrint('Photo uploaded successfully: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('Failed to upload photo to Wasabi: $e');
      rethrow;
    }
  }

  // Delete photo by URL
  static Future<bool> deletePhoto(String photoUrl) async {
    try {
      await _ensureBucket();

      // Extract object name from URL
      final objectName = _extractObjectNameFromUrl(photoUrl);
      if (objectName == null) {
        debugPrint('Invalid photo URL: $photoUrl');
        return false;
      }

      // Delete from Wasabi
      await _minio.removeObject(_bucketName, objectName);
      debugPrint('Photo deleted successfully: $objectName');

      return true;
    } catch (e) {
      debugPrint('Failed to delete photo from Wasabi: $e');
      return false;
    }
  }

  // Delete multiple photos
  static Future<List<String>> deletePhotos(List<String> photoUrls) async {
    final failedDeletes = <String>[];

    for (final url in photoUrls) {
      final success = await deletePhoto(url);
      if (!success) {
        failedDeletes.add(url);
      }
    }

    return failedDeletes;
  }

  // Get presigned download URL (if needed for private access)
  static Future<String> getPresignedUrl(String objectName, {Duration? expiry}) async {
    try {
      if (!_isInitialized) await initialize();

      final url = await _minio.presignedGetObject(
        _bucketName,
        objectName,
        expires: expiry?.inSeconds ?? 3600, // 1 hour default
      );

      return url;
    } catch (e) {
      debugPrint('Failed to get presigned URL: $e');
      rethrow;
    }
  }

  // Simplified storage stats without list operations
  static Future<Map<String, dynamic>> getBucketStats() async {
    try {
      if (!_isInitialized) await initialize();

      return {
        'bucket_name': _bucketName,
        'region': _region,
        'endpoint': _endpoint,
        'status': 'available',
      };
    } catch (e) {
      debugPrint('Failed to get bucket stats: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  // Helper method to get content type
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

  // Helper method to extract object name from URL
  static String? _extractObjectNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // URL format: https://s3.region.wasabisys.com/bucket-name/object-name
      if (pathSegments.length >= 2 && pathSegments[0] == _bucketName) {
        return pathSegments.skip(1).join('/');
      }

      return null;
    } catch (e) {
      debugPrint('Failed to extract object name from URL: $e');
      return null;
    }
  }
}