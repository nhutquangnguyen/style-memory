import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/visits/visit_card.dart';
import '../../l10n/app_localizations.dart';

class ServiceVisitHistoryScreen extends StatefulWidget {
  final String serviceId;

  const ServiceVisitHistoryScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<ServiceVisitHistoryScreen> createState() => _ServiceVisitHistoryScreenState();
}

class _ServiceVisitHistoryScreenState extends State<ServiceVisitHistoryScreen> {
  List<Visit> _visits = [];
  Map<String, Client> _clients = {}; // Cache clients for display
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServiceVisits();
    });
  }

  Future<void> _loadServiceVisits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final visitsProvider = context.read<VisitsProvider>();
      final clientsProvider = context.read<ClientsProvider>();

      // Load all visits for this service
      final allVisits = await visitsProvider.getVisitsForService(widget.serviceId);

      // Load clients data for the visits
      final clientIds = allVisits.map((v) => v.clientId).toSet();
      final clientsData = <String, Client>{};

      for (final clientId in clientIds) {
        final client = clientsProvider.getClientById(clientId);
        if (client != null) {
          clientsData[clientId] = client;
        }
      }

      setState(() {
        _visits = allVisits;
        _clients = clientsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadServiceVisits();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final serviceProvider = context.watch<ServiceProvider>();
    final service = serviceProvider.getServiceById(widget.serviceId);

    if (service == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Service Not Found'),
        ),
        body: const Center(
          child: Text('Service not found'),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: null,
        ),
        body: Column(
          children: [
            // Service info header
            _buildServiceHeader(service),

            // Error banner
            if (_errorMessage != null) ...[
              ErrorBanner(
                message: _errorMessage!,
                onDismiss: () => setState(() => _errorMessage = null),
                onRetry: _refresh,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Visit list
            Expanded(
              child: _buildVisitsList(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHeader(Service service) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: AppTheme.borderLightColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Service icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.secondaryColor,
                  AppTheme.secondaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.design_services_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),

          // Service details
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
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Created ${_formatDate(service.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: service.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(
                      color: service.isActive
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    service.isActive ? 'Active' : 'Inactive',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: service.isActive ? Colors.green[700] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Visit count badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${_visits.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _visits.length == 1 ? 'Visit' : 'Visits',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildVisitsList(AppLocalizations l10n) {
    if (_visits.isEmpty && !_isLoading) {
      return EmptyState(
        icon: Icons.design_services_outlined,
        title: 'No Visits Yet',
        description: 'This service hasn\'t been used in any visits yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.secondaryColor,
      backgroundColor: AppTheme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMedium,
          0,
          AppTheme.spacingMedium,
          AppTheme.spacing4xl,
        ),
        itemCount: _visits.length,
        itemBuilder: (context, index) {
          final visit = _visits[index];
          final client = _clients[visit.clientId];

          return VisitCard(
            visit: visit,
            client: client,
            onTap: () => context.pushNamed(
              'visit_details',
              pathParameters: {'visitId': visit.id},
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}