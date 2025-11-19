import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';

class CapturePhotosScreen extends StatefulWidget {
  final String clientId;

  const CapturePhotosScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<CapturePhotosScreen> createState() => _CapturePhotosScreenState();
}

class _CapturePhotosScreenState extends State<CapturePhotosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initializeCameras();
    });
  }

  @override
  void dispose() {
    context.read<CameraProvider>().disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = context.read<ClientsProvider>().getClientById(widget.clientId);

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Not Found')),
        body: const Center(
          child: Text('Client not found'),
        ),
      );
    }

    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        return LoadingOverlay(
          isLoading: cameraProvider.isCapturing,
          message: 'Capturing photo...',
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Column(
                children: [
                  Text(
                    client.fullName,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    '${cameraProvider.currentStep + 1} / ${cameraProvider.totalSteps}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              actions: [
                if (cameraProvider.isComplete)
                  TextButton(
                    onPressed: () => _proceedToNotes(context, cameraProvider),
                    child: const Text(
                      'Next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            body: Column(
              children: [
                // Camera preview
                Expanded(
                  flex: 3,
                  child: _buildCameraPreview(cameraProvider),
                ),

                // Instructions and controls
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    children: [
                      // Progress indicator
                      _buildProgressIndicator(cameraProvider),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Instructions
                      Text(
                        cameraProvider.currentPhotoType.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      Text(
                        cameraProvider.isComplete
                            ? 'All photos captured! Tap Next to continue.'
                            : cameraProvider.currentInstruction,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // Controls
                      _buildControls(cameraProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview(CameraProvider cameraProvider) {
    if (cameraProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              cameraProvider.errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => cameraProvider.initializeCameras(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!cameraProvider.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // For now, show a placeholder since we don't have actual camera integration
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              color: Colors.white54,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Camera Preview\n(Not implemented in demo)',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(CameraProvider cameraProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: PhotoType.values.map((type) {
        final index = PhotoType.values.indexOf(type);
        final isCompleted = cameraProvider.hasPhoto(type);
        final isCurrent = index == cameraProvider.currentStep && !cameraProvider.isComplete;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isCurrent
                    ? Colors.white
                    : Colors.white30,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControls(CameraProvider cameraProvider) {
    if (cameraProvider.isComplete) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: () => cameraProvider.resetCapture(),
            child: const Text(
              'Start Over',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () => _proceedToNotes(context, cameraProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (cameraProvider.currentStep > 0)
          IconButton(
            onPressed: () => cameraProvider.goToPreviousStep(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          )
        else
          const SizedBox(width: 48),

        // Capture button
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: IconButton(
            onPressed: () => _simulateCapturePhoto(cameraProvider),
            icon: const Icon(
              Icons.camera_alt,
              color: Colors.black,
              size: 32,
            ),
            padding: const EdgeInsets.all(16),
          ),
        ),

        if (cameraProvider.currentStep < cameraProvider.totalSteps - 1)
          IconButton(
            onPressed: cameraProvider.hasPhoto(cameraProvider.currentPhotoType)
                ? () => cameraProvider.goToNextStep()
                : null,
            icon: Icon(
              Icons.arrow_forward,
              color: cameraProvider.hasPhoto(cameraProvider.currentPhotoType)
                  ? Colors.white
                  : Colors.white30,
            ),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  void _simulateCapturePhoto(CameraProvider cameraProvider) {
    // Simulate photo capture with dummy data
    // In a real implementation, this would capture from the camera
    final dummyImageData = List.generate(1000, (i) => i % 256);

    // Capture the current photo type before incrementing step
    final capturedPhotoType = cameraProvider.currentPhotoType;

    // Add to the camera provider's captured photos
    cameraProvider.capturedPhotos[capturedPhotoType] =
        Uint8List.fromList(dummyImageData);

    cameraProvider.goToNextStep();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${capturedPhotoType.displayName} photo captured'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _proceedToNotes(BuildContext context, CameraProvider cameraProvider) {
    // Navigate to add notes screen
    context.goNamed(
      'add_notes',
      queryParameters: {'clientId': widget.clientId},
    );
  }
}