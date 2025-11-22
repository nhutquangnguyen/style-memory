import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/modern_button.dart';
import '../../widgets/common/modern_input.dart';
import '../../widgets/client/client_avatar.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientsProvider>().loadClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        context.read<ClientsProvider>().updateSearchQuery('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ClientsProvider>(
      builder: (context, clientsProvider, child) {
        return LoadingOverlay(
          isLoading: clientsProvider.isLoading,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: Text(
                l10n.yourClients,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: _toggleSearchBar,
                  icon: Icon(_showSearchBar ? Icons.search_off : Icons.search),
                  tooltip: _showSearchBar ? 'Hide Search' : 'Search Clients',
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar (conditionally visible)
                if (_showSearchBar)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: ModernSearchInput(
                      hint: l10n.searchByNamePhoneEmail,
                      controller: _searchController,
                      onChanged: (query) {
                        clientsProvider.updateSearchQuery(query);
                      },
                      onClear: () {
                        _searchController.clear();
                        clientsProvider.updateSearchQuery('');
                      },
                    ),
                  ),

                // Error banner
                if (clientsProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                    ),
                    child: ErrorBanner(
                      message: clientsProvider.errorMessage!,
                      onDismiss: () => clientsProvider.clearError(),
                      onRetry: () => clientsProvider.refresh(),
                    ),
                  ),

                // Clients list
                Expanded(
                  child: _buildClientsList(clientsProvider, l10n),
                ),
              ],
            ),
            floatingActionButton: ModernFab(
              onPressed: () => context.goNamed('add_client'),
              icon: Icons.person_add_rounded,
              label: l10n.addClient,
              gradient: AppTheme.primaryGradient,
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientsList(ClientsProvider clientsProvider, AppLocalizations l10n) {
    final clients = clientsProvider.filteredClients;

    if (clients.isEmpty && !clientsProvider.isLoading) {
      if (clientsProvider.searchQuery.isNotEmpty) {
        return Center(
          child: ModernCard(
            margin: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: AppTheme.icon3xl,
                  color: AppTheme.mutedTextColor,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  l10n.noClientsFound,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  l10n.tryAdjustingSearch,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                ModernButton(
                  text: l10n.clearSearch,
                  onPressed: () {
                    _searchController.clear();
                    clientsProvider.updateSearchQuery('');
                  },
                  variant: ModernButtonVariant.secondary,
                  size: ModernButtonSize.small,
                ),
              ],
            ),
          ),
        );
      } else {
        return Center(
          child: ModernCard(
            margin: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people_rounded,
                    size: AppTheme.icon3xl,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                Text(
                  l10n.welcomeToStyleMemory,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  l10n.startByAddingFirstClient,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingExtraLarge),
                ModernButton(
                  text: l10n.addYourFirstClient,
                  onPressed: () => context.goNamed('add_client'),
                  icon: Icons.person_add_rounded,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: clientsProvider.refresh,
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMedium,
          AppTheme.spacingMedium, // Add top spacing to match loved styles tab
          AppTheme.spacingMedium,
          AppTheme.spacing4xl, // Extra space for FAB
        ),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return _ModernClientCard(
            client: client,
            onTap: () => context.goNamed(
              'client_profile',
              pathParameters: {'clientId': client.id},
            ),
          );
        },
      ),
    );
  }
}

class _ModernClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;

  const _ModernClientCard({
    required this.client,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VisitsProvider>(
      builder: (context, visitsProvider, child) {
        final lastVisit = visitsProvider.getLastVisitForClient(client.id);

        return ModernCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          onTap: onTap,
          child: Row(
            children: [
              // Avatar
              ClientAvatar(
                client: client,
                size: 56,
                showBorder: true,
              ),
              const SizedBox(width: AppTheme.spacingMedium),

              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),

                    // Birthday info only
                    if (client.birthday != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: AppTheme.iconSm,
                            color: AppTheme.secondaryTextColor,
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          Text(
                            client.formattedBirthday ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                    ],

                    // Last visit info
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        final l10n = AppLocalizations.of(context)!;
                        if (lastVisit != null) {
                          return Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: AppTheme.iconSm,
                                color: AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(width: AppTheme.spacingXs),
                              Text(
                                lastVisit.simpleTimeFormat(l10n),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: AppTheme.iconSm,
                                color: AppTheme.mutedTextColor,
                              ),
                              const SizedBox(width: AppTheme.spacingXs),
                              Text(
                                l10n.noVisitsYet,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedTextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Latest service badge on the right
              if (lastVisit != null) ...[
                const SizedBox(width: AppTheme.spacingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    lastVisit.shortDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],

            ],
          ),
        );
      },
    );
  }
}