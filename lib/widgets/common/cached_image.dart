import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/image_cache_service.dart';

class CachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

// Global cache manager for Instagram-like smooth experience
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  // Large memory cache for instant access
  static final Map<String, Uint8List> _memoryCache = {};
  static final Map<String, Future<Uint8List?>> _loadingCache = {};
  static final List<String> _accessOrder = []; // For LRU eviction

  // Generous cache limits for smooth scrolling
  static const int _maxMemoryCacheSize = 500; // 500 images in memory (up from 200)
  static const int _cleanupThreshold = 600; // Start cleanup when reaching 600 images

  Uint8List? getFromMemory(String url) {
    final data = _memoryCache[url];
    if (data != null) {
      // Update LRU order
      _accessOrder.remove(url);
      _accessOrder.add(url);
    }
    return data;
  }

  Future<Uint8List?> loadImage(String url) {
    // Return existing loading future if in progress
    if (_loadingCache.containsKey(url)) {
      return _loadingCache[url]!;
    }

    // Check memory cache first
    final cached = getFromMemory(url);
    if (cached != null) {
      return Future.value(cached);
    }

    // Start loading and cache the future
    final future = ImageCacheService.getCachedImage(url).then((data) {
      if (data != null) {
        _storeInMemory(url, data);
      }
      _loadingCache.remove(url);
      return data;
    }).catchError((error) {
      _loadingCache.remove(url);
      return null;
    });

    _loadingCache[url] = future;
    return future;
  }

  void _storeInMemory(String url, Uint8List data) {
    _memoryCache[url] = data;
    _accessOrder.remove(url);
    _accessOrder.add(url);
    _cleanup();
  }

  void _cleanup() {
    if (_memoryCache.length > _cleanupThreshold) {
      // Remove oldest 50 images to get back to max size
      final toRemove = _accessOrder.take(50).toList();
      for (final url in toRemove) {
        _memoryCache.remove(url);
        _accessOrder.remove(url);
      }
    }
  }

  // Preload images for smoother scrolling
  void preloadImage(String url) {
    if (!_memoryCache.containsKey(url) && !_loadingCache.containsKey(url)) {
      loadImage(url);
    }
  }

  // Preload multiple images in parallel
  void preloadImages(List<String> urls) {
    for (final url in urls) {
      preloadImage(url);
    }
  }

  // Preload multiple images in parallel with explicit Future handling
  Future<void> preloadImagesParallel(List<String> urls) async {
    final futures = urls
        .where((url) => !_memoryCache.containsKey(url) && !_loadingCache.containsKey(url))
        .map((url) => loadImage(url))
        .toList();

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  // Clear specific URL from cache
  void clearUrl(String url) {
    _memoryCache.remove(url);
    _loadingCache.remove(url);
    _accessOrder.remove(url);
  }

  // Clear all caches
  void clearAll() {
    _memoryCache.clear();
    _loadingCache.clear();
    _accessOrder.clear();
  }

  // Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    return {
      'memory_cache_size': _memoryCache.length,
      'loading_cache_size': _loadingCache.length,
      'access_order_size': _accessOrder.length,
    };
  }

  // Static access for preloading from other widgets
  static ImageCacheManager get instance => ImageCacheManager();
}

class _CachedImageState extends State<CachedImage> {
  final _cacheManager = ImageCacheManager();
  Uint8List? _cachedImageData;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImageData();
    }
  }

  void _loadImageData() async {
    setState(() {
      _hasError = false;
    });

    // Check memory cache first - instant return
    final cachedData = _cacheManager.getFromMemory(widget.imageUrl);
    if (cachedData != null) {
      setState(() {
        _cachedImageData = cachedData;
      });
      return;
    }

    try {
      final imageData = await _cacheManager.loadImage(widget.imageUrl);
      if (mounted) {
        setState(() {
          _cachedImageData = imageData;
          _hasError = imageData == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return cached image immediately - no loading state
    if (_cachedImageData != null) {
      return Image.memory(
        _cachedImageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    // Show error state
    if (_hasError) {
      return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                'Image not available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
    }

    // Show loading state only for first time loads
    return widget.placeholder ??
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
  }
}