import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/empty_state.dart';

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
      context.read<VisitsProvider>().loadVisitsForClient(widget.clientId);
    });
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
                // Client info header
                _buildClientHeader(client),

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
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                context.goNamed(
                  'capture_photos',
                  pathParameters: {'clientId': widget.clientId},
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientHeader(Client client) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryAccentColor.withOpacity(0.2),
            child: Text(
              client.initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryButtonColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            client.fullName,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (client.phone != null || client.email != null) ...[
            const SizedBox(height: AppTheme.spacingSmall),
            if (client.phone != null)
              Text(
                client.phone!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            if (client.email != null)
              Text(
                client.email!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitsList(VisitsProvider visitsProvider, Client client) {
    final visits = visitsProvider.getVisitsForClient(widget.clientId);

    if (visits.isEmpty && !visitsProvider.isLoading) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Text(
            'Recent Visits (${visits.length})',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 18,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => visitsProvider.refreshVisitsForClient(widget.clientId),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
              ),
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final visit = visits[index];
                return _VisitCard(visit: visit);
              },
            ),
          ),
        ),
      ],
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${client.fullName}? This will also delete all their visits and photos. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context
                  .read<ClientsProvider>()
                  .deleteClient(client.id);
              if (success && mounted) {
                context.pop(); // Go back to clients list
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

class _VisitCard extends StatelessWidget {
  final Visit visit;

  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: InkWell(
        onTap: () {
          context.goNamed(
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
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.secondaryTextColor,
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
      height: 60,
      child: Row(
        children: photos.take(4).map((photo) {
          return Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
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
          child: Image.network(
            snapshot.data!,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                ),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
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
            },
          ),
        );
      },
    );
  }
}