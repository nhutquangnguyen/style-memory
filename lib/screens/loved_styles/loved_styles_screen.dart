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
}

class _LovedStylesScreenState extends State<LovedStylesScreen> {
  List<PhotoWithContext> _lovedPhotos = [];
  List<PhotoWithContext> _filteredPhotos = [];
  bool _isLoading = true;
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
    // Defer loading until after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLovedStyles();
      // Also load services for filtering
      context.read<ServiceProvider>().loadServices();
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
      });
      _applyFilters();
      return;
    }

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
            for (final photo in visit.photos!) {
              // Pre-fetch the photo URL to avoid calling provider during build
              final photoUrl = await visitsProvider.getPhotoUrl(photo.storagePath);
              lovedPhotos.add(PhotoWithContext(
                photo: photo,
                client: client,
                visit: visit,
                photoUrl: photoUrl,
              ));
            }
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
        return _buildVisitCard(visit);
      },
    );
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                        Expanded(
                          child: Text(
                            client.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          visit.formattedVisitDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Styling session',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        visit.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${visitPhotos.length} photo${visitPhotos.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              const Icon(
                Icons.chevron_right,
                color: AppTheme.secondaryTextColor,
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