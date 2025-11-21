import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/photo_service.dart';
import '../../services/supabase_service.dart';
import '../../services/wasabi_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/modern_input.dart';
import '../../widgets/common/modern_card.dart';
import '../../l10n/app_localizations.dart';

class EditVisitScreen extends StatefulWidget {
  final String visitId;

  const EditVisitScreen({
    super.key,
    required this.visitId,
  });

  @override
  State<EditVisitScreen> createState() => _EditVisitScreenState();
}

class _EditVisitScreenState extends State<EditVisitScreen> {
  final TextEditingController _notesController = TextEditingController();
  final List<XFile> _newImages = [];
  final List<Photo> _existingPhotos = [];
  final Set<String> _photosToDelete = {};

  Visit? _originalVisit;
  Service? _selectedService;
  Staff? _selectedStaff;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadVisit();
  }

  Future<void> _loadVisit() async {
    setState(() => _isLoading = true);

    try {
      final visitsProvider = context.read<VisitsProvider>();
      final serviceProvider = context.read<ServiceProvider>();
      final staffProvider = context.read<StaffProvider>();

      final visit = await visitsProvider.getVisitById(widget.visitId);

      if (visit != null && mounted) {
        setState(() {
          _originalVisit = visit;
          _notesController.text = visit.notes ?? '';
          _existingPhotos.clear();
          _existingPhotos.addAll(visit.photos ?? []);
        });

        // Load service if exists
        if (visit.serviceId != null) {
          _selectedService = serviceProvider.getServiceById(visit.serviceId!);
        }

        // Load staff if exists
        if (visit.staffId != null) {
          _selectedStaff = staffProvider.getStaffById(visit.staffId!);
        }

        _setupChangeListeners();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load visit: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupChangeListeners() {
    _notesController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles;

      if (source == ImageSource.gallery) {
        pickedFiles = await picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (pickedFiles.length > 10) {
          _showError('Maximum 10 images allowed');
          return;
        }
      } else {
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        pickedFiles = pickedFile != null ? [pickedFile] : [];
      }

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles);
          _markAsChanged();
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      _markAsChanged();
    });
  }

  void _markExistingPhotoForDeletion(String photoId) {
    setState(() {
      if (_photosToDelete.contains(photoId)) {
        _photosToDelete.remove(photoId);
      } else {
        _photosToDelete.add(photoId);
      }
      _markAsChanged();
    });
  }

  Future<void> _saveVisit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_originalVisit == null) return;

    // Validation: At least one photo or notes must exist
    final remainingPhotos = _existingPhotos.where((photo) => !_photosToDelete.contains(photo.id)).length;
    final totalPhotos = remainingPhotos + _newImages.length;
    final hasNotes = _notesController.text.trim().isNotEmpty;

    if (totalPhotos == 0 && !hasNotes) {
      _showError(l10n.pleaseAddPhotoOrNotes);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final visitsProvider = context.read<VisitsProvider>();

      // Update visit data
      final updatedVisit = _originalVisit!.copyWith(
        serviceId: _selectedService?.id,
        staffId: _selectedStaff?.id,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      // Update visit in database
      final success = await visitsProvider.updateVisit(updatedVisit);

      if (!success) {
        _showError('Failed to update visit');
        return;
      }

      // Delete marked photos
      for (final photoId in _photosToDelete) {
        await visitsProvider.deletePhoto(photoId);
      }

      // Upload new photos in parallel
      if (_newImages.isNotEmpty) {
        final currentUserId = SupabaseService.currentUser?.id;
        if (currentUserId != null) {
          await _uploadPhotosInParallel(_newImages, widget.visitId, currentUserId);
        }
      }

      // Refresh the visit data
      await visitsProvider.refreshVisitsForClient(_originalVisit!.clientId);

      if (mounted) {
        context.goNamed('visit_details', pathParameters: {'visitId': widget.visitId});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.visitUpdatedSuccessfully)),
        );
      }
    } catch (e) {
      _showError('Failed to save visit: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showUnsavedChangesDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard changes?'),
        content: Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.goNamed('visit_details', pathParameters: {'visitId': widget.visitId}); // Go back to visit details
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_hasChanges) {
            _showUnsavedChangesDialog();
          } else {
            context.goNamed('visit_details', pathParameters: {'visitId': widget.visitId});
          }
        }
      },
      child: LoadingOverlay(
        isLoading: _isLoading,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(l10n.editVisit),
            actions: [
              TextButton(
                onPressed: _hasChanges ? null : () => context.goNamed('visit_details', pathParameters: {'visitId': widget.visitId}),
                child: Text(l10n.cancel),
              ),
            ],
          ),
          body: _originalVisit == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Staff selection
                          _buildStaffSelection(l10n),
                          const SizedBox(height: AppTheme.spacingMedium),

                          // Service selection
                          _buildServiceSelection(l10n),
                          const SizedBox(height: AppTheme.spacingMedium),

                          // Notes
                          _buildNotesSection(l10n),
                          const SizedBox(height: AppTheme.spacingMedium),

                          // Photos
                          _buildPhotosSection(l10n),
                          const SizedBox(height: AppTheme.spacing4xl),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
          floatingActionButton: _hasChanges ? FloatingActionButton.extended(
            onPressed: _isSaving ? null : _saveVisit,
            backgroundColor: AppTheme.primaryColor,
            icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save, color: Colors.white),
            label: Text(
              _isSaving ? 'Saving...' : l10n.save,
              style: const TextStyle(color: Colors.white),
            ),
          ) : null,
        ),
      ),
    );
  }

  Widget _buildStaffSelection(AppLocalizations l10n) {
    return Consumer<StaffProvider>(
      builder: (context, staffProvider, child) {
        final activeStaff = staffProvider.activeStaff;

        // If the currently selected staff is inactive, include them in the list
        // so the user can see what was previously selected
        final staff = <Staff>[];
        staff.addAll(activeStaff);

        if (_selectedStaff != null &&
            !_selectedStaff!.isActive &&
            !activeStaff.any((s) => s.id == _selectedStaff!.id)) {
          staff.add(_selectedStaff!);
        }

        return ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.staffMember,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              DropdownButtonFormField<Staff>(
                initialValue: _selectedStaff,
                decoration: const InputDecoration(
                  hintText: 'Select staff member',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<Staff>(
                    value: null,
                    child: Text('No staff selected'),
                  ),
                  ...staff.map((staffMember) => DropdownMenuItem<Staff>(
                    value: staffMember,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            staffMember.initials,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Text(
                                      staffMember.name,
                                      style: staffMember.isActive ? null : TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  if (!staffMember.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Inactive',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (staffMember.specialty != null)
                                Text(
                                  staffMember.specialty!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: staffMember.isActive ? null : Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStaff = value;
                    _markAsChanged();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceSelection(AppLocalizations l10n) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        final activeServices = serviceProvider.activeServices;

        // If the currently selected service is inactive, include it in the list
        // so the user can see what was previously selected
        final services = <Service>[];
        services.addAll(activeServices);

        if (_selectedService != null &&
            !_selectedService!.isActive &&
            !activeServices.any((s) => s.id == _selectedService!.id)) {
          services.add(_selectedService!);
        }

        return ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.service,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              DropdownButtonFormField<Service>(
                initialValue: _selectedService,
                decoration: const InputDecoration(
                  hintText: 'Select service type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<Service>(
                    value: null,
                    child: Text('No service selected'),
                  ),
                  ...services.map((service) => DropdownMenuItem<Service>(
                    value: service,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            service.name,
                            style: service.isActive ? null : TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (!service.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedService = value;
                    _markAsChanged();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesSection(AppLocalizations l10n) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.visitNotes,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          ModernInput(
            controller: _notesController,
            hint: l10n.addNotesAboutService,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(AppLocalizations l10n) {
    final totalExistingPhotos = _existingPhotos.where((photo) => !_photosToDelete.contains(photo.id)).length;
    final totalPhotos = totalExistingPhotos + _newImages.length;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.photos} ($totalPhotos)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    tooltip: 'Take Photo',
                  ),
                  IconButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    tooltip: 'Choose from Gallery',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),

          if (totalPhotos == 0)
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Colors.grey[400]),
                    const SizedBox(height: 4),
                    Text('No photos', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.spacingSmall,
                mainAxisSpacing: AppTheme.spacingSmall,
                childAspectRatio: 1,
              ),
              itemCount: _existingPhotos.length + _newImages.length,
              itemBuilder: (context, index) {
                if (index < _existingPhotos.length) {
                  return _buildExistingPhotoItem(_existingPhotos[index]);
                } else {
                  return _buildNewPhotoItem(_newImages[index - _existingPhotos.length], index - _existingPhotos.length);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExistingPhotoItem(Photo photo) {
    final isMarkedForDeletion = _photosToDelete.contains(photo.id);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMarkedForDeletion ? Colors.red : Colors.grey.withValues(alpha: 0.3),
              width: isMarkedForDeletion ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: FutureBuilder<String?>(
              future: Provider.of<VisitsProvider>(context, listen: false).getPhotoUrl(photo.storagePath),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                      if (isMarkedForDeletion)
                        Container(
                          color: Colors.red.withValues(alpha: 0.7),
                          child: const Center(
                            child: Icon(Icons.delete, color: Colors.white, size: 32),
                          ),
                        ),
                    ],
                  );
                }
                return Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _markExistingPhotoForDeletion(photo.id),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isMarkedForDeletion ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMarkedForDeletion ? Icons.undo : Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPhotoItem(XFile image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeNewImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
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
        final bytes = await imageFile.readAsBytes();

        // Compress photo
        final compressedBytes = await PhotoService.compressImageBytes(bytes);

        // Upload to Wasabi storage
        final extension = 'jpg';
        final customPath = 'photos/$userId/$visitId/front_${DateTime.now().millisecondsSinceEpoch}_$index.$extension';
        await WasabiService.uploadPhotoFromBytes(
          compressedBytes,
          extension,
          customPath: customPath,
        );

        // Create photo record in database with Wasabi object path
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
        // Log error silently without printing to console
        return null;
      }
    }).toList();

    // Execute all uploads in parallel
    await Future.wait(uploadFutures);
  }
}