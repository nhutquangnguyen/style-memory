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
import '../../widgets/common/star_rating.dart';
import '../../widgets/common/modern_button.dart';
import '../loved_styles/loved_styles_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitsProvider>().refreshVisitsForClient(widget.clientId);
      _preloadImages();
    });
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
        return LoadingOverlay(
          isLoading: visitsProvider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: Text(client.fullName),
              actions: [
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
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Client'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Client'),
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

                // Visits section
                Expanded(
                  child: _buildVisitsList(visitsProvider, client),
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
              label: 'New Visit',
              gradient: AppTheme.primaryGradient,
            ),
          ),
        );
      },
    );
  }


  Widget _buildVisitsList(VisitsProvider visitsProvider, Client client) {
    final allVisits = visitsProvider.getVisitsForClient(widget.clientId);

    if (allVisits.isEmpty && !visitsProvider.isLoading) {
      return EmptyState(
        icon: Icons.camera_alt_outlined,
        title: 'No visits yet',
        description: 'Start by capturing photos for ${client.fullName}\'s first visit',
        actionText: 'New Visit',
        onAction: () {
          context.goNamed(
            'capture_photos',
            pathParameters: {'clientId': widget.clientId},
          );
        },
      );
    }

    // Filter loved visits
    final lovedVisits = allVisits.where((visit) => visit.loved ?? false).toList();

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
                      Text('Recent (${allVisits.length})'),
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
                      Text('Loved (${lovedVisits.length})'),
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
                _buildVisitsTabContent(allVisits, 'recent'),
                // Loved Visits Tab
                _buildVisitsTabContent(lovedVisits, 'loved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsTabContent(List<Visit> visits, String tabType) {
    if (visits.isEmpty && tabType == 'loved') {
      return _buildEmptyLovedState();
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
          return _VisitCard(
            visit: visit,
            onToggleLoved: _toggleLovedVisit,
          );
        },
      ),
    );
  }

  Widget _buildEmptyLovedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'No loved visits yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
            child: Text(
              'Tap the heart icon ❤️ on visit cards to mark your favorite results and see them here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, Client client) {
    // TODO: Implement edit client dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit client feature coming soon')),
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

class _VisitCard extends StatelessWidget {
  final Visit visit;
  final void Function(Visit) onToggleLoved;

  const _VisitCard({
    required this.visit,
    required this.onToggleLoved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'visit_details',
            pathParameters: {'visitId': visit.id},
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    visit.formattedVisitDate,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Heart icon for loved visits
                      GestureDetector(
                        onTap: () => onToggleLoved(visit),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            (visit.loved ?? false) ? Icons.favorite : Icons.favorite_border,
                            color: (visit.loved ?? false) ? Colors.red : AppTheme.secondaryTextColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingVerySmall),
              Text(
                visit.shortDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              // Star rating (always on the left) and staff information
              if (visit.staffId != null || visit.rating != null) ...[
                const SizedBox(height: AppTheme.spacingSmall),
                Row(
                  children: [
                    // Rating always comes first (left side)
                    if (visit.rating != null) ...[
                      StarRating(
                        rating: visit.rating!,
                        size: 16.0,
                        readOnly: true,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                    ],
                    // Staff information takes remaining space
                    if (visit.staffId != null)
                      Expanded(child: _buildStaffInfo(context)),
                  ],
                ),
              ],
              if (visit.photos != null && visit.photos!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMedium),
                _buildPhotoPreview(context, visit.photos!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(BuildContext context, List<Photo> photos) {
    return SizedBox(
      height: 180, // Increased for larger thumbnails
      child: Row(
        children: photos.take(2).map((photo) { // Showing only 2 images for bigger display
          return Container(
            width: 180, // Much larger for better visibility
            height: 180,
            margin: const EdgeInsets.only(right: AppTheme.spacingMedium),
            child: _buildThumbnail(context, photo),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, Photo photo) {
    return FutureBuilder<String?>(
      future: context.read<VisitsProvider>().getPhotoUrl(photo.storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            ),
            child: const Icon(
              Icons.broken_image,
              color: AppTheme.secondaryTextColor,
              size: 20,
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          child: CachedImage(
            imageUrl: snapshot.data!,
            width: 180,
            height: 180,
            fit: BoxFit.cover,
            placeholder: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: const Icon(
                Icons.broken_image,
                color: AppTheme.secondaryTextColor,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffInfo(BuildContext context) {
    return Consumer<StaffProvider>(
      builder: (context, staffProvider, child) {
        final staff = staffProvider.getStaffById(visit.staffId!);

        if (staff == null) {
          return Container(); // Staff not found
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primaryAccentColor.withValues(alpha: 0.2),
              child: Text(
                staff.initials,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryButtonColor,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: Text(
                'by ${staff.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}