import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/star_rating.dart';

class VisitDetailsScreen extends StatefulWidget {
  final String visitId;

  const VisitDetailsScreen({
    super.key,
    required this.visitId,
  });

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  Visit? _visit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisit();
  }

  Future<void> _loadVisit() async {
    final visitsProvider = context.read<VisitsProvider>();
    final visit = await visitsProvider.getVisit(widget.visitId);

    if (mounted) {
      setState(() {
        _visit = visit;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visit Not Found')),
        body: const Center(
          child: Text('Visit not found'),
        ),
      );
    }

    final client = context.read<ClientsProvider>().getClientById(_visit!.clientId);

    return Consumer<VisitsProvider>(
      builder: (context, visitsProvider, child) {
        return LoadingOverlay(
          isLoading: visitsProvider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Fallback navigation to clients list
                    context.go('/clients');
                  }
                },
              ),
              title: Text(client?.fullName ?? 'Visit Details'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditDialog();
                        break;
                      case 'delete':
                        _showDeleteDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Visit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Visit'),
                    ),
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo viewer
                  _buildPhotoViewer(),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // Visit details
                  _buildVisitDetails(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoViewer() {
    final photos = _visit!.photos ?? [];

    if (photos.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppTheme.primaryAccentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: AppTheme.secondaryTextColor,
              ),
              SizedBox(height: 8),
              Text(
                'No photos available',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 500, // Increased from 400 for better viewing
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        color: Colors.grey[100],
      ),
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return Container(
            margin: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            ),
            child: Stack(
              children: [
                // Photo image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  child: _buildPhotoImage(photo),
                ),
                // Overlay with photo info
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    '${index + 1} / ${photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoImage(Photo photo) {
    return FutureBuilder<String?>(
      future: context.read<VisitsProvider>().getPhotoUrl(photo.storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return CachedImage(
          imageUrl: snapshot.data!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: Container(
            width: double.infinity,
            height: double.infinity,
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
          ),
        );
      },
    );
  }

  Widget _buildVisitDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visit Details',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: _visit!.formattedVisitDate,
            ),

            if (_visit!.serviceType != null && _visit!.serviceType!.isNotEmpty)
              _buildDetailRow(
                icon: Icons.content_cut,
                label: 'Service',
                value: _visit!.serviceType!,
              ),

            // Staff member information
            if (_visit!.staffId != null)
              _buildStaffDetailRow(),

            // Rating information
            if (_visit!.rating != null)
              _buildRatingDetailRow(),

            if (_visit!.notes != null && _visit!.notes!.isNotEmpty)
              _buildDetailSection(
                icon: Icons.notes,
                label: 'Notes',
                value: _visit!.notes!,
              ),

            if (_visit!.productsUsed != null && _visit!.productsUsed!.isNotEmpty)
              _buildDetailSection(
                icon: Icons.inventory_2,
                label: 'Products Used',
                value: _visit!.productsUsed!,
              ),

            const SizedBox(height: AppTheme.spacingMedium),

            _buildDetailRow(
              icon: Icons.photo_library,
              label: 'Photos',
              value: '${_visit!.photos?.length ?? 0} photos',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.secondaryTextColor,
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffDetailRow() {
    return Consumer<StaffProvider>(
      builder: (context, staffProvider, child) {
        final staff = staffProvider.getStaffById(_visit!.staffId!);

        if (staff == null) {
          return _buildDetailRow(
            icon: Icons.person_outline,
            label: 'Staff Member',
            value: 'Staff not found',
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.person,
                size: 20,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Member',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingVerySmall),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryAccentColor.withValues(alpha: 0.2),
                          child: Text(
                            staff.initials,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryButtonColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.name,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              if (staff.specialty != null && staff.specialty!.isNotEmpty)
                                Text(
                                  staff.specialty!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingDetailRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.star,
            size: 20,
            color: AppTheme.secondaryTextColor,
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingVerySmall),
                StarRating(
                  rating: _visit!.rating!,
                  size: 20.0,
                  readOnly: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit visit feature coming soon')),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visit'),
        content: const Text(
          'Are you sure you want to delete this visit? This will also delete all photos. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store navigator and context references before async operations
              final navigator = Navigator.of(context);
              final goRouter = GoRouter.of(context);
              final visitsProvider = context.read<VisitsProvider>();

              // Close dialog first
              navigator.pop();

              // Delete the visit
              final success = await visitsProvider.deleteVisit(_visit!.clientId, _visit!.id);

              if (success && mounted) {
                // Navigate back to client profile using go instead of pop
                // Since the visit is deleted, we can't stay on this screen
                goRouter.go('/clients/${_visit!.clientId}');
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
}