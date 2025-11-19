import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';
import '../services/photo_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Photos & Notes'),
            Text(
              widget.client.fullName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Staff Selection
            Consumer<StaffProvider>(
              builder: (context, staffProvider, child) {
                final activeStaff = staffProvider.activeStaff;

                return DropdownButtonFormField<Staff>(
                  initialValue: _selectedStaff,
                  decoration: const InputDecoration(
                    labelText: 'Staff Member',
                    hintText: 'Select who performed this service',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: activeStaff.map((staff) {
                    return DropdownMenuItem<Staff>(
                      value: staff,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.purple.withValues(alpha: 0.2),
                            child: Text(
                              staff.initials,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  staff.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (staff.specialty != null)
                                  Text(
                                    staff.specialty!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
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
                  isExpanded: true,
                );
              },
            ),
            const SizedBox(height: 16),

            // Notes Section
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add your notes about the service, products used, client preferences, etc...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Photo Selection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photos (${_selectedImages.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    // Photo Grid
                    if (_selectedImages.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                    const SizedBox(height: 12),

                    // Photo Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade300,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _isUploading ? null : _saveVisit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Uploading...'),
                      ],
                    )
                  : const Text('Save Visit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null && mounted) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
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
      final List<XFile> photos = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        limit: 10, // Limit to prevent memory issues
      );

      if (photos.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(photos);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: ${e.toString()}'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo or some notes'),
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
        serviceType: null, // Service type removed
        rating: null, // Rating removed
        loved: false, // Default to not loved
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photos: [],
      );

      // Save visit and get the ID
      final savedVisit = await SupabaseService.createVisit(visit);

      // Upload photos if any
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          final imageFile = _selectedImages[i];
          final originalBytes = await File(imageFile.path).readAsBytes();

          // Compress image for better storage and performance
          final compressedBytes = await PhotoService.compressImageBytes(originalBytes);

          // Upload compressed image to storage
          final storagePath = await SupabaseService.uploadPhoto(
            photoData: compressedBytes,
            userId: SupabaseService.currentUser!.id,
            visitId: savedVisit.id,
            photoType: PhotoType.front, // For simplicity, all photos are 'front'
          );

          // Create photo record
          final photo = Photo(
            id: '', // Will be generated
            visitId: savedVisit.id,
            userId: SupabaseService.currentUser!.id,
            storagePath: storagePath,
            photoType: PhotoType.front,
            fileSize: compressedBytes.length, // Use compressed size
            createdAt: DateTime.now(),
          );

          await SupabaseService.createPhoto(photo);
        }
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
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Visit saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Store context reference before potential async operations to avoid async context warnings
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error saving visit: $e'),
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}