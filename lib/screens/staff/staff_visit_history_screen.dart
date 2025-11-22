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

class StaffVisitHistoryScreen extends StatefulWidget {
  final String staffId;

  const StaffVisitHistoryScreen({
    super.key,
    required this.staffId,
  });

  @override
  State<StaffVisitHistoryScreen> createState() => _StaffVisitHistoryScreenState();
}

class _StaffVisitHistoryScreenState extends State<StaffVisitHistoryScreen> {
  List<Visit> _visits = [];
  Map<String, Client> _clients = {}; // Cache clients for display
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStaffVisits();
    });
  }

  Future<void> _loadStaffVisits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final visitsProvider = context.read<VisitsProvider>();
      final clientsProvider = context.read<ClientsProvider>();

      // Load all visits for this staff member
      final allVisits = await visitsProvider.getVisitsForStaff(widget.staffId);

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
    await _loadStaffVisits();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final staffProvider = context.watch<StaffProvider>();
    final staff = staffProvider.getStaffById(widget.staffId);

    if (staff == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Staff Not Found'),
        ),
        body: const Center(
          child: Text('Staff member not found'),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                staff.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (staff.specialty != null)
                Text(
                  staff.specialty!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
            ],
          ),
          actions: [
            _buildStatsButton(),
          ],
        ),
        body: Column(
          children: [
            // Staff info header
            _buildStaffHeader(staff),

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

  Widget _buildStaffHeader(Staff staff) {
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
          // Staff avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Center(
              child: Text(
                staff.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),

          // Staff details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (staff.specialty != null) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    staff.specialty!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Joined ${staff.formattedHireDate}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedTextColor,
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
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${_visits.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _visits.length == 1 ? 'Visit' : 'Visits',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
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

  Widget _buildStatsButton() {
    return IconButton(
      onPressed: _showStatsDialog,
      icon: const Icon(Icons.analytics_outlined),
      tooltip: 'View Statistics',
    );
  }

  void _showStatsDialog() {
    final totalVisits = _visits.length;
    final ratedVisits = _visits.where((v) => v.rating != null).length;
    final lovedVisits = _visits.where((v) => v.loved == true).length;
    final averageRating = ratedVisits > 0
        ? _visits.where((v) => v.rating != null)
            .map((v) => v.rating!)
            .reduce((a, b) => a + b) / ratedVisits
        : 0.0;
    final uniqueClients = _visits.map((v) => v.clientId).toSet().length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.read<StaffProvider>().getStaffById(widget.staffId)?.name} Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Visits', totalVisits.toString()),
            _buildStatRow('Unique Clients', uniqueClients.toString()),
            _buildStatRow('Loved Styles', lovedVisits.toString()),
            if (ratedVisits > 0) ...[
              _buildStatRow('Average Rating', '${averageRating.toStringAsFixed(1)} ★'),
              _buildStatRow('Rated Visits', '$ratedVisits of $totalVisits'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsList(AppLocalizations l10n) {
    if (_visits.isEmpty && !_isLoading) {
      return EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No Visits Yet',
        description: 'This staff member hasn\'t been assigned to any visits.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primaryColor,
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
}