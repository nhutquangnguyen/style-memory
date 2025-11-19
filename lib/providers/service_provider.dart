import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';

class ServiceProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;

  // State
  List<Service> _services = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Service> get services => List.unmodifiable(_services);
  List<Service> get activeServices => _services.where((s) => s.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get service by ID
  Service? getServiceById(String id) {
    try {
      return _services.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }


  // Load all services for current user
  Future<void> loadServices() async {
    _setLoading(true);
    _clearError();

    try {
      _services = await SupabaseService.getServices();
      debugPrint('Loaded ${_services.length} services');
    } catch (e) {
      _setError('Failed to load services: $e');
      debugPrint('Error loading services: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add new service
  Future<bool> addService(Service service) async {
    _setLoading(true);
    _clearError();

    try {
      final createdService = await SupabaseService.createService(service);
      _services.add(createdService);
      _services.sort((a, b) => a.name.compareTo(b.name));

      debugPrint('Added service: ${createdService.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add service: $e');
      debugPrint('Error adding service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing service
  Future<bool> updateService(Service service) async {
    _setLoading(true);
    _clearError();

    try {
      await SupabaseService.updateService(service);
      final index = _services.indexWhere((s) => s.id == service.id);

      if (index != -1) {
        _services[index] = service;
        _services.sort((a, b) => a.name.compareTo(b.name));
      }

      debugPrint('Updated service: ${service.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update service: $e');
      debugPrint('Error updating service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete service (soft delete by marking inactive)
  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);
    _clearError();

    try {
      final service = getServiceById(serviceId);
      if (service == null) {
        throw Exception('Service not found');
      }

      // Soft delete by marking as inactive
      final updatedService = service.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _supabase
          .from('services')
          .update(updatedService.toJson())
          .eq('id', serviceId);

      // Update local state
      final index = _services.indexWhere((s) => s.id == serviceId);
      if (index != -1) {
        _services[index] = updatedService;
      }

      debugPrint('Deleted service: ${service.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete service: $e');
      debugPrint('Error deleting service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Permanently delete service (hard delete)
  Future<bool> permanentlyDeleteService(String serviceId) async {
    _setLoading(true);
    _clearError();

    try {
      await SupabaseService.deleteService(serviceId);
      _services.removeWhere((s) => s.id == serviceId);

      debugPrint('Permanently deleted service: $serviceId');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to permanently delete service: $e');
      debugPrint('Error permanently deleting service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reactivate service
  Future<bool> reactivateService(String serviceId) async {
    _setLoading(true);
    _clearError();

    try {
      final service = getServiceById(serviceId);
      if (service == null) {
        throw Exception('Service not found');
      }

      final reactivatedService = service.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await _supabase
          .from('services')
          .update(reactivatedService.toJson())
          .eq('id', serviceId);

      // Update local state
      final index = _services.indexWhere((s) => s.id == serviceId);
      if (index != -1) {
        _services[index] = reactivatedService;
      }

      debugPrint('Reactivated service: ${service.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reactivate service: $e');
      debugPrint('Error reactivating service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh services list
  Future<void> refreshServices() async {
    await loadServices();
  }

  // Get service statistics
  Map<String, dynamic> getServiceStats() {
    return {
      'total_services': _services.length,
      'active_services': activeServices.length,
      'inactive_services': _services.where((s) => !s.isActive).length,
    };
  }


  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Clear all state (for logout)
  void clear() {
    _services.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}