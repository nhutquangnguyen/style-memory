import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/store.dart';
import '../../services/store_image_service.dart';
import '../../widgets/common/cached_image.dart';
import '../../l10n/app_localizations.dart';

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  bool _isUploading = false;
  bool _useSalonWatermark = false;

  @override
  void initState() {
    super.initState();
    _loadWatermarkSetting();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<StoresProvider>(
      builder: (context, storesProvider, child) {
        final store = storesProvider.currentStore;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: CustomScrollView(
            slivers: [
              // App bar with cover image
              _buildSliverAppBar(store),

              // Store information content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTheme.spacingMedium),

                      // Store basic info section
                      _buildBasicInfoSection(store, l10n),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // Watermark settings section
                      _buildWatermarkSection(l10n),

                      const SizedBox(height: AppTheme.spacingLarge),



                      const SizedBox(height: AppTheme.spacing4xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build sliver app bar with cover image
  Widget _buildSliverAppBar(Store? store) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed('home');
          }
        },
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showImagePickerDialog(StoreImageType.cover),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: store?.hasCover == true
            ? _buildCoverImage(store!)
            : _buildDefaultCover(),
      ),
    );
  }

  // Build cover image
  Widget _buildCoverImage(Store store) {
    return FutureBuilder<String?>(
      future: StoreImageService.getStoreImageUrl(store.cover!),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return CachedImage(
            imageUrl: snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: _buildDefaultCover(),
            errorWidget: _buildDefaultCover(),
          );
        }
        return _buildDefaultCover();
      },
    );
  }

  // Build default cover
  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              'Add Cover Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Tap camera icon to add cover',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build basic info section
  Widget _buildBasicInfoSection(Store? store, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Store Avatar with edit button
                Stack(
                  children: [
                    _buildStoreAvatar(store),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showImagePickerDialog(StoreImageType.avatar),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: AppTheme.spacingMedium),

                // Store name with edit button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store?.name ?? 'Store Name',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditDialog('name', store?.name ?? ''),
                            icon: const Icon(Icons.edit, size: 18),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store?.slug != null ? '@${store!.slug}' : 'No URL set',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: store?.slug != null ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditDialog('slug', store?.slug ?? ''),
                            icon: const Icon(Icons.edit, size: 18),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMedium),
            const Divider(),
            const SizedBox(height: AppTheme.spacingMedium),

            // Store contact info with edit buttons
            _buildEditableInfoRow(
              Icons.location_on_outlined,
              'Address',
              store?.address ?? 'Add address',
              () => _showEditDialog('address', store?.address ?? ''),
            ),

            const SizedBox(height: AppTheme.spacingSmall),

            _buildEditableInfoRow(
              Icons.phone_outlined,
              'Phone',
              store?.phone ?? 'Add phone number',
              () => _showEditDialog('phone', store?.phone ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  // Build info row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.secondaryTextColor,
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build editable info row with edit button
  Widget _buildEditableInfoRow(IconData icon, String label, String value, VoidCallback onEdit) {
    final isEmpty = value == 'Add address' || value == 'Add phone number';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.secondaryTextColor,
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isEmpty ? AppTheme.secondaryTextColor : null,
                  fontStyle: isEmpty ? FontStyle.italic : null,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, size: 18),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // Show edit dialog for store fields
  void _showEditDialog(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    String title;
    String hint;

    switch (field) {
      case 'name':
        title = 'Edit Store Name';
        hint = 'Enter store name';
        break;
      case 'slug':
        title = 'Edit Store URL';
        hint = 'Enter URL slug (letters, numbers, hyphens only)';
        break;
      case 'address':
        title = 'Edit Address';
        hint = 'Enter store address';
        break;
      case 'phone':
        title = 'Edit Phone Number';
        hint = 'Enter phone number';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: field == 'slug' ? TextCapitalization.none : TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              Navigator.of(context).pop();

              if (newValue != currentValue) {
                await _updateStoreField(field, newValue);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Update specific store field
  Future<void> _updateStoreField(String field, String value) async {
    final storesProvider = context.read<StoresProvider>();
    bool success = false;

    switch (field) {
      case 'name':
        success = await storesProvider.updateStoreName(value);
        break;
      case 'slug':
        success = await storesProvider.updateStoreSlug(value);
        break;
      case 'address':
        success = await storesProvider.updateStoreAddress(value);
        break;
      case 'phone':
        success = await storesProvider.updateStorePhone(value);
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '${field[0].toUpperCase()}${field.substring(1)} updated successfully' : 'Failed to update $field'),
        ),
      );
    }
  }



  // Build store avatar
  Widget _buildStoreAvatar(Store? store) {
    if (_isUploading) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 3,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    if (store?.hasAvatar == true) {
      return FutureBuilder<String?>(
        future: StoreImageService.getStoreImageUrl(store!.avatar!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: CachedImage(
                  imageUrl: snapshot.data!,
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
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

  // Build default avatar
  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 3,
        ),
      ),
      child: Icon(
        Icons.add_photo_alternate,
        size: 32,
        color: AppTheme.primaryColor,
      ),
    );
  }

  // Show image picker dialog
  void _showImagePickerDialog(StoreImageType imageType) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(imageType, false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(imageType, true);
                },
              ),
              if (_hasCurrentImage(imageType))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage(imageType);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Check if current store has the specified image type
  bool _hasCurrentImage(StoreImageType imageType) {
    final currentStore = context.read<StoresProvider>().currentStore;
    if (currentStore == null) return false;

    switch (imageType) {
      case StoreImageType.avatar:
        return currentStore.hasAvatar;
      case StoreImageType.cover:
        return currentStore.hasCover;
    }
  }

  // Pick and upload image
  Future<void> _pickImage(StoreImageType imageType, bool fromCamera) async {
    try {
      final XFile? image;

      switch (imageType) {
        case StoreImageType.avatar:
          image = await StoreImageService.pickAvatarImage(fromCamera: fromCamera);
          break;
        case StoreImageType.cover:
          image = await StoreImageService.pickCoverImage(fromCamera: fromCamera);
          break;
      }

      if (image == null || !mounted) return;

      // Set loading state instead of showing dialog
      setState(() {
        _isUploading = true;
      });

      final imageBytes = await image.readAsBytes();

      if (!mounted) return;

      final storesProvider = context.read<StoresProvider>();
      final currentStore = storesProvider.currentStore;

      if (currentStore == null) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
        return;
      }

      String imagePath;

      switch (imageType) {
        case StoreImageType.avatar:
          imagePath = await StoreImageService.uploadStoreAvatar(
            imageBytes: imageBytes,
            storeId: currentStore.id,
          );
          print('Uploading avatar: $imagePath');
          final success = await storesProvider.updateStoreAvatar(imagePath);
          print('Avatar update success: $success');
          break;
        case StoreImageType.cover:
          imagePath = await StoreImageService.uploadStoreCover(
            imageBytes: imageBytes,
            storeId: currentStore.id,
          );
          print('Uploading cover: $imagePath');
          final success = await storesProvider.updateStoreCover(imagePath);
          print('Cover update success: $success');
          break;
      }

      if (mounted) {
        // Clear image caches to force refresh
        StoreImageService.clearCache();
        ImageCacheManager.instance.clearAll();

        setState(() {
          _isUploading = false;
        });

        // Force refresh the stores provider to reload current store from database
        await storesProvider.loadStores();
        print('Current store after refresh: ${storesProvider.currentStore?.avatar}, ${storesProvider.currentStore?.cover}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${imageType.displayName} updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ${imageType.displayName.toLowerCase()}: $e')),
        );
      }
    }
  }

  // Remove image
  Future<void> _removeImage(StoreImageType imageType) async {
    try {
      final storesProvider = context.read<StoresProvider>();

      switch (imageType) {
        case StoreImageType.avatar:
          await storesProvider.updateStoreAvatar(null);
          break;
        case StoreImageType.cover:
          await storesProvider.updateStoreCover(null);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${imageType.displayName} removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove ${imageType.displayName.toLowerCase()}: $e')),
        );
      }
    }
  }

  // Load watermark setting from SharedPreferences
  Future<void> _loadWatermarkSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _useSalonWatermark = prefs.getBool('use_salon_watermark') ?? false;
      });
    }
  }

  // Save watermark setting to SharedPreferences
  Future<void> _saveWatermarkSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_salon_watermark', value);
    if (mounted) {
      setState(() {
        _useSalonWatermark = value;
      });
    }
  }

  // Build watermark section widget
  Widget _buildWatermarkSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.branding_watermark,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  'Store Branding',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.useSalonWatermark,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                l10n.useSalonWatermarkDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              trailing: Switch.adaptive(
                value: _useSalonWatermark,
                onChanged: (value) => _saveWatermarkSetting(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

}