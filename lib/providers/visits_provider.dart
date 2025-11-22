import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/photo_service.dart';
import '../services/wasabi_service.dart';

class VisitsProvider extends ChangeNotifier {
  Map<String, List<Visit>> _visitsByClient = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUploading = false;


  // Cache to prevent unnecessary reloads
  Map<String, DateTime> _lastLoadTimes = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;


  List<Visit> getVisitsForClient(String clientId) {
    return _visitsByClient[clientId] ?? [];
  }

  Future<List<Visit>> getVisitsForStaff(String staffId) async {
    try {
      return await _retryOperation(() => SupabaseService.getVisitsForStaff(staffId));
    } catch (e) {
      _errorMessage = _getNetworkErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadVisitsForClient(String clientId) async {
    // Check if we have valid cached data for this client
    final lastLoadTime = _lastLoadTimes[clientId];
    final existingVisits = _visitsByClient[clientId];

    if (existingVisits != null &&
        existingVisits.isNotEmpty &&
        lastLoadTime != null &&
        DateTime.now().difference(lastLoadTime) < _cacheExpiry) {
      // Use cached data - no loading needed
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final visits = await _retryOperation(() => SupabaseService.getVisitsForClient(clientId));
      _visitsByClient[clientId] = visits;
      _lastLoadTimes[clientId] = DateTime.now(); // Cache the load time
    } catch (e) {
      _errorMessage = _getNetworkErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Retry network operations with exponential backoff
  Future<T> _retryOperation<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempt = 0;
    Duration delay = const Duration(seconds: 1);

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow; // Final attempt failed
        }

        // Check if it's a retryable error
        if (_isRetryableError(e)) {
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
        } else {
          rethrow; // Don't retry non-retryable errors
        }
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Check if an error should be retried
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('connection reset by peer') ||
           errorString.contains('network error') ||
           errorString.contains('timeout') ||
           errorString.contains('connection refused') ||
           errorString.contains('host unreachable') ||
           errorString.contains('temporary failure');
  }

  /// Get user-friendly error message
  String _getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('connection reset by peer') ||
        errorString.contains('network error') ||
        errorString.contains('connection refused')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('unauthorized') ||
               errorString.contains('authentication')) {
      return 'Authentication error. Please sign in again.';
    } else {
      return 'Failed to load data. Please try again.';
    }
  }

