import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/photo.dart';
import '../providers/visits_provider.dart';
import '../services/wasabi_service.dart';
import '../widgets/common/cached_image.dart';

class PhotoGalleryViewer extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const PhotoGalleryViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<PhotoGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _isVisible
          ? AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                '${_currentIndex + 1} of ${widget.photos.length}',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: _showPhotoInfo,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleUI,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.photos.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            return _buildPhotoView(photo);
          },
        ),
      ),
      bottomNavigationBar: _isVisible && widget.photos.length > 1
          ? Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: _currentIndex > 0 ? Colors.white : Colors.grey,
                    ),
                    onPressed: _currentIndex > 0 ? _previousPhoto : null,
                  ),
                  Text(
                    widget.photos[_currentIndex].photoType.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: _currentIndex < widget.photos.length - 1
                          ? Colors.white
                          : Colors.grey,
                    ),
                    onPressed: _currentIndex < widget.photos.length - 1
                        ? _nextPhoto
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildPhotoView(Photo photo) {
    return FutureBuilder<String?>(
      future: context.read<VisitsProvider>().getPhotoUrl(photo.storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          );
        }

        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: CachedImage(
              imageUrl: snapshot.data!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
              errorWidget: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Image not available',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _previousPhoto() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPhoto() {
    if (_currentIndex < widget.photos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showPhotoInfo() {
    final photo = widget.photos[_currentIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Photo Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${photo.photoType.displayName}'),
            const SizedBox(height: 8),
            Text('Captured: ${photo.createdAt.toLocal().toString().split('.')[0]}'),
            const SizedBox(height: 8),
            FutureBuilder<int?>(
              future: _getActualFileSize(photo),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      Text('Size: '),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ],
                  );
                }

                final fileSize = snapshot.data;
                if (fileSize != null) {
                  return Text('Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
                } else {
                  return const Text('Size: Unknown');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<int?> _getActualFileSize(Photo photo) async {
    try {
      // Handle different storage path formats
      if (photo.storagePath.startsWith('wasabi:')) {
        // For new Wasabi integration, remove 'wasabi:' prefix
        final objectName = photo.storagePath.substring(7);
        return await WasabiService.getObjectSize(objectName);
      } else if (photo.storagePath.startsWith('https://s3.') &&
                 photo.storagePath.contains('wasabisys.com')) {
        // For legacy Wasabi URLs, extract object name from URL
        final uri = Uri.parse(photo.storagePath);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final objectName = pathSegments.skip(1).join('/'); // Skip bucket name
          return await WasabiService.getObjectSize(objectName);
        }
      }

      // For other storage paths (e.g., Supabase), fall back to stored size
      return photo.fileSize;
    } catch (e) {
      // If error getting actual size, fall back to stored size
      return photo.fileSize;
    }
  }
}