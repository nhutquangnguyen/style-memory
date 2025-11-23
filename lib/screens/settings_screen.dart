import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;
  ImageQuality _selectedImageQuality = ImageQuality.hd;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadImageQualitySetting();
    // Initialize language provider after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLanguageProvider();
    });
  }

  Future<void> _initializeLanguageProvider() async {
    if (!mounted) return;

    try {
      // Initialize language provider
      final languageProvider = context.read<LanguageProvider>();
      if (!languageProvider.isLoading) {
        await languageProvider.initialize();
      }
    } catch (e) {
      debugPrint('Failed to initialize language provider: $e');
    }
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
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
              if (authProvider.userProfile != null)
                _buildInfoTile(
                  context,
                  icon: Icons.email_outlined,
                  title: l10n.email,
                  subtitle: authProvider.userProfile!.email,
                ),

              // Language section
              _buildSectionHeader(context, l10n.language),
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return _buildLanguageSection(context, l10n, languageProvider);
                },
              ),

              // Image Quality section
              _buildSectionHeader(context, l10n.imageQuality),
              _buildImageQualitySection(context, l10n),

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





  // Load image quality setting from SharedPreferences
  Future<void> _loadImageQualitySetting() async {
    final prefs = await SharedPreferences.getInstance();
    final qualityString = prefs.getString('image_quality') ?? 'hd';
    if (mounted) {
      setState(() {
        _selectedImageQuality = ImageQuality.fromString(qualityString);
      });
    }
  }

  // Save image quality setting to SharedPreferences
  Future<void> _saveImageQualitySetting(ImageQuality quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('image_quality', quality.value);
    if (mounted) {
      setState(() {
        _selectedImageQuality = quality;
      });
    }
  }


  // Build image quality section widget
  Widget _buildImageQualitySection(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.photo_camera,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  l10n.imageQuality,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Image quality options
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.imageQualityDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Quality dropdown
                DropdownButtonFormField<ImageQuality>(
                  initialValue: _selectedImageQuality,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall,
                    ),
                  ),
                  items: ImageQuality.values.map((quality) {
                    return DropdownMenuItem<ImageQuality>(
                      value: quality,
                      child: Text(
                        _getQualityDisplayName(quality, l10n),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (ImageQuality? value) {
                    if (value != null) {
                      _saveImageQualitySetting(value);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  _getQualityDescription(_selectedImageQuality, l10n),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get localized display name for image quality
  String _getQualityDisplayName(ImageQuality quality, AppLocalizations l10n) {
    switch (quality) {
      case ImageQuality.raw:
        return l10n.imageQualityRaw;
      case ImageQuality.hd:
        return l10n.imageQualityHd;
      case ImageQuality.compressed:
        return l10n.imageQualityCompressed;
    }
  }

  // Helper method to get localized description for image quality
  String _getQualityDescription(ImageQuality quality, AppLocalizations l10n) {
    switch (quality) {
      case ImageQuality.raw:
        return l10n.imageQualityRawDescription;
      case ImageQuality.hd:
        return l10n.imageQualityHdDescription;
      case ImageQuality.compressed:
        return l10n.imageQualityCompressedDescription;
    }
  }

  // Build language section widget
  Widget _buildLanguageSection(BuildContext context, AppLocalizations l10n, LanguageProvider languageProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Language options
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select your preferred language for the application',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Language dropdown
                DropdownButtonFormField<Locale>(
                  initialValue: languageProvider.currentLocale,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall,
                    ),
                  ),
                  items: LanguageProvider.supportedLocales.map((locale) {
                    return DropdownMenuItem<Locale>(
                      value: locale,
                      child: Text(
                        languageProvider.getLanguageName(locale),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (Locale? value) async {
                    if (value != null && value != languageProvider.currentLocale) {
                      try {
                        await languageProvider.changeLanguage(value);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.languageUpdated)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}