import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/modern_input.dart';

class LovedStylesScreen extends StatefulWidget {
  const LovedStylesScreen({super.key});

  @override
  State<LovedStylesScreen> createState() => _LovedStylesScreenState();

  // Static method to clear cache from outside the widget
  static void clearCache() {
    _LovedStylesScreenState._cachedLovedPhotos = null;
    _LovedStylesScreenState._lastCacheTime = null;
  }

  // Static method to preload loved styles data
  static Future<void> preloadLovedStylesData(BuildContext context) async {
    // Check if we already have valid cached data
    if (_LovedStylesScreenState._cachedLovedPhotos != null &&
        _LovedStylesScreenState._lastCacheTime != null &&
        DateTime.now().difference(_LovedStylesScreenState._lastCacheTime!) < _LovedStylesScreenState._cacheExpiry) {
      debugPrint('Loved styles data already cached, skipping preload');
      return;
    }

    try {
      final clientsProvider = context.read<ClientsProvider>();
      final visitsProvider = context.read<VisitsProvider>();

      // Load all clients first
      await clientsProvider.loadClients();
      final clients = clientsProvider.clients;

      List<PhotoWithContext> lovedPhotos = [];

      // Load visits and photos for each client, but only include loved visits
      for (final client in clients) {
        await visitsProvider.loadVisitsForClient(client.id);
        final visits = visitsProvider.getVisitsForClient(client.id);

        // Filter for only loved visits
        final lovedVisits = visits.where((visit) => visit.loved == true);

        for (final visit in lovedVisits) {
          if (visit.photos != null && visit.photos!.isNotEmpty) {
            // Only load the first photo for thumbnail - much more efficient
            final firstPhoto = visit.photos!.first;
            final photoUrl = await visitsProvider.getPhotoUrl(firstPhoto.storagePath);

            lovedPhotos.add(PhotoWithContext(
              photo: firstPhoto,
              client: client,
              visit: visit,
              photoUrl: photoUrl,
            ));
          }
        }
      }

      // Sort by most recent first (visit date)
      lovedPhotos.sort((a, b) => b.visit.visitDate.compareTo(a.visit.visitDate));

      // Cache the results
      _LovedStylesScreenState._cachedLovedPhotos = lovedPhotos;
      _LovedStylesScreenState._lastCacheTime = DateTime.now();

      // Smart preloading: prioritize viewport-visible images first
      final allImageUrls = lovedPhotos
          .map((photo) => photo.photoUrl)
          .where((url) => url != null)
          .cast<String>()
          .toList();

      if (allImageUrls.isNotEmpty) {
        // Calculate how many cards fit in viewport - be conservative
        const int viewportCardCount = 5; // Actual visible cards (reduced from 6)
        const int preloadBuffer = 1; // Minimal buffer for smooth scrolling
        final int priorityCount = viewportCardCount + preloadBuffer; // = 6 total

        // Split into priority and background loading
        final priorityUrls = allImageUrls.take(priorityCount).toList();
        final backgroundUrls = allImageUrls.skip(priorityCount).toList();

        // Load priority images immediately (viewport + buffer)
        if (priorityUrls.isNotEmpty) {
          ImageCacheManager.instance.preloadImagesParallel(priorityUrls);
        }

        // Load remaining images with delay to not impact initial performance
        if (backgroundUrls.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            ImageCacheManager.instance.preloadImages(backgroundUrls);
          });
        }

        debugPrint('Loved styles data preloaded: ${lovedPhotos.length} photos, ${priorityUrls.length} priority images, ${backgroundUrls.length} background images');
      }
    } catch (e) {
      debugPrint('Failed to preload loved styles data: $e');
    }
  }
}

class _LovedStylesScreenState extends State<LovedStylesScreen> {
  List<PhotoWithContext> _lovedPhotos = [];
  List<PhotoWithContext> _filteredPhotos = [];
  bool _isLoading = false; // Start with false, will be set to true only if no cache
  String? _errorMessage;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String? _selectedServiceId;
  bool _showSearchBar = false;

