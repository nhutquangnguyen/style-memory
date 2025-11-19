import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../models/models.dart';

class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _errorMessage;

  // Photo capture workflow
  int _currentStep = 0;
  Map<PhotoType, Uint8List> _capturedPhotos = {};
  bool _isCapturing = false;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  int get currentStep => _currentStep;
  bool get isCapturing => _isCapturing;
  Map<PhotoType, Uint8List> get capturedPhotos => _capturedPhotos;

  // Photo types in order
  final List<PhotoType> _photoOrder = [
    PhotoType.front,
    PhotoType.back,
    PhotoType.left,
    PhotoType.right,
  ];

  PhotoType get currentPhotoType {
    if (_currentStep >= _photoOrder.length) {
      return _photoOrder.last; // Return the last photo type if out of bounds
    }
    return _photoOrder[_currentStep];
  }
  int get totalSteps => _photoOrder.length;
  bool get isComplete => _currentStep >= _photoOrder.length;

  String get currentInstruction {
    switch (currentPhotoType) {
      case PhotoType.front:
        return 'Position client facing the camera.\nCapture front view of hairstyle.';
      case PhotoType.back:
        return 'Have client turn around.\nCapture back view of hairstyle.';
      case PhotoType.left:
        return 'Have client turn to the left.\nCapture left side view.';
      case PhotoType.right:
        return 'Have client turn to the right.\nCapture right side view.';
    }
  }

  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        await _initializeCamera(_cameras!.first);
      } else {
        _errorMessage = 'No cameras available';
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
    }
    notifyListeners();
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      _isInitialized = false;
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentCamera = _controller?.description;
    final newCamera = _cameras!.firstWhere(
      (camera) => camera != currentCamera,
      orElse: () => _cameras!.first,
    );

    await disposeCamera();
    await _initializeCamera(newCamera);
  }

  Future<void> capturePhoto() async {
    if (!_isInitialized || _controller == null || _isCapturing) return;

    _isCapturing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      _capturedPhotos[currentPhotoType] = imageBytes;

      // Move to next step
      _currentStep++;

      _isCapturing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to capture photo: $e';
      _isCapturing = false;
      notifyListeners();
    }
  }

  void retakeCurrentPhoto() {
    if (_currentStep > 0) {
      _currentStep--;
      _capturedPhotos.remove(currentPhotoType);
      notifyListeners();
    }
  }

  void goToNextStep() {
    if (_currentStep < _photoOrder.length) {
      _currentStep++;
      notifyListeners();
    }
  }

  void goToPreviousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void resetCapture() {
    _currentStep = 0;
    _capturedPhotos.clear();
    _errorMessage = null;
    notifyListeners();
  }

  bool hasPhoto(PhotoType photoType) {
    return _capturedPhotos.containsKey(photoType);
  }

  Uint8List? getPhoto(PhotoType photoType) {
    return _capturedPhotos[photoType];
  }

  void removePhoto(PhotoType photoType) {
    _capturedPhotos.remove(photoType);
    notifyListeners();
  }

  Future<void> disposeCamera() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}