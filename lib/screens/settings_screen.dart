import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
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
    // Initialize store provider after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStoreProvider();
    });
  }

  Future<void> _initializeStoreProvider() async {
    if (!mounted) return;

    // Initialize store provider if not already done
    final storeProvider = context.read<StoreProvider>();
    if (!storeProvider.isStoreInfoCustomized && !storeProvider.isLoading) {
      await storeProvider.initialize();
    }

    // Initialize language provider
    if (mounted) {
      final languageProvider = context.read<LanguageProvider>();
      if (!languageProvider.isLoading) {
        await languageProvider.initialize();
      }
    }
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


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settings),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
            children: [
              // Account section
              _buildSectionHeader(context, l10n.account),
              if (authProvider.userProfile != null) ...[
                _buildAccountTile(
                  context,
                  icon: Icons.email_outlined,
                  title: l10n.email,
                  subtitle: authProvider.userProfile!.email,
                  onTap: () => _showEditEmailDialog(context),
                ),
                if (authProvider.userProfile!.fullName != null)
                  _buildAccountTile(
                    context,
                    icon: Icons.person_outline,
                    title: l10n.fullName,
                    subtitle: authProvider.userProfile!.fullName!,
                    onTap: () => _showEditNameDialog(context),
                  ),
              ],

              // Store Information section
              _buildSectionHeader(context, l10n.storeInformation),
              Consumer<StoreProvider>(
                builder: (context, storeProvider, child) {
                  return Column(
                    children: [
                      _buildAccountTile(
                        context,
                        icon: Icons.store_outlined,
                        title: l10n.storeName,
                        subtitle: storeProvider.storeInfo.name.isNotEmpty
                          ? storeProvider.storeInfo.name
                          : l10n.tapToAddStoreName,
                        onTap: () => _showEditStoreNameDialog(context),
                      ),
                      _buildAccountTile(
                        context,
                        icon: Icons.phone_outlined,
                        title: l10n.phone,
                        subtitle: storeProvider.storeInfo.phone.isNotEmpty
                          ? storeProvider.storeInfo.phone
                          : l10n.tapToAddPhone,
                        onTap: () => _showEditStorePhoneDialog(context),
                      ),
                      _buildAccountTile(
                        context,
                        icon: Icons.location_on_outlined,
                        title: l10n.address,
                        subtitle: storeProvider.storeInfo.address.isNotEmpty
                          ? storeProvider.storeInfo.address
                          : l10n.tapToAddAddress,
                        onTap: () => _showEditStoreAddressDialog(context),
                      ),
                    ],
                  );
                },
              ),

              // Language section
              _buildSectionHeader(context, l10n.language),
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return _buildAccountTile(
                    context,
                    icon: Icons.language,
                    title: l10n.language,
                    subtitle: languageProvider.currentLanguageName,
                    onTap: () => _showLanguageDialog(context),
                  );
                },
              ),

              // Management section
              _buildSectionHeader(context, l10n.management),
              _buildAccountTile(
                context,
                icon: Icons.group_work,
                title: l10n.staffManagement,
                subtitle: l10n.manageTeamMembers,
                onTap: () => _navigateToStaffManagement(context),
              ),
              _buildAccountTile(
                context,
                icon: Icons.design_services,
                title: l10n.serviceManagement,
                subtitle: l10n.manageServicesAndPricing,
                onTap: () => _navigateToServiceManagement(context),
              ),

              // Subscription section (placeholder)
              _buildSectionHeader(context, l10n.subscription),
              _buildInfoTile(
                context,
                icon: Icons.workspace_premium_outlined,
                title: l10n.currentPlan,
                subtitle: l10n.freePlan,
              ),
              _buildActionTile(
                context,
                icon: Icons.upgrade_outlined,
                title: l10n.manageSubscription,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.comingSoon)),
                  );
                },
              ),


              // About section
              _buildSectionHeader(context, l10n.about),
              _buildInfoTile(
                context,
                icon: Icons.info_outline,
                title: l10n.appVersion,
                subtitle: _packageInfo?.version ?? l10n.loading,
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
                  child: Text(l10n.signOut),
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


  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
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

  void _showEditStoreNameDialog(BuildContext context) {
    final storeProvider = context.read<StoreProvider>();
    final controller = TextEditingController(text: storeProvider.storeInfo.name);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editStoreName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.storeName,
            hintText: l10n.enterStoreName,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await storeProvider.updateStoreName(newName);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.storeNameUpdated)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.failedToUpdateStoreName)),
                    );
                  }
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditStorePhoneDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storeProvider = context.read<StoreProvider>();
    final controller = TextEditingController(text: storeProvider.storeInfo.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editPhoneNumber),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.phoneNumber,
            hintText: 'Enter your phone number',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newPhone = controller.text.trim();
              try {
                await storeProvider.updateStorePhone(newPhone);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update phone number: $e')),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditStoreAddressDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storeProvider = context.read<StoreProvider>();
    final controller = TextEditingController(text: storeProvider.storeInfo.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editAddress),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.address,
            hintText: 'Enter your store address',
          ),
          textCapitalization: TextCapitalization.words,
          maxLines: 3,
          minLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newAddress = controller.text.trim();
              try {
                await storeProvider.updateStoreAddress(newAddress);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update address: $e')),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LanguageProvider.supportedLocales.map((locale) {
            return ListTile(
              leading: Radio<Locale>(
                value: locale,
                groupValue: languageProvider.currentLocale,
                onChanged: (Locale? value) async {
                  if (value != null && value != languageProvider.currentLocale) {
                    try {
                      await languageProvider.changeLanguage(value);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Language updated successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update language: $e')),
                        );
                      }
                    }
                  }
                },
              ),
              title: Text(languageProvider.getLanguageName(locale)),
              onTap: () async {
                if (locale != languageProvider.currentLocale) {
                  try {
                    await languageProvider.changeLanguage(locale);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.languageUpdated)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update language: $e')),
                      );
                    }
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

}