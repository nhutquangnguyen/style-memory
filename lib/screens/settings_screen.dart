import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'staff/staff_list_screen.dart';
import 'services/service_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  void _navigateToStaffManagement(BuildContext context) {
    // Navigate to staff management screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StaffListScreen(),
      ),
    );
  }

  void _navigateToServiceManagement(BuildContext context) {
    // Navigate to service management screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ServiceListScreen(),
      ),
    );
  }

  void _navigateToFullGallery(BuildContext context) {
    // Navigate to full gallery screen
    context.pushNamed('gallery');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
            children: [
              // Account section
              _buildSectionHeader(context, 'Account'),
              if (authProvider.userProfile != null) ...[
                _buildAccountTile(
                  context,
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: authProvider.userProfile!.email,
                  onTap: () => _showEditEmailDialog(context),
                ),
                if (authProvider.userProfile!.fullName != null)
                  _buildAccountTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Full Name',
                    subtitle: authProvider.userProfile!.fullName!,
                    onTap: () => _showEditNameDialog(context),
                  ),
              ],

              // Storage section
              _buildSectionHeader(context, 'Storage'),
              Consumer2<ClientsProvider, VisitsProvider>(
                builder: (context, clientsProvider, visitsProvider, child) {
                  return Column(
                    children: [
                      _buildInfoTile(
                        context,
                        icon: Icons.people_outline,
                        title: 'Total Clients',
                        subtitle: '${clientsProvider.clients.length}',
                      ),
                      _buildInfoTile(
                        context,
                        icon: Icons.photo_library_outlined,
                        title: 'Total Photos',
                        subtitle: _calculateTotalPhotos(visitsProvider).toString(),
                      ),
                      _buildInfoTile(
                        context,
                        icon: Icons.storage_outlined,
                        title: 'Storage Usage',
                        subtitle: 'Coming soon',
                      ),
                    ],
                  );
                },
              ),

              // Management section
              _buildSectionHeader(context, 'Management'),
              _buildAccountTile(
                context,
                icon: Icons.group_work,
                title: 'Staff Management',
                subtitle: 'Manage your team members',
                onTap: () => _navigateToStaffManagement(context),
              ),
              _buildAccountTile(
                context,
                icon: Icons.design_services,
                title: 'Service Management',
                subtitle: 'Manage your services and pricing',
                onTap: () => _navigateToServiceManagement(context),
              ),
              _buildAccountTile(
                context,
                icon: Icons.photo_library,
                title: 'All Photos Gallery',
                subtitle: 'View all photos with search & filter',
                onTap: () => _navigateToFullGallery(context),
              ),

              // Subscription section (placeholder)
              _buildSectionHeader(context, 'Subscription'),
              _buildInfoTile(
                context,
                icon: Icons.workspace_premium_outlined,
                title: 'Current Plan',
                subtitle: 'Free Plan',
              ),
              _buildActionTile(
                context,
                icon: Icons.upgrade_outlined,
                title: 'Manage Subscription',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription management coming soon')),
                  );
                },
              ),

              // Help & Support section
              _buildSectionHeader(context, 'Help & Support'),
              _buildActionTile(
                context,
                icon: Icons.help_outline,
                title: 'FAQ',
                onTap: () => _showFAQDialog(context),
              ),
              _buildActionTile(
                context,
                icon: Icons.contact_support_outlined,
                title: 'Contact Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact support: support@stylememory.com')),
                  );
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.school_outlined,
                title: 'How to Use StyleMemory',
                onTap: () => _showHelpDialog(context),
              ),

              // About section
              _buildSectionHeader(context, 'About'),
              _buildActionTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy')),
                  );
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.gavel_outlined,
                title: 'Terms of Service',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of Service')),
                  );
                },
              ),
              _buildInfoTile(
                context,
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: _packageInfo?.version ?? 'Loading...',
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMedium,
        AppTheme.spacingLarge,
        AppTheme.spacingMedium,
        AppTheme.spacingSmall,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryButtonColor,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.secondaryTextColor),
      title: Text(title),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.secondaryTextColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAccountTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.secondaryTextColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(
              Icons.edit,
              color: AppTheme.secondaryTextColor,
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.secondaryTextColor),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  int _calculateTotalPhotos(VisitsProvider visitsProvider) {
    // This is a simplified calculation
    // In a real app, you'd want to track this more accurately
    return 0; // TODO: Calculate actual photo count
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                context.goNamed('welcome');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit name feature coming soon')),
    );
  }

  void _showEditEmailDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit email feature coming soon')),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Q: How do I add a new client?\n'
                'A: Tap the "+" button on the Clients screen or use the "Add Client" button.\n\n'
                'Q: How do I capture photos?\n'
                'A: From a client\'s profile, tap "New Visit" or the camera icon.\n\n'
                'Q: Can I edit client information?\n'
                'A: Yes, tap the menu icon (⋮) on the client profile screen.\n\n'
                'Q: How do I delete a visit?\n'
                'A: Open the visit details and use the delete option in the menu.',
              ),
            ],
          ),
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use StyleMemory'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Add Clients\n'
                'Start by adding your clients with their basic information.\n\n'
                '2. Capture Photos\n'
                'For each visit, capture 4 photos: front, back, left, and right views.\n\n'
                '3. Add Notes\n'
                'Include service details, products used, and any special notes.\n\n'
                '4. Review History\n'
                'View past visits and photos to remember previous styles.\n\n'
                '5. Stay Organized\n'
                'Use the search feature to quickly find clients.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}