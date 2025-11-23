import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common/loading_overlay.dart';
import '../widgets/common/modern_card.dart';
import '../widgets/common/cached_image.dart';
import '../services/store_image_service.dart';
import '../models/store.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _metrics = {};
  bool _isLoadingMetrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMetrics();
    });
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoadingMetrics = true;
    });

    try {
      final clientsProvider = context.read<ClientsProvider>();
      final visitsProvider = context.read<VisitsProvider>();
      final staffProvider = context.read<StaffProvider>();

      // Load basic data
      await clientsProvider.loadClients();
      await staffProvider.loadStaff();

      // Calculate metrics
      final totalClients = clientsProvider.clients.length;
      final totalStaff = staffProvider.activeStaff.length;

      // Get recent visits count (last 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      int recentVisits = 0;
      int lovedVisits = 0;

      // Calculate visit metrics across all clients
      for (final client in clientsProvider.clients) {
        final visits = visitsProvider.getVisitsForClient(client.id);

        for (final visit in visits) {
          if (visit.visitDate.isAfter(thirtyDaysAgo)) {
            recentVisits++;
          }

          if (visit.loved == true) {
            lovedVisits++;
          }
        }
      }

      setState(() {
        _metrics = {
          'totalClients': totalClients,
          'totalStaff': totalStaff,
          'recentVisits': recentVisits,
          'lovedVisits': lovedVisits,
        };
        _isLoadingMetrics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMetrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<StoresProvider>(
      builder: (context, storesProvider, child) {
        return LoadingOverlay(
          isLoading: storesProvider.isLoading,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: Text(
                l10n.welcomeToStyleMemory,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: _loadMetrics,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.refresh,
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _loadMetrics,
              color: AppTheme.primaryColor,
              backgroundColor: AppTheme.surfaceColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Information Card
                    _buildStoreInfoCard(storesProvider),

                    const SizedBox(height: AppTheme.spacingLarge),

                    // Business Metrics Section
                    _buildMetricsSection(l10n),

                    const SizedBox(height: AppTheme.spacingLarge),

                    // Quick Actions Section
                    _buildQuickActionsSection(l10n),

                    const SizedBox(height: AppTheme.spacing4xl), // Extra space at bottom
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreInfoCard(StoresProvider storesProvider) {
    final store = storesProvider.currentStore;

    return ModernCard(
      padding: EdgeInsets.zero,
      onTap: () {
        context.go('/store/profile');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image Section
          if (store?.hasCover == true)
            _buildCoverImage(store!)
          else
            _buildDefaultCover(),

          // Store Info Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Row(
              children: [
                // Store Avatar
                _buildStoreAvatar(store),

                const SizedBox(width: AppTheme.spacingMedium),

                // Store Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store?.name ?? 'Style Memory',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (store != null) ...[
                        const SizedBox(height: AppTheme.spacingXs),
                        if (store.address.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: AppTheme.iconSm,
                                color: AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(width: AppTheme.spacingXs),
                              Expanded(
                                child: Text(
                                  store.address,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (store.phone.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingXs),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: AppTheme.iconSm,
                                color: AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(width: AppTheme.spacingXs),
                              Text(
                                store.phone,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.businessOverview,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),

        if (_isLoadingMetrics)
          const ModernCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing4xl),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else ...[
          // Top row: Clients and Staff
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  l10n.totalClients,
                  _metrics['totalClients']?.toString() ?? '0',
                  Icons.people_rounded,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildMetricCard(
                  l10n.activeStaff,
                  _metrics['totalStaff']?.toString() ?? '0',
                  Icons.person_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Bottom row: Recent visits and Loved Styles
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  l10n.recentVisits,
                  '${_metrics['recentVisits'] ?? 0}',
                  Icons.event_rounded,
                  Colors.green,
                  subtitle: l10n.last30Days,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildMetricCard(
                  l10n.lovedStyles,
                  '${_metrics['lovedVisits'] ?? 0}',
                  Icons.favorite_rounded,
                  Colors.red,
                  subtitle: l10n.clientFavorites,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool fullWidth = false,
  }) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppTheme.iconLg,
                  color: color,
                ),
              ),
              if (fullWidth) ...[
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (!fullWidth) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),

        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                l10n.staff,
                l10n.manageTeamMembers,
                Icons.people_alt_rounded,
                AppTheme.primaryColor,
                () => context.goNamed('staff_list'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: _buildActionButton(
                l10n.services,
                l10n.manageServices,
                Icons.content_cut_rounded,
                Colors.purple,
                () => context.goNamed('services'),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingMedium),

        // Settings button (full width)
        _buildActionButton(
          l10n.settings,
          l10n.appSettingsAndConfiguration,
          Icons.settings_rounded,
          Colors.grey[600]!,
          () => context.goNamed('settings'),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool fullWidth = false,
  }) {
    return ModernCard(
      onTap: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppTheme.iconXl,
                  color: color,
                ),
              ),
              if (fullWidth) ...[
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: AppTheme.iconSm,
                  color: AppTheme.mutedTextColor,
                ),
              ],
            ],
          ),
          if (!fullWidth) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build store cover image
  Widget _buildCoverImage(Store store) {
    return Container(
      height: 160,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadiusLarge),
          topRight: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
      child: FutureBuilder<String?>(
        future: StoreImageService.getStoreImageUrl(store.cover!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CachedImage(
              imageUrl: snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 160,
              placeholder: _buildDefaultCover(),
              errorWidget: _buildDefaultCover(),
            );
          }
          return _buildDefaultCover();
        },
      ),
    );
  }

  // Build default cover when no cover image is set
  Widget _buildDefaultCover() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadiusLarge),
          topRight: Radius.circular(AppTheme.borderRadiusLarge),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.primaryColor.withValues(alpha: 0.6),
            AppTheme.primaryColor.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_rounded,
              size: 48,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              'Your Store',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build store avatar
  Widget _buildStoreAvatar(Store? store) {
    if (store?.hasAvatar == true) {
      return FutureBuilder<String?>(
        future: StoreImageService.getStoreImageUrl(store!.avatar!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedImage(
                  imageUrl: snapshot.data!,
                  fit: BoxFit.cover,
                  width: 64,
                  height: 64,
                  placeholder: _buildDefaultAvatar(),
                  errorWidget: _buildDefaultAvatar(),
                ),
              ),
            );
          }
          return _buildDefaultAvatar();
        },
      );
    }

    return _buildDefaultAvatar();
  }

  // Build default avatar when no avatar image is set
  Widget _buildDefaultAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.store_rounded,
        size: 32,
        color: AppTheme.primaryColor,
      ),
    );
  }
}