import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';
import '../services/photo_service.dart';
import '../services/wasabi_service.dart';
import '../services/image_quality_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/modern_card.dart';
import '../widgets/common/modern_button.dart';
import '../widgets/common/modern_input.dart';
import '../l10n/app_localizations.dart';

class SimplePhotoNotesScreen extends StatefulWidget {
  final Client client;

  const SimplePhotoNotesScreen({
    super.key,
    required this.client,
  });

  @override
  State<SimplePhotoNotesScreen> createState() => _SimplePhotoNotesScreenState();
}

class _SimplePhotoNotesScreenState extends State<SimplePhotoNotesScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();

  List<XFile> _selectedImages = [];
  bool _isUploading = false;
  Staff? _selectedStaff;
  Service? _selectedService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
      context.read<ServiceProvider>().loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addPhotosAndNotes,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.client.fullName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Staff Selection Card
            ModernCard(
              child: Consumer<StaffProvider>(
                builder: (context, staffProvider, child) {
                  final activeStaff = staffProvider.activeStaff;

                  return ModernDropdown<Staff>(
                    label: l10n.staffMember,
                    hint: l10n.selectStaffMember,
                    value: _selectedStaff,
                    items: activeStaff.map((staff) {
                      return DropdownMenuItem<Staff>(
                        value: staff,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                staff.initials,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    staff.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (staff.specialty != null)
                                    Text(
                                      staff.specialty!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.secondaryTextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Staff? newStaff) {
                      setState(() {
                        _selectedStaff = newStaff;
                      });
                    },
                    prefixIcon: Icon(
                      Icons.person_rounded,
                      color: AppTheme.secondaryTextColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            // Service Selection Card
            ModernCard(
              child: Consumer<ServiceProvider>(
                builder: (context, serviceProvider, child) {
                  final activeServices = serviceProvider.activeServices;

                  return ModernDropdown<Service>(
                    label: l10n.serviceType,
                    hint: l10n.selectServiceType,
                    value: _selectedService,
                    items: activeServices.map((service) {
                      return DropdownMenuItem<Service>(
                        value: service,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.design_services_rounded,
                                size: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    service.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Service? newService) {
                      setState(() {
                        _selectedService = newService;
                      });
                    },
                    prefixIcon: Icon(
                      Icons.design_services_rounded,
                      color: AppTheme.secondaryTextColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            // Notes Section
            ModernCard(
              child: ModernInput(
                controller: _notesController,
                label: l10n.visitNotes,
                hint: l10n.addNotesAboutService,
                maxLines: 4,
                variant: ModernInputVariant.filled,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            // Photo Selection Section
            ModernHeaderCard(
              title: l10n.photos,
              subtitle: _selectedImages.isEmpty
                ? l10n.addPhotosToDocument
                : _selectedImages.length == 1
                    ? l10n.onePhotoSelected
                    : '${_selectedImages.length} photos selected',
              leading: Icon(
                Icons.photo_camera_rounded,
                color: AppTheme.primaryColor,
                size: AppTheme.iconLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Grid
                  if (_selectedImages.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppTheme.spacingMedium,
                        mainAxisSpacing: AppTheme.spacingMedium,
                        childAspectRatio: 1,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: AppTheme.spacingXs,
                              right: AppTheme.spacingXs,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [AppTheme.buttonShadow],
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: AppTheme.iconSm,
                                    color: Colors.white,
                                  ),
                                  iconSize: AppTheme.iconSm,
                                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                  ],

                  // Photo Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          text: l10n.camera,
                          onPressed: _pickFromCamera,
                          icon: Icons.camera_alt_rounded,
                          variant: ModernButtonVariant.primary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMedium),
                      Expanded(
                        child: ModernButton(
                          text: l10n.gallery,
                          onPressed: _pickFromGallery,
                          icon: Icons.photo_library_rounded,
                          variant: ModernButtonVariant.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingExtraLarge),

            // Save Button
            ModernButton(
              text: _isUploading ? l10n.savingVisit : l10n.saveVisit,
              onPressed: _isUploading ? null : _saveVisit,
              variant: ModernButtonVariant.success,
              icon: _isUploading ? null : Icons.save_rounded,
              loading: _isUploading,
              fullWidth: true,
              size: ModernButtonSize.large,
            ),
            const SizedBox(height: AppTheme.spacingExtraLarge),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final imageQuality = await ImageQualityService.getImageQuality();
      final isRawQuality = imageQuality.jpegQuality >= 95;

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: isRawQuality ? null : 1920,
        maxHeight: isRawQuality ? null : 1080,
        imageQuality: imageQuality.jpegQuality,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null && mounted) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.cameraError}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Camera error: $e'); // For debugging
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final imageQuality = await ImageQualityService.getImageQuality();
      final isRawQuality = imageQuality.jpegQuality >= 95;

      final List<XFile> photos = await _picker.pickMultiImage(
        maxWidth: isRawQuality ? null : 1920,
        maxHeight: isRawQuality ? null : 1080,
        imageQuality: imageQuality.jpegQuality,
        limit: 10, // Limit to prevent memory issues
      );

      if (photos.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(photos);
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.galleryError}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // Consider using a proper logging framework in production
      print('Gallery error: $e');
    }
  }

  Future<void> _saveVisit() async {
    if (_selectedImages.isEmpty && _notesController.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseAddPhotoOrNotes),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Create visit
      final visit = Visit(
        id: '', // Will be generated by database
        clientId: widget.client.id,
        userId: SupabaseService.currentUser!.id,
        staffId: _selectedStaff?.id, // Include selected staff member
        visitDate: DateTime.now(),
        serviceId: _selectedService?.id, // Include selected service
        rating: null, // Rating removed
        loved: false, // Default to not loved
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photos: [],
      );

      // Save visit and get the ID
      final savedVisit = await SupabaseService.createVisit(visit);

      // Upload photos in parallel if any
      if (_selectedImages.isNotEmpty) {
        await _uploadPhotosInParallel(_selectedImages, savedVisit.id, SupabaseService.currentUser!.id);
      }

      // Refresh the visits list to show the new visit immediately
      if (mounted) {
        // Store context references before async operations to avoid async context warnings
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final visitsProvider = context.read<VisitsProvider>();

        await visitsProvider.refreshVisitsForClient(widget.client.id);

        // Check mounted again after async operation
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(l10n.visitSavedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Store context reference before potential async operations to avoid async context warnings
        final l10n = AppLocalizations.of(context)!;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.errorSavingVisit}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Upload photos in parallel and wait for completion
  Future<void> _uploadPhotosInParallel(
    List<XFile> imageFiles,
    String visitId,
    String userId,
  ) async {
    // Create list of upload futures for parallel execution
    final uploadFutures = imageFiles.asMap().entries.map((entry) async {
      try {
        final index = entry.key;
        final imageFile = entry.value;
        final originalBytes = await File(imageFile.path).readAsBytes();

        // Compress image for better storage and performance
        final compressedBytes = await PhotoService.compressImageBytes(originalBytes);

        // Upload compressed image to Wasabi storage
        final extension = 'jpg';
        final customPath = 'photos/$userId/$visitId/front_${DateTime.now().millisecondsSinceEpoch}_$index.$extension';
        await WasabiService.uploadPhotoFromBytes(
          compressedBytes,
          extension,
          customPath: customPath,
        );

        // Create photo record with Wasabi object path
        final photo = Photo(
          id: '', // Will be generated
          visitId: visitId,
          userId: userId,
          storagePath: 'wasabi:$customPath',
          photoType: PhotoType.front,
          fileSize: compressedBytes.length,
          createdAt: DateTime.now(),
        );

        await SupabaseService.createPhoto(photo);

        return photo;
      } catch (e) {
        debugPrint('Failed to upload photo ${entry.value.name}: $e');
        return null;
      }
    }).toList();

    // Execute all uploads in parallel
    await Future.wait(uploadFutures);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}