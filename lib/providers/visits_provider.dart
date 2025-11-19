import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/photo_service.dart';

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
      final visits = await SupabaseService.getVisitsForClient(clientId);
      _visitsByClient[clientId] = visits;
      _lastLoadTimes[clientId] = DateTime.now(); // Cache the load time
    } catch (e) {
      _errorMessage = 'Failed to load visits: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Visit?> getVisit(String visitId) async {
    try {
      return await SupabaseService.getVisit(visitId);
    } catch (e) {
      _errorMessage = 'Failed to load visit: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> createVisitWithPhotos({
    required String clientId,
    required Map<PhotoType, Uint8List> photos,
    String? serviceType,
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
        serviceType: serviceType?.trim(),
        notes: notes?.trim(),
        productsUsed: productsUsed?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdVisit = await SupabaseService.createVisit(visit);

      // Upload photos and create photo records
      for (final entry in photos.entries) {
        final photoType = entry.key;
        final photoData = entry.value;

        // Compress photo
        final compressedPhoto = await PhotoService.compressImageBytes(photoData);

        // Upload to storage
        final storagePath = await SupabaseService.uploadPhoto(
          photoData: compressedPhoto,
          userId: userId,
          visitId: visitId,
          photoType: photoType,
        );

        // Create photo record
        final photo = Photo(
          id: const Uuid().v4(),
          visitId: visitId,
          userId: userId,
          storagePath: storagePath,
          photoType: photoType,
          fileSize: compressedPhoto.length,
          createdAt: DateTime.now(),
        );

        await SupabaseService.createPhoto(photo);
      }

      // Add to local list (ensure clientId exists in cache)
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
      return await SupabaseService.getPhotoUrl(storagePath);
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

  Future<void> refreshVisitsForClient(String clientId) async {
    // Force refresh by clearing cache for this client
    _lastLoadTimes.remove(clientId);
    await loadVisitsForClient(clientId);
  }

  // Method to force refresh all client visits (clear all cache)
  Future<void> forceRefreshAll() async {
    _lastLoadTimes.clear();
    _visitsByClient.clear();
    notifyListeners();
  }
}