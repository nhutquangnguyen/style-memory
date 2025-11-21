import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageCacheService {
  static const String _cacheDir = 'style_memory_image_cache';
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration _cacheExpiry = Duration(days: 7);

  static Directory? _cacheDirectory;
  static final Map<String, Uint8List> _memoryCache = {};
  static const int _maxMemoryCacheSize = 10 * 1024 * 1024; // 10MB in memory
  static int _currentMemoryCacheSize = 0;

  /// Initialize cache directory
  static Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/$_cacheDir');

      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }

      // Clean up expired cache files on startup
      _cleanupExpiredFiles();
    } catch (e) {
      debugPrint('Failed to initialize image cache: $e');
    }
  }

  /// Get cached image or download if not available
  static Future<Uint8List?> getCachedImage(String imageUrl) async {
    try {
      final cacheKey = _getCacheKey(imageUrl);

      // Check memory cache first
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey];
      }

      // Check disk cache
      if (_cacheDirectory != null) {
        final cacheFile = File('${_cacheDirectory!.path}/$cacheKey.jpg');

        if (await cacheFile.exists()) {
          final lastModified = await cacheFile.lastModified();
          final now = DateTime.now();

          // Check if cache is still valid
          if (now.difference(lastModified) < _cacheExpiry) {
            final imageData = await cacheFile.readAsBytes();
            _addToMemoryCache(cacheKey, imageData);
            return imageData;
          } else {
            // Delete expired file
            await cacheFile.delete();
          }
        }
      }

      // Download image if not cached
      return await _downloadAndCacheImage(imageUrl, cacheKey);
    } catch (e) {
      return null;
    }
  }

  /// Download image and cache it
  static Future<Uint8List?> _downloadAndCacheImage(String imageUrl, String cacheKey) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;

        // Cache to disk
        if (_cacheDirectory != null) {
          final cacheFile = File('${_cacheDirectory!.path}/$cacheKey.jpg');
          await cacheFile.writeAsBytes(imageData);
        }

        // Cache to memory
        _addToMemoryCache(cacheKey, imageData);

        return imageData;
      }
    } catch (e) {
      // Error handled silently
    }
    return null;
  }

  /// Add image to memory cache with size management
  static void _addToMemoryCache(String key, Uint8List data) {
    final dataSize = data.length;

    // Clean memory cache if it would exceed limit
    while (_currentMemoryCacheSize + dataSize > _maxMemoryCacheSize && _memoryCache.isNotEmpty) {
      final firstKey = _memoryCache.keys.first;
      final removedData = _memoryCache.remove(firstKey);
      if (removedData != null) {
        _currentMemoryCacheSize -= removedData.length;
      }
    }

    _memoryCache[key] = data;
    _currentMemoryCacheSize += dataSize;
  }

  /// Generate cache key from URL
  static String _getCacheKey(String imageUrl) {
    final bytes = utf8.encode(imageUrl);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Clean up expired cache files
  static Future<void> _cleanupExpiredFiles() async {
    try {
      if (_cacheDirectory == null) return;

      final now = DateTime.now();
      final files = await _cacheDirectory!.list().toList();

      for (final file in files) {
        if (file is File) {
          final lastModified = await file.lastModified();
          if (now.difference(lastModified) > _cacheExpiry) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    try {
      _memoryCache.clear();
      _currentMemoryCacheSize = 0;

      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache size info
  static Future<Map<String, int>> getCacheInfo() async {
    try {
      int diskSize = 0;
      int fileCount = 0;

      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        final files = await _cacheDirectory!.list().toList();

        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            diskSize += stat.size;
            fileCount++;
          }
        }
      }

      return {
        'memorySize': _currentMemoryCacheSize,
        'diskSize': diskSize,
        'fileCount': fileCount,
        'memoryCacheItems': _memoryCache.length,
      };
    } catch (e) {
      debugPrint('Error getting cache info: $e');
      return {};
    }
  }
}