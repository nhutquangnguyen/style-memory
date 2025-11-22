import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/visits/visit_card.dart';
import '../../widgets/common/modern_button.dart';
import '../../widgets/common/modern_input.dart';
import '../../widgets/client/client_avatar.dart';
import '../loved_styles/loved_styles_screen.dart';
import '../../l10n/app_localizations.dart';

class ClientProfileScreen extends StatefulWidget {
  final String clientId;

  const ClientProfileScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String? _selectedServiceId;
  bool _showSearchBar = false;

  // Client details expansion state - using ValueNotifier to prevent full widget rebuilds
  final ValueNotifier<bool> _isClientDetailsExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitsProvider>().refreshVisitsForClient(widget.clientId);
      context.read<ServiceProvider>().loadServices();
      context.read<StaffProvider>().loadStaff(); // Load staff data for visit cards
      _preloadImages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isClientDetailsExpandedNotifier.dispose();
    super.dispose();
  }

  void _preloadImages() async {
    // Wait a bit to let the visits load first
    await Future.delayed(const Duration(milliseconds: 300)); // Reduced delay

    if (!mounted) return;

    // Preload images in parallel for faster loading
    final visitsProvider = context.read<VisitsProvider>();
    final visits = visitsProvider.getVisitsForClient(widget.clientId);

    final cacheManager = ImageCacheManager.instance;
    final preloadTasks = <Future<void>>[];

    // Create parallel preload tasks for better performance
    for (final visit in visits) {
      if (visit.photos != null) {
        for (final photo in visit.photos!) {
          final task = _preloadSingleImage(visitsProvider, cacheManager, photo.storagePath);
          preloadTasks.add(task);
        }
      }
    }

    // Execute all preloading tasks in parallel (limit concurrency to avoid overwhelming)
    final batches = <List<Future<void>>>[];
    const batchSize = 10; // Process 10 images at a time
    for (int i = 0; i < preloadTasks.length; i += batchSize) {
      final end = (i + batchSize < preloadTasks.length) ? i + batchSize : preloadTasks.length;
      batches.add(preloadTasks.sublist(i, end));
    }

    for (final batch in batches) {
      if (mounted) {
        await Future.wait(batch);
        // Small delay between batches to prevent UI blocking
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  Future<void> _preloadSingleImage(VisitsProvider visitsProvider, ImageCacheManager cacheManager, String storagePath) async {
    try {
      final url = await visitsProvider.getPhotoUrl(storagePath);
      if (url != null && mounted) {
        cacheManager.preloadImage(url); // Remove await - this method doesn't return Future
      }
    } catch (e) {
      // Ignore preload errors - don't block other images
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = context.read<ClientsProvider>().getClientById(widget.clientId);

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Not Found')),
        body: const Center(
          child: Text('Client not found'),
        ),
      );
    }

    return Consumer<VisitsProvider>(
      builder: (context, visitsProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        return LoadingOverlay(
          isLoading: visitsProvider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: Text(client.fullName),
              actions: [
                IconButton(
                  onPressed: _toggleSearchBar,
                  icon: Icon(_showSearchBar ? Icons.search_off : Icons.search),
                  tooltip: _showSearchBar ? 'Hide Search' : 'Search Visits',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditClientDialog(context, client);
                        break;
                      case 'delete':
                        _showDeleteClientDialog(context, client);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l10n.editClient),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.deleteClient),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                // Error banner
                if (visitsProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: ErrorBanner(
                      message: visitsProvider.errorMessage!,
                      onDismiss: () => visitsProvider.clearError(),
                      onRetry: () => visitsProvider.refreshVisitsForClient(widget.clientId),
                    ),
                  ),

                // Client avatar and basic info section with expandable details
                _buildExpandableClientSection(client, visitsProvider),

                // Search bar
                if (_showSearchBar) _buildSearchBar(l10n),

                // Visits section
                Expanded(
                  child: _buildVisitsList(visitsProvider, client, l10n),
                ),
              ],
            ),
            floatingActionButton: ModernFab(
              onPressed: () {
                context.goNamed(
                  'capture_photos',
                  pathParameters: {'clientId': widget.clientId},
                );
              },
              icon: Icons.camera_alt_rounded,
              label: l10n.newVisit,
              gradient: AppTheme.primaryGradient,
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandableClientSection(Client client, VisitsProvider visitsProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
        AppTheme.spacingSmall,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isClientDetailsExpandedNotifier,
        builder: (context, isExpanded, child) {
          return Column(
            children: [
              // Client header with dropdown arrow
              _ExpandableClientHeader(
                client: client,
                isExpanded: isExpanded,
                onToggle: () {
                  _isClientDetailsExpandedNotifier.value = !_isClientDetailsExpandedNotifier.value;
                },
              ),

              // Expandable content
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                  ? _buildExpandedClientDetails(client, visitsProvider)
                  : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandedClientDetails(Client client, VisitsProvider visitsProvider) {
    final hasContactInfo = (client.phone?.isNotEmpty ?? false) ||
                          (client.email?.isNotEmpty ?? false) ||
                          client.birthday != null;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.borderRadiusMedium),
          bottomRight: Radius.circular(AppTheme.borderRadiusMedium),
        ),
        border: Border.all(
          color: AppTheme.borderLightColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Information Section
          if (hasContactInfo) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppTheme.iconMd,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),

            // Contact details
            if (client.phone?.isNotEmpty ?? false)
              _buildInfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: client.phone!,
                onTap: () => _callPhone(client.phone!),
              ),

            if (client.email?.isNotEmpty ?? false)
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: client.email!,
                onTap: () => _sendEmail(client.email!),
              ),

            if (client.birthday != null)
              _buildInfoRow(
                icon: Icons.cake_outlined,
                label: 'Birthday',
                value: client.formattedBirthday ?? '',
                onTap: null,
              ),

            const SizedBox(height: AppTheme.spacingLarge),
          ],

          // Client Metrics Section
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: AppTheme.iconMd,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Client Metrics',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),

          // Metrics content
          _buildClientMetricsContent(client, visitsProvider),
        ],
      ),
    );
  }

  Widget _buildClientMetricsContent(Client client, VisitsProvider visitsProvider) {
    final visits = visitsProvider.getVisitsForClient(widget.clientId);

    // Calculate metrics for this client
    final totalVisits = visits.length;
    final lovedVisits = visits.where((visit) => visit.loved == true).length;

    // Calculate recent visits (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentVisits = visits.where((visit) => visit.visitDate.isAfter(thirtyDaysAgo)).length;

    // Find first visit date
    DateTime? firstVisitDate;
    if (visits.isNotEmpty) {
      firstVisitDate = visits.map((v) => v.visitDate).reduce((a, b) => a.isBefore(b) ? a : b);
    }

    // Calculate client lifetime (days since first visit)
    int clientLifetimeDays = 0;
    if (firstVisitDate != null) {
      clientLifetimeDays = now.difference(firstVisitDate).inDays;
    }

    return Column(
      children: [
        // Top row: Total visits and Loved visits
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Visits',
                value: totalVisits.toString(),
                icon: Icons.event_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: _buildMetricCard(
                title: 'Loved Styles',
                value: lovedVisits.toString(),
                icon: Icons.favorite_rounded,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMedium),

        // Bottom row: Recent visits and Client since
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Recent Visits',
                value: recentVisits.toString(),
                subtitle: 'Last 30 days',
                icon: Icons.schedule_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: _buildMetricCard(
                title: 'Client Since',
                value: clientLifetimeDays > 0 ? '${clientLifetimeDays}d' : 'New',
                subtitle: firstVisitDate != null
                  ? '${firstVisitDate.day}/${firstVisitDate.month}/${firstVisitDate.year}'
                  : 'No visits',
                icon: Icons.person_rounded,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingXs,
          horizontal: AppTheme.spacingXs,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _callPhone(String phoneNumber) {
    // TODO: Implement phone call functionality
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call: $phoneNumber')),
    );
  }

  void _sendEmail(String email) {
    // TODO: Implement email functionality
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Email: $email')),
    );
  }



  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderLightColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppTheme.iconSm,
                  color: color,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitsList(VisitsProvider visitsProvider, Client client, AppLocalizations l10n) {
    final allVisits = visitsProvider.getVisitsForClient(widget.clientId);

    if (allVisits.isEmpty && !visitsProvider.isLoading) {
      return EmptyState(
        icon: Icons.camera_alt_outlined,
        title: l10n.noVisitsYet,
        description: l10n.startByCaptureFirstVisit(client.fullName),
        actionText: l10n.newVisit,
        onAction: () {
          context.goNamed(
            'capture_photos',
            pathParameters: {'clientId': widget.clientId},
          );
        },
      );
    }

    // Apply search filters if active
    final filteredVisits = _applyVisitFilters(allVisits);
    final filteredLovedVisits = filteredVisits.where((visit) => visit.loved ?? false).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab Bar - Modern pill style
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppTheme.spacingMedium,
              AppTheme.spacingMedium,
              AppTheme.spacingMedium,
              AppTheme.spacingSmall,
            ),
            padding: const EdgeInsets.all(AppTheme.spacingXs),
            decoration: BoxDecoration(
              color: AppTheme.borderLightColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusFull),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusFull),
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                    spreadRadius: 0,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.zero,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.mutedTextColor,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                Tab(
                  height: 36,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: AppTheme.iconSm,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text('${l10n.recent} (${filteredVisits.length})'),
                    ],
                  ),
                ),
                Tab(
                  height: 36,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: AppTheme.iconSm,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text('${l10n.loved} (${filteredLovedVisits.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          // Tab Views
          Expanded(
            child: TabBarView(
              children: [
                // Recent Visits Tab
                _buildVisitsTabContent(filteredVisits, 'recent', l10n),
                // Loved Visits Tab
                _buildVisitsTabContent(filteredLovedVisits, 'loved', l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Visit> _applyVisitFilters(List<Visit> visits) {
    if (!_showSearchBar) return visits;

    return visits.where((visit) {
      // Apply service filter
      if (_selectedServiceId != null && _selectedServiceId!.isNotEmpty) {
        if (visit.serviceId != _selectedServiceId) {
          return false;
        }
      }

      // Apply notes search filter
      final searchQuery = _searchController.text.toLowerCase().trim();
      if (searchQuery.isNotEmpty) {
        final notesMatch = visit.notes?.toLowerCase().contains(searchQuery) ?? false;
        final serviceNameMatch = visit.serviceName?.toLowerCase().contains(searchQuery) ?? false;

        if (!notesMatch && !serviceNameMatch) {
          return false;
        }
      }

      return true;
    }).toList();
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
    final visitsProvider = context.read<VisitsProvider>();
    final allVisits = visitsProvider.getVisitsForClient(widget.clientId);

    // Get unique service IDs from visits
    final serviceIds = allVisits
        .map((v) => v.serviceId)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    final serviceProvider = context.read<ServiceProvider>();
    return serviceProvider.services
        .where((service) => serviceIds.contains(service.id))
        .toList();
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
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
          // Search input for notes
          ModernInput(
            controller: _searchController,
            label: l10n.searchByNotesOrService,
            hint: l10n.enterSearchTerms,
            prefixIcon: const Icon(Icons.search),
            onChanged: (_) => setState(() {}), // Trigger rebuild for filtering
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
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
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(l10n.allServices),
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
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  IconButton(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all),
                    tooltip: l10n.clearFilters,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsTabContent(List<Visit> visits, String tabType, AppLocalizations l10n) {
    if (visits.isEmpty) {
      if (tabType == 'loved') {
        return _buildEmptyLovedState();
      } else {
        return _buildEmptyRecentState();
      }
    }

    return RefreshIndicator(
      onRefresh: () => context.read<VisitsProvider>().refreshVisitsForClient(widget.clientId),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
        ),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return VisitCard(
            visit: visit,
            onToggleLoved: _toggleLovedVisit,
          );
        },
      ),
    );
  }

  Widget _buildEmptyLovedState() {
    final isFiltered = _showSearchBar && (_searchController.text.isNotEmpty || _selectedServiceId != null);

    return Center(
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
            isFiltered ? 'No loved visits found' : 'No loved visits yet',
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
                  ? 'Try adjusting your search criteria or clear filters to see more loved visits.'
                  : 'Tap the heart icon ❤️ on visit cards to mark your favorite results and see them here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyRecentState() {
    final isFiltered = _showSearchBar && (_searchController.text.isNotEmpty || _selectedServiceId != null);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.camera_alt_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            isFiltered ? 'No visits found' : 'No visits yet',
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
                  ? 'Try adjusting your search criteria or clear filters to see more visits.'
                  : 'Start by capturing photos for this client\'s first visit.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, Client client) {
    context.goNamed(
      'edit_client',
      pathParameters: {'clientId': client.id},
    );
  }

  void _showDeleteClientDialog(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${client.fullName}? This will also delete all their visits and photos. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store references to avoid context issues
              final navigator = Navigator.of(dialogContext);
              final clientsProvider = context.read<ClientsProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop(); // Close dialog first

              try {
                final success = await clientsProvider.deleteClient(client.id);

                if (!mounted) return; // Early exit if widget disposed

                if (success) {
                  // Navigate back to clients list
                  if (context.mounted) {
                    context.pop();
                  }
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete client'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting client: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleLovedVisit(Visit visit) async {
    try {
      // Toggle the loved state (null defaults to false)
      final currentLoved = visit.loved ?? false;
      final newLoved = !currentLoved;
      final updatedVisit = visit.copyWith(loved: newLoved);

      // Update in backend
      final success = await context.read<VisitsProvider>().updateVisitLoved(visit.id, newLoved);

      if (success) {
        // Clear loved styles cache so it shows updated data
        LovedStylesScreen.clearCache();

        // Show feedback to user
        if (mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                (updatedVisit.loved ?? false)
                    ? 'Added to loved visits ❤️'
                    : 'Removed from loved visits',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: (updatedVisit.loved ?? false) ? Colors.red[400] : null,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update visit'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Separate widget to prevent avatar reloading when expansion state changes
class _ExpandableClientHeader extends StatefulWidget {
  final Client client;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandableClientHeader({
    required this.client,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_ExpandableClientHeader> createState() => _ExpandableClientHeaderState();
}

class _ExpandableClientHeaderState extends State<_ExpandableClientHeader> {
  // Cache the static content to prevent rebuilds
  late final Widget _staticContent;

  @override
  void initState() {
    super.initState();
    _staticContent = Row(
      children: [
        // Avatar - this will be cached and won't reload
        ClientAvatar(
          client: widget.client,
          size: 56,
          showBorder: true,
        ),

        const SizedBox(width: AppTheme.spacingMedium),

        // Client basic info - also cached
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.client.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTextColor,
                ),
              ),

              const SizedBox(height: AppTheme.spacingXs),

              const Text(
                'Client',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onToggle,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: AppTheme.borderLightColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Static cached content (avatar + client info)
            Expanded(child: _staticContent),

            // Only the dropdown arrow animates
            AnimatedRotation(
              turns: widget.isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: AppTheme.primaryColor,
                size: AppTheme.iconLg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}