import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientsProvider>(
      builder: (context, clientsProvider, child) {
        return LoadingOverlay(
          isLoading: clientsProvider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Clients'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () {
                    context.goNamed('add_client');
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            body: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search clients...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      clientsProvider.updateSearchQuery(query);
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
                  child: _buildClientsList(clientsProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientsList(ClientsProvider clientsProvider) {
    final clients = clientsProvider.filteredClients;

    if (clients.isEmpty && !clientsProvider.isLoading) {
      if (clientsProvider.searchQuery.isNotEmpty) {
        return const Center(
          child: Text('No clients match your search'),
        );
      } else {
        return EmptyState(
          icon: Icons.people_outline,
          title: 'No clients yet',
          description: 'Add your first client to start tracking their styles',
          actionText: 'Add Client',
          onAction: () => context.goNamed('add_client'),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: clientsProvider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
        ),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return _ClientCard(client: client);
        },
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Consumer<VisitsProvider>(
      builder: (context, visitsProvider, child) {
        final lastVisit = visitsProvider.getLastVisitForClient(client.id);

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryAccentColor.withOpacity(0.2),
              child: Text(
                client.initials,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryButtonColor,
                ),
              ),
            ),
            title: Text(
              client.fullName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.phone != null) ...[
                  const SizedBox(height: AppTheme.spacingVerySmall),
                  Text(
                    client.phone!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
                if (lastVisit != null) ...[
                  const SizedBox(height: AppTheme.spacingVerySmall),
                  Text(
                    'Last visit: ${lastVisit.formattedVisitDate}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.secondaryTextColor,
            ),
            onTap: () {
              context.goNamed(
                'client_profile',
                pathParameters: {'clientId': client.id},
              );
            },
          ),
        );
      },
    );
  }
}