  Future<Visit?> getVisit(String visitId) async {
    try {
      return await _retryOperation(() => SupabaseService.getVisit(visitId));
    } catch (e) {
      _errorMessage = _getNetworkErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> createVisitWithPhotos({
    required String clientId,
    required Map<PhotoType, Uint8List> photos,
    String? serviceId,
    String? notes,
    String? productsUsed,
    DateTime? visitDate,
  }) async {
    if (!SupabaseService.isAuthenticated) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final visitId = const Uuid().v4();
      final userId = SupabaseService.currentUser!.id;

      // Create visit first
      final visit = Visit(
        id: visitId,
        clientId: clientId,
        userId: userId,
        visitDate: visitDate ?? DateTime.now(),
        serviceId: serviceId?.trim(),
        notes: notes?.trim(),
        productsUsed: productsUsed?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdVisit = await _retryOperation(() => SupabaseService.createVisit(visit));

      // Upload photos in parallel and wait for completion
      if (photos.isNotEmpty) {
        await _uploadPhotosInParallel(photos, visitId, userId);
      }

      // Add to local list after photos are uploaded
      if (!_visitsByClient.containsKey(clientId)) {
        _visitsByClient[clientId] = [];
      }
      _visitsByClient[clientId]!.insert(0, createdVisit);
      // Update cache timestamp since we added a new visit
      _lastLoadTimes[clientId] = DateTime.now();

      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create visit: $e';
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload photos in parallel and wait for completion (blocking)
  Future<void> _uploadPhotosInParallel(
    Map<PhotoType, Uint8List> photos,
    String visitId,
    String userId,
  ) async {
    // Create list of upload futures for parallel execution
    final uploadFutures = photos.entries.map((entry) async {
      try {
        final photoType = entry.key;
        final photoData = entry.value;

        // Compress photo
        final compressedPhoto = await PhotoService.compressImageBytes(photoData);

        // Upload to Wasabi storage
        final extension = 'jpg';
        final customPath = 'photos/$userId/$visitId/${photoType.name}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        await WasabiService.uploadPhotoFromBytes(
          compressedPhoto,
          extension,
          customPath: customPath,
        );

        // Create photo record with Wasabi object path
        final photo = Photo(
          id: const Uuid().v4(),
          visitId: visitId,
          userId: userId,
          storagePath: 'wasabi:$customPath',
          photoType: photoType,
          fileSize: compressedPhoto.length,
          createdAt: DateTime.now(),
        );

        await SupabaseService.createPhoto(photo);

        return photo;
      } catch (e) {
        debugPrint('Failed to upload photo ${entry.key.name}: $e');
        return null;
      }
    }).toList();

    // Execute all uploads in parallel and wait for completion
    await Future.wait(uploadFutures);
  }


  Future<bool> updateVisit(Visit visit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedVisit = visit.copyWith(
        updatedAt: DateTime.now(),
      );

      await SupabaseService.updateVisit(updatedVisit);

      // Update in local list
      if (_visitsByClient.containsKey(visit.clientId)) {
        final visits = _visitsByClient[visit.clientId]!;
        final index = visits.indexWhere((v) => v.id == visit.id);
        if (index != -1) {
          visits[index] = updatedVisit;
          // Update cache timestamp since we modified a visit
          _lastLoadTimes[visit.clientId] = DateTime.now();
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update visit: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVisitLoved(String visitId, bool loved) async {
    try {
      await SupabaseService.updateVisitLoved(visitId, loved);

      // Update in local lists
      for (final visits in _visitsByClient.values) {
        final index = visits.indexWhere((v) => v.id == visitId);
        if (index != -1) {
          final updatedVisit = visits[index].copyWith(
            loved: loved,
            updatedAt: DateTime.now(),
          );
          visits[index] = updatedVisit;
          break;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update visit loved status: $e';
      return false;
    }
  }

  Future<bool> deleteVisit(String clientId, String visitId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.deleteVisit(visitId);

      // Remove from local list
      if (_visitsByClient.containsKey(clientId)) {
        _visitsByClient[clientId]!.removeWhere((v) => v.id == visitId);
        // Update cache timestamp since we removed a visit
        _lastLoadTimes[clientId] = DateTime.now();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete visit: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> getPhotoUrl(String storagePath) async {
    try {
      // For new Wasabi integration, storagePath starts with 'wasabi:'
      if (storagePath.startsWith('wasabi:')) {
        final objectName = storagePath.substring(7); // Remove 'wasabi:' prefix
        final presignedUrl = await WasabiService.getPresignedUrl(objectName, expiry: const Duration(hours: 1));
        return presignedUrl;
      }

      // For legacy Wasabi URLs (full URLs from previous uploads)
      if (storagePath.startsWith('https://s3.') && storagePath.contains('wasabisys.com')) {
        // Extract object name from full URL and generate presigned URL
        final uri = Uri.parse(storagePath);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final objectName = pathSegments.skip(1).join('/'); // Skip bucket name
          final presignedUrl = await WasabiService.getPresignedUrl(objectName, expiry: const Duration(hours: 1));
          return presignedUrl;
        }
      }

      // Fallback for old Supabase storage paths
      final supabaseUrl = await SupabaseService.getPhotoUrl(storagePath);
      return supabaseUrl;
    } catch (e) {
      _errorMessage = 'Failed to get photo URL: $e';
      notifyListeners();
      return null;
    }
  }

  Visit? getLastVisitForClient(String clientId) {
    final visits = _visitsByClient[clientId];
    if (visits != null && visits.isNotEmpty) {
      return visits.first; // Already sorted by visit_date desc
    }
    return null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get a single visit by ID
  Future<Visit?> getVisitById(String visitId) async {
    try {
      // First check if we have it in cache
      for (final visits in _visitsByClient.values) {
        for (final visit in visits) {
          if (visit.id == visitId) {
            return visit;
          }
        }
      }

      // If not in cache, fetch from database
      final visit = await SupabaseService.getVisitById(visitId);
      return visit;
    } catch (e) {
      _errorMessage = 'Failed to get visit: $e';
      notifyListeners();
      return null;
    }
  }

  /// Delete a single photo from a visit
  Future<bool> deletePhoto(String photoId) async {
    try {
      // Find the photo in cache to get storage path
      String? storagePath;
      for (final visits in _visitsByClient.values) {
        for (final visit in visits) {
          if (visit.photos != null) {
            for (final photo in visit.photos!) {
              if (photo.id == photoId) {
                storagePath = photo.storagePath;
                break;
              }
            }
          }
        }
      }

      if (storagePath == null) {
        throw Exception('Photo not found in cache');
      }

      // Delete from Wasabi storage if it's a Wasabi object
      if (storagePath.startsWith('wasabi:')) {
        final objectName = storagePath.substring(7); // Remove 'wasabi:' prefix
        final wasabiSuccess = await WasabiService.deletePhoto('https://s3.ap-southeast-1.wasabisys.com/style-memory-photos/$objectName');

        if (!wasabiSuccess) {
          throw Exception('Failed to delete photo from Wasabi storage');
        }
      } else if (storagePath.startsWith('https://s3.') && storagePath.contains('wasabisys.com')) {
        // Legacy Wasabi URL format
        final wasabiSuccess = await WasabiService.deletePhoto(storagePath);

        if (!wasabiSuccess) {
          throw Exception('Failed to delete photo from Wasabi storage');
        }
      }

      // Delete photo record from database
      await SupabaseService.deletePhotoRecord(photoId);

      // Remove from local cache if exists
      for (final visits in _visitsByClient.values) {
        for (final visit in visits) {
          if (visit.photos != null) {
            visit.photos!.removeWhere((photo) => photo.id == photoId);
          }
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete photo: $e';
      notifyListeners();
      return false;
    }
  }

  /// Refresh visits for a specific client
  Future<void> refreshVisitsForClient(String clientId) async {
    // Clear cache for this client to force reload
    _lastLoadTimes.remove(clientId);
    _visitsByClient.remove(clientId);
    await loadVisitsForClient(clientId);
  }

  // Method to force refresh all client visits (clear all cache)
  Future<void> forceRefreshAll() async {
    _lastLoadTimes.clear();
    _visitsByClient.clear();
    notifyListeners();
  }
}