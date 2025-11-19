import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/modern_button.dart';
import '../../widgets/common/modern_input.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        return LoadingOverlay(
          isLoading: serviceProvider.isLoading,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: const Text('Service Management'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'show_all':
                        // Toggle between active only and all services
                        break;
                      case 'analytics':
                        _showServiceAnalytics(context, serviceProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'show_all',
                      child: Text('Show All Services'),
                    ),
                    const PopupMenuItem(
                      value: 'analytics',
                      child: Text('Service Analytics'),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                // Error banner
                if (serviceProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: ErrorBanner(
                      message: serviceProvider.errorMessage!,
                      onDismiss: () {},
                      onRetry: () => serviceProvider.refreshServices(),
                    ),
                  ),

                // Service list
                Expanded(
                  child: _buildServiceList(serviceProvider),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddServiceDialog(context),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceList(ServiceProvider serviceProvider) {
    final activeServices = serviceProvider.activeServices;

    if (activeServices.isEmpty && !serviceProvider.isLoading) {
      return EmptyState(
        icon: Icons.design_services_outlined,
        title: 'No services yet',
        description: 'Add your first service to get started',
        actionText: 'Add Service',
        onAction: () => _showAddServiceDialog(context),
      );
    }

    return RefreshIndicator(
      onRefresh: serviceProvider.refreshServices,
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMedium,
          0,
          AppTheme.spacingMedium,
          AppTheme.spacing4xl, // Extra space for FAB
        ),
        itemCount: activeServices.length,
        itemBuilder: (context, index) {
          final service = activeServices[index];
          return _ServiceCard(
            service: service,
            onTap: () => _showServiceDetails(context, service),
            onEdit: () => _showEditServiceDialog(context, service),
            onDelete: () => _confirmDeleteService(context, service),
          );
        },
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ServiceDialog(
        title: 'Add Service',
        onSave: (service) async {
          final success = await context.read<ServiceProvider>().addService(service);
          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (context) => _ServiceDialog(
        title: 'Edit Service',
        service: service,
        onSave: (updatedService) async {
          final success = await context.read<ServiceProvider>().updateService(updatedService);
          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showServiceDetails(BuildContext context, Service service) {
    // TODO: Navigate to service details screen
  }

  void _confirmDeleteService(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<ServiceProvider>().deleteService(service.id);
              if (mounted) {
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Service deleted successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showServiceAnalytics(BuildContext context, ServiceProvider serviceProvider) {
    final stats = serviceProvider.getServiceStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnalyticRow('Total Services', '${stats['total_services']}'),
            _AnalyticRow('Active Services', '${stats['active_services']}'),
            _AnalyticRow('Inactive Services', '${stats['inactive_services']}'),
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
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ServiceCard({
    required this.service,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.design_services_rounded,
                    color: AppTheme.primaryColor,
                    size: AppTheme.iconMd,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),

        ],
      ),
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  final String title;
  final Service? service;
  final Function(Service) onSave;

  const _ServiceDialog({
    required this.title,
    this.service,
    required this.onSave,
  });

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModernInput(
              controller: _nameController,
              label: 'Service Name',
              hint: 'Enter service name',
              prefixIcon: Icon(Icons.design_services_rounded),
            ),
          ],
        ),
      ),
      actions: [
        ModernButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
          variant: ModernButtonVariant.secondary,
          size: ModernButtonSize.small,
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        ModernButton(
          text: 'Save',
          onPressed: _saveService,
          variant: ModernButtonVariant.success,
          size: ModernButtonSize.small,
        ),
      ],
    );
  }

  void _saveService() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a service name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final service = Service(
      id: widget.service?.id ?? '',
      userId: widget.service?.userId ?? SupabaseService.currentUser!.id,
      name: _nameController.text.trim(),
      isActive: widget.service?.isActive ?? true,
      createdAt: widget.service?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(service);
  }
}

class _AnalyticRow extends StatelessWidget {
  final String label;
  final String value;

  const _AnalyticRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}