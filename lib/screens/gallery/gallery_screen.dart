import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<PhotoWithContext> _allPhotos = [];
  List<PhotoWithContext> _filteredPhotos = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClientFilter;
  DateTimeRange? _selectedDateRange;
  Set<String> _availableClients = {};

  @override
  void initState() {
    super.initState();
    // Defer loading until after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllPhotos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPhotos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clientsProvider = context.read<ClientsProvider>();
      final visitsProvider = context.read<VisitsProvider>();

      // Load all clients first
      await clientsProvider.loadClients();
      final clients = clientsProvider.clients;

      List<PhotoWithContext> allPhotos = [];

      // Load visits and photos for each client
      for (final client in clients) {
        await visitsProvider.loadVisitsForClient(client.id);
        final visits = visitsProvider.getVisitsForClient(client.id);

        for (final visit in visits) {
          if (visit.photos != null && visit.photos!.isNotEmpty) {
            for (final photo in visit.photos!) {
              // Pre-fetch the photo URL to avoid calling provider during build
              final photoUrl = await visitsProvider.getPhotoUrl(photo.storagePath);
              allPhotos.add(PhotoWithContext(
                photo: photo,
                client: client,
                visit: visit,
                photoUrl: photoUrl,
              ));
            }
          }
        }
      }

      // Sort by most recent first
      allPhotos.sort((a, b) => b.visit.visitDate.compareTo(a.visit.visitDate));

      // Extract unique client names for filtering
      final clientNames = allPhotos.map((photo) => photo.client.fullName).toSet();

      setState(() {
        _allPhotos = allPhotos;
        _filteredPhotos = allPhotos; // Initially show all photos
        _availableClients = clientNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load photos: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPhotos = _allPhotos.where((photo) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final clientName = photo.client.fullName.toLowerCase();
          final hasNotes = photo.visit.notes?.toLowerCase().contains(query) ?? false;
          if (!clientName.contains(query) && !hasNotes) {
            return false;
          }
        }

        // Client filter
        if (_selectedClientFilter != null &&
            photo.client.fullName != _selectedClientFilter) {
          return false;
        }

        // Date range filter
        if (_selectedDateRange != null) {
          final visitDate = photo.visit.visitDate;
          if (visitDate.isBefore(_selectedDateRange!.start) ||
              visitDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onClientFilterChanged(String? clientName) {
    setState(() {
      _selectedClientFilter = clientName;
    });
    _applyFilters();
  }

  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() {
      _selectedDateRange = range;
    });
    _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedClientFilter = null;
      _selectedDateRange = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Gallery (${_filteredPhotos.length})'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => _showFilterBottomSheet(context),
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter Photos',
            ),
            IconButton(
              onPressed: _loadAllPhotos,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Gallery',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search clients or notes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Active filters chips
            if (_hasActiveFilters()) _buildActiveFiltersChips(),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: ErrorBanner(
                  message: _errorMessage!,
                  onRetry: _loadAllPhotos,
                ),
              ),
            if (_allPhotos.isEmpty && !_isLoading)
              _buildEmptyState()
            else if (_filteredPhotos.isEmpty && _allPhotos.isNotEmpty)
              _buildNoResultsState()
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAllPhotos,
                  child: _buildPhotoGrid(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No photos yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
              child: Text(
                'Start capturing photos for your clients to build your showcase gallery.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('clients'),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add First Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryButtonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                  vertical: AppTheme.spacingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    const crossAxisCount = 3; // Instagram-style 3 columns

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(2.0), // Minimal padding for full-width grid
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 2.0, // Minimal gaps like Instagram
              crossAxisSpacing: 2.0,
              childAspectRatio: 1.0, // Perfect squares
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final photoContext = _filteredPhotos[index];
                return _buildPhotoGridItem(photoContext, index);
              },
              childCount: _filteredPhotos.length,
            ),
          ),
        ),
        // Add some bottom padding
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 80),
        ),
      ],
    );
  }

  Widget _buildPhotoGridItem(PhotoWithContext photoContext, int index) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(index),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.grey,
        ),
        child: photoContext.photoUrl != null
            ? CachedImage(
                imageUrl: photoContext.photoUrl!,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[600],
                    size: 30,
                  ),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      ),
    );
  }

  void _openPhotoViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(
          photos: _filteredPhotos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
           _selectedClientFilter != null ||
           _selectedDateRange != null;
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedClientFilter != null)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
              child: Chip(
                label: Text(_selectedClientFilter!),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () => _onClientFilterChanged(null),
              ),
            ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
              child: Chip(
                label: Text(
                  '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                ),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () => _onDateRangeChanged(null),
              ),
            ),
          if (_hasActiveFilters())
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
              child: ActionChip(
                label: const Text('Clear all'),
                onPressed: _clearFilters,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No photos found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
              child: Text(
                'Try adjusting your search terms or filters to find what you\'re looking for.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Photos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearFilters();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),

                  // Client filter
                  Text(
                    'Filter by Client',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedClientFilter,
                      hint: const Text('  Select a client'),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('  All Clients'),
                        ),
                        ..._availableClients.map((client) => DropdownMenuItem<String>(
                          value: client,
                          child: Text('  $client'),
                        )),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _selectedClientFilter = value;
                        });
                        _onClientFilterChanged(value);
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),

                  // Date range filter
                  Text(
                    'Filter by Date Range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  OutlinedButton(
                    onPressed: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: _selectedDateRange,
                      );
                      if (picked != null) {
                        setModalState(() {
                          _selectedDateRange = picked;
                        });
                        _onDateRangeChanged(picked);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: Text(
                            _selectedDateRange != null
                                ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                                : 'Select date range',
                          ),
                        ),
                        if (_selectedDateRange != null)
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedDateRange = null;
                              });
                              _onDateRangeChanged(null);
                            },
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper class to store photo with context
class PhotoWithContext {
  final Photo photo;
  final Client client;
  final Visit visit;
  String? photoUrl; // Cache the URL

  PhotoWithContext({
    required this.photo,
    required this.client,
    required this.visit,
    this.photoUrl,
  });
}

// Full-screen photo viewer
class _PhotoViewerScreen extends StatefulWidget {
  final List<PhotoWithContext> photos;
  final int initialIndex;

  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

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

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentPhoto.client.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              currentPhoto.visit.formattedVisitDate,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.goNamed(
              'client_profile',
              pathParameters: {'clientId': currentPhoto.client.id},
            ),
            icon: const Icon(Icons.person),
            tooltip: 'View Client Profile',
          ),
          IconButton(
            onPressed: () => context.goNamed(
              'visit_details',
              pathParameters: {'visitId': currentPhoto.visit.id},
            ),
            icon: const Icon(Icons.calendar_today),
            tooltip: 'View Visit Details',
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              final photoContext = widget.photos[index];
              return Center(
                child: photoContext.photoUrl != null
                    ? CachedImage(
                        imageUrl: photoContext.photoUrl!,
                        fit: BoxFit.contain,
                        placeholder: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
              );
            },
          ),
          // Photo counter
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.photos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}