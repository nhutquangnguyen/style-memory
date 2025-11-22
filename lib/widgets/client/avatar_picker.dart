import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/client.dart';
import '../../services/avatar_service.dart';
import '../../theme/app_theme.dart';
import 'client_avatar.dart';

class AvatarPicker extends StatefulWidget {
  final Client? client;
  final Function(String?) onAvatarChanged;

  const AvatarPicker({
    super.key,
    this.client,
    required this.onAvatarChanged,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  String? _selectedAvatarUrl;
  XFile? _selectedImageFile;
  bool _isUploading = false;
  bool _avatarRemoved = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = widget.client?.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // Avatar display
        GestureDetector(
          onTap: _showAvatarOptions,
          child: Stack(
            children: [
            // Show selected image file immediately, or existing avatar, or initials
            _selectedImageFile != null
                ? Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.file(
                        File(_selectedImageFile!.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : ClientAvatar(
                    client: widget.client?.copyWith(
                      avatarUrl: _avatarRemoved ? null : _selectedAvatarUrl,
                      clearAvatarUrl: _avatarRemoved,
                    ) ?? Client(
                      id: '',
                      userId: '',
                      fullName: widget.client?.fullName ?? 'New Client',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      avatarUrl: _avatarRemoved ? null : _selectedAvatarUrl,
                    ),
                    size: 80,
                    showBorder: true,
                  ),

            // Loading overlay
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Edit button if not uploading
            if (!_isUploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showAvatarOptions,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        ),

        const SizedBox(height: AppTheme.spacingSmall),

        // Help text
        Text(
          'Tap to change avatar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
        ),
      ],
    );
  }

  void _showAvatarOptions() {

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.spacingMedium),

            // Title
            Text(
              'Choose Avatar',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: AppTheme.spacingMedium),

            // Camera option
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => _pickAvatar(fromCamera: true),
            ),

            // Gallery option
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => _pickAvatar(fromCamera: false),
            ),

            // Remove avatar option (only if avatar exists)
            if (_selectedAvatarUrl != null || _selectedImageFile != null || (widget.client?.avatarUrl != null))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Avatar'),
                onTap: _removeAvatar,
              ),

            const SizedBox(height: AppTheme.spacingMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar({required bool fromCamera}) async {
    Navigator.of(context).pop(); // Close bottom sheet

    try {
      final image = await AvatarService.pickAvatarImage(fromCamera: fromCamera);

      if (image != null) {
        setState(() {
          _selectedImageFile = image;
          _selectedAvatarUrl = null;
          _avatarRemoved = false; // Reset removal flag when new image selected
        });

        // Upload the avatar in background while showing the image immediately
        _uploadAvatar(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAvatar() {
    Navigator.of(context).pop(); // Close bottom sheet

    setState(() {
      _selectedImageFile = null;
      _selectedAvatarUrl = null;
      _avatarRemoved = true; // Mark avatar as removed for immediate UI update
    });

    // Immediately notify parent that avatar was removed
    widget.onAvatarChanged(null);
  }

  Future<void> _uploadAvatar(XFile imageFile) async {
    // For new clients, we need to generate a temporary ID
    final clientId = widget.client?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final userId = widget.client?.userId ?? 'temp_user';

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final avatarUrl = await AvatarService.uploadAvatar(
        imageBytes: bytes,
        userId: userId,
        clientId: clientId,
      );

      setState(() {
        _selectedAvatarUrl = avatarUrl;
        _selectedImageFile = null; // Clear the local file since upload is complete
        _isUploading = false;
      });

      // Notify parent with the new avatar URL
      widget.onAvatarChanged(avatarUrl);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}