  // Cache to prevent unnecessary reloads
  static List<PhotoWithContext>? _cachedLovedPhotos;
  static DateTime? _lastCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Check if we have cached data immediately
    if (_cachedLovedPhotos != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheExpiry) {
      _lovedPhotos = _cachedLovedPhotos!;
      _isLoading = false;
      // Apply filters in next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFilters();
      });
    }

    // Defer loading until after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLovedStyles();
      // Also load services and staff for proper display
      context.read<ServiceProvider>().loadServices();
      context.read<StaffProvider>().loadStaff();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadLovedStyles() async {
    // Check if we have valid cached data
    if (_cachedLovedPhotos != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheExpiry) {
      setState(() {
        _lovedPhotos = _cachedLovedPhotos!;
        _isLoading = false;
        _errorMessage = null;
      });
      _applyFilters();
      return;
    }

    // Only show loading if we don't have cached data
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

      List<PhotoWithContext> lovedPhotos = [];

      // Load visits and photos for each client, but only include loved visits
      for (final client in clients) {
        await visitsProvider.loadVisitsForClient(client.id);
        final visits = visitsProvider.getVisitsForClient(client.id);

        // Filter for only loved visits
        final lovedVisits = visits.where((visit) => visit.loved == true);

        for (final visit in lovedVisits) {
          if (visit.photos != null && visit.photos!.isNotEmpty) {
            // Only load the first photo for thumbnail - much more efficient
            final firstPhoto = visit.photos!.first;
            final photoUrl = await visitsProvider.getPhotoUrl(firstPhoto.storagePath);

            lovedPhotos.add(PhotoWithContext(
              photo: firstPhoto,
              client: client,
              visit: visit,
              photoUrl: photoUrl,
            ));
          }
        }
      }

      // Sort by most recent first (visit date)
      lovedPhotos.sort((a, b) => b.visit.visitDate.compareTo(a.visit.visitDate));

      setState(() {
        _lovedPhotos = lovedPhotos;
        _isLoading = false;
      });

      // Apply current filters
      _applyFilters();

      // Cache the results for future tab switches
      _cachedLovedPhotos = lovedPhotos;
      _lastCacheTime = DateTime.now();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load loved styles: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    if (!mounted) return;

    setState(() {
      _filteredPhotos = _lovedPhotos.where((photoWithContext) {
        final client = photoWithContext.client;
        final visit = photoWithContext.visit;

        // Apply search filter (client name)
        final searchQuery = _searchController.text.toLowerCase().trim();
        if (searchQuery.isNotEmpty) {
          final clientName = client.fullName.toLowerCase();
          if (!clientName.contains(searchQuery)) {
            return false;
          }
        }

        // Apply service filter
        if (_selectedServiceId != null && _selectedServiceId!.isNotEmpty) {
          if (visit.serviceId != _selectedServiceId) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _selectedServiceId = null;
      }
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedServiceId = null;
    });
  }

  List<Service> _getAvailableServices() {
    // Get unique services from loved visits
    final serviceIds = _lovedPhotos
        .map((p) => p.visit.serviceId)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    final serviceProvider = context.read<ServiceProvider>();
    return serviceProvider.services
        .where((service) => serviceIds.contains(service.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Loved Styles (${_getLovedVisitsCount()})'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: _toggleSearchBar,
              icon: Icon(_showSearchBar ? Icons.search_off : Icons.search),
              tooltip: _showSearchBar ? 'Hide Search' : 'Search Styles',
            ),
            IconButton(
              onPressed: () {
                // Clear cache and force refresh
                _cachedLovedPhotos = null;
                _lastCacheTime = null;
                _loadLovedStyles();
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Loved Styles',
            ),
          ],
        ),
        body: Column(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: ErrorBanner(
                  message: _errorMessage!,
                  onRetry: _loadLovedStyles,
                ),
              ),
            if (_showSearchBar) _buildSearchBar(),
            if ((_showSearchBar ? _filteredPhotos : _lovedPhotos).isEmpty && !_isLoading)
              _buildEmptyState()
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadLovedStyles,
                  child: _buildPhotoGrid(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _showSearchBar && (_searchController.text.isNotEmpty || _selectedServiceId != null);

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.search_off : Icons.favorite_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              isFiltered ? 'No results found' : 'No loved styles yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
              child: Text(
                isFiltered
                    ? 'Try adjusting your search criteria or clear filters to see more results.'
                    : 'Start marking your best work by tapping the ❤️ on visit cards. Your loved styling sessions will appear here as inspiration cards for future appointments.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            if (!isFiltered)
              ElevatedButton.icon(
                onPressed: () => context.goNamed('clients'),
                icon: const Icon(Icons.favorite),
                label: const Text('Create Loved Styles'),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search input
          ModernInput(
            controller: _searchController,
            label: 'Search by client name',
            hint: 'Enter client name...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () => _searchController.clear(),
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Service filter
          Consumer<ServiceProvider>(
            builder: (context, serviceProvider, child) {
              final availableServices = _getAvailableServices();

              if (availableServices.isEmpty) {
                return const SizedBox.shrink();
              }

              return Row(
                children: [
                  const Icon(
                    Icons.design_services,
                    size: 20,
                    color: AppTheme.secondaryTextColor,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                        vertical: AppTheme.spacingSmall,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedServiceId,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        hint: const Text('Filter by service'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Services'),
                          ),
                          ...availableServices.map((service) => DropdownMenuItem<String>(
                            value: service.id,
                            child: Text(service.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedServiceId = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  IconButton(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear Filters',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: _getUniqueVisits().length,
      itemBuilder: (context, index) {
        final visit = _getUniqueVisits()[index];

        // Progressive preloading: preload images for upcoming cards
        _progressivePreloadImages(index);

        return _buildVisitCard(visit);
      },
    );
  }

  void _progressivePreloadImages(int currentIndex) {
    const int preloadAhead = 3; // Preload 3 cards ahead
    final visits = _getUniqueVisits();
    final startIndex = currentIndex + 1;
    final endIndex = (startIndex + preloadAhead).clamp(0, visits.length);

    for (int i = startIndex; i < endIndex; i++) {
      final visit = visits[i];
      final photoWithContext = _lovedPhotos
          .where((photo) => photo.visit.id == visit.id)
          .firstOrNull;

      if (photoWithContext?.photoUrl != null) {
        ImageCacheManager.instance.preloadImage(photoWithContext!.photoUrl!);
      }
    }
  }

  List<Visit> _getUniqueVisits() {
    // Group photos by visit and return unique visits
    final photosToUse = _showSearchBar ? _filteredPhotos : _lovedPhotos;
    final Map<String, Visit> visitMap = {};
    for (final photoContext in photosToUse) {
      visitMap[photoContext.visit.id] = photoContext.visit;
    }
    final visits = visitMap.values.toList();
    // Sort by most recent first
    visits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    return visits;
  }

  List<PhotoWithContext> _getPhotosForVisit(Visit visit) {
    final photosToUse = _showSearchBar ? _filteredPhotos : _lovedPhotos;
    return photosToUse.where((photo) => photo.visit.id == visit.id).toList();
  }

  int _getLovedVisitsCount() {
    if (_lovedPhotos.isEmpty) return 0;
    return _getUniqueVisits().length;
  }

  Widget _buildVisitCard(Visit visit) {
    final client = _lovedPhotos.firstWhere((p) => p.visit.id == visit.id).client;
    final visitPhotos = _getPhotosForVisit(visit);
    final mainPhoto = visitPhotos.isNotEmpty ? visitPhotos.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      elevation: AppTheme.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        side: BorderSide(color: AppTheme.borderLightColor, width: 1),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to the specific visit details while preserving back navigation
          context.pushNamed(
            'visit_details',
            pathParameters: {'visitId': visit.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Row(
            children: [
              // Photo thumbnail (if available)
              if (mainPhoto?.photoUrl != null) ...[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CachedImage(
                    imageUrl: mainPhoto!.photoUrl!,
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
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
              ],

              // Visit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Client: ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            client.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Date: ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          visit.formattedVisitDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Consumer<ServiceProvider>(
                      builder: (context, serviceProvider, child) {
                        final service = visit.serviceId != null && visit.serviceId!.isNotEmpty
                            ? serviceProvider.getServiceById(visit.serviceId!)
                            : null;
                        return Row(
                          children: [
                            Icon(
                              Icons.design_services,
                              size: 16,
                              color: AppTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Service: ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                service?.name ?? 'Styling session',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes,
                            size: 16,
                            color: AppTheme.secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Notes: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              visit.notes!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryTextColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Photos: ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${visit.photos?.length ?? 0} photo${(visit.photos?.length ?? 0) != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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