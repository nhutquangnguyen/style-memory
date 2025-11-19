import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';

class StaffProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;

  // State
  List<Staff> _staff = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Staff> get staff => List.unmodifiable(_staff);
  List<Staff> get activeStaff => _staff.where((s) => s.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get staff member by ID
  Staff? getStaffById(String id) {
    try {
      return _staff.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get staff by specialty
  List<Staff> getStaffBySpecialty(String specialty) {
    return _staff.where((s) =>
      s.isActive &&
      (s.specialty?.toLowerCase().contains(specialty.toLowerCase()) ?? false)
    ).toList();
  }

  // Load all staff for current user
  Future<void> loadStaff() async {
    _setLoading(true);
    _clearError();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('staff')
          .select()
          .eq('user_id', userId)
          .order('name');

      _staff = (response as List)
          .map((json) => Staff.fromJson(json))
          .toList();

      debugPrint('Loaded ${_staff.length} staff members');
    } catch (e) {
      _setError('Failed to load staff: $e');
      debugPrint('Error loading staff: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add new staff member
  Future<bool> addStaff(Staff staff) async {
    _setLoading(true);
    _clearError();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create staff with current user ID
      final newStaff = staff.copyWith(userId: userId);
      final response = await _supabase
          .from('staff')
          .insert(newStaff.toJson())
          .select()
          .single();

      final createdStaff = Staff.fromJson(response);
      _staff.add(createdStaff);
      _staff.sort((a, b) => a.name.compareTo(b.name));

      debugPrint('Added staff: ${createdStaff.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add staff: $e');
      debugPrint('Error adding staff: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing staff member
  Future<bool> updateStaff(Staff staff) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase
          .from('staff')
          .update(staff.toJson())
          .eq('id', staff.id)
          .select()
          .single();

      final updatedStaff = Staff.fromJson(response);
      final index = _staff.indexWhere((s) => s.id == staff.id);

      if (index != -1) {
        _staff[index] = updatedStaff;
        _staff.sort((a, b) => a.name.compareTo(b.name));
      }

      debugPrint('Updated staff: ${updatedStaff.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update staff: $e');
      debugPrint('Error updating staff: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete staff member (soft delete by marking inactive)
  Future<bool> deleteStaff(String staffId) async {
    _setLoading(true);
    _clearError();

    try {
      final staffMember = getStaffById(staffId);
      if (staffMember == null) {
        throw Exception('Staff member not found');
      }

      // Soft delete by marking as inactive
      final updatedStaff = staffMember.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _supabase
          .from('staff')
          .update(updatedStaff.toJson())
          .eq('id', staffId);

      // Update local state
      final index = _staff.indexWhere((s) => s.id == staffId);
      if (index != -1) {
        _staff[index] = updatedStaff;
      }

      debugPrint('Deleted staff: ${staffMember.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete staff: $e');
      debugPrint('Error deleting staff: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Permanently delete staff member (hard delete)
  Future<bool> permanentlyDeleteStaff(String staffId) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase
          .from('staff')
          .delete()
          .eq('id', staffId);

      _staff.removeWhere((s) => s.id == staffId);

      debugPrint('Permanently deleted staff: $staffId');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to permanently delete staff: $e');
      debugPrint('Error permanently deleting staff: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reactivate staff member
  Future<bool> reactivateStaff(String staffId) async {
    _setLoading(true);
    _clearError();

    try {
      final staffMember = getStaffById(staffId);
      if (staffMember == null) {
        throw Exception('Staff member not found');
      }

      final reactivatedStaff = staffMember.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await _supabase
          .from('staff')
          .update(reactivatedStaff.toJson())
          .eq('id', staffId);

      // Update local state
      final index = _staff.indexWhere((s) => s.id == staffId);
      if (index != -1) {
        _staff[index] = reactivatedStaff;
      }

      debugPrint('Reactivated staff: ${staffMember.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reactivate staff: $e');
      debugPrint('Error reactivating staff: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh staff list
  Future<void> refreshStaff() async {
    await loadStaff();
  }

  // Get staff performance statistics
  Map<String, int> getStaffStats() {
    return {
      'total_staff': _staff.length,
      'active_staff': activeStaff.length,
      'inactive_staff': _staff.where((s) => !s.isActive).length,
    };
  }

  // Get available specialties
  List<String> getAvailableSpecialties() {
    final specialties = _staff
        .where((s) => s.isActive && s.specialty != null)
        .map((s) => s.specialty!)
        .toSet()
        .toList();

    specialties.sort();
    return specialties;
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
    _staff.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}