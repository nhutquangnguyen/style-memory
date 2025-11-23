import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/models.dart';
import '../services/supabase_service.dart';

class StoresProvider extends ChangeNotifier {
  List<Store> _stores = [];
  Store? _currentStore;
  bool _isLoading = false;
  String? _errorMessage;

  List<Store> get stores => _stores;
  Store? get currentStore => _currentStore;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check if user has any stores
  bool get hasStores => _stores.isNotEmpty;

  // Check if current store has custom information
  bool get isCurrentStoreCustomized => _currentStore?.isCustomized ?? false;

  // Get formatted store information for display
  String get formattedStoreInfo => _currentStore?.formattedStoreInfo ?? '';

  /// Initialize stores from Supabase
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      // Load stores from Supabase
      await loadStores();

      // If no stores exist, check for migration from old StoreProvider
      if (_stores.isEmpty) {
        await _migrateFromOldStoreProvider();
      }

      // If still no stores, create a default one
      if (_stores.isEmpty) {
        await _createDefaultStore();
      }

      // Set the first store as current (for now, can be enhanced for multi-store)
      if (_stores.isNotEmpty) {
        _currentStore = _stores.first;
      }
    } catch (e) {
      _setError('Failed to initialize stores: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all stores for the current user
  Future<void> loadStores() async {
    try {
      final stores = await SupabaseService.getUserStores();
      _stores = stores;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load stores: $e');
      rethrow;
    }
  }

  /// Create a new store
  Future<bool> createStore({
    required String name,
    String phone = '',
    String address = '',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final newStore = Store.create(
        ownerId: userId,
        name: name,
        phone: phone,
        address: address,
      );

      final createdStore = await SupabaseService.createStore(newStore);

      _stores.add(createdStore);

      // Set as current store if it's the first one
      if (_currentStore == null) {
        _currentStore = createdStore;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create store: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing store
  Future<bool> updateStore(Store store) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedStore = await SupabaseService.updateStore(store);

      // Update in local list
      final index = _stores.indexWhere((s) => s.id == store.id);
      if (index != -1) {
        _stores[index] = updatedStore;
      }

      // Update current store if it's the one being updated
      if (_currentStore?.id == store.id) {
        _currentStore = updatedStore;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update store: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update store name
  Future<bool> updateStoreName(String name) async {
    if (_currentStore == null) return false;

    final updatedStore = _currentStore!.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );

    return await updateStore(updatedStore);
  }

  /// Update store phone
  Future<bool> updateStorePhone(String phone) async {
    if (_currentStore == null) return false;

    final updatedStore = _currentStore!.copyWith(
      phone: phone,
      updatedAt: DateTime.now(),
    );

    return await updateStore(updatedStore);
  }

  /// Update store address
  Future<bool> updateStoreAddress(String address) async {
    if (_currentStore == null) return false;

    final updatedStore = _currentStore!.copyWith(
      address: address,
      updatedAt: DateTime.now(),
    );

    return await updateStore(updatedStore);
  }

  /// Update store slug
  Future<bool> updateStoreSlug(String slug) async {
    if (_currentStore == null) return false;

    final updatedStore = _currentStore!.copyWith(
      slug: slug.isEmpty ? null : slug,
      updatedAt: DateTime.now(),
    );

    return await updateStore(updatedStore);
  }

  /// Update store avatar
  Future<bool> updateStoreAvatar(String? avatarPath) async {
    if (_currentStore == null) return false;

    final updatedStore = _currentStore!.copyWith(
      avatar: avatarPath,
      updatedAt: DateTime.now(),
    );

    return await updateStore(updatedStore);
  }

  /// Update store cover
  Future<bool> updateStoreCover(String? coverPath) async {
    if (_currentStore == null) return false;

    final updatedStore = _currentStore!.copyWith(
      cover: coverPath,
      updatedAt: DateTime.now(),
    );

    return await updateStore(updatedStore);
  }

  /// Delete a store
  Future<bool> deleteStore(String storeId) async {
    _setLoading(true);
    _clearError();

    try {
      await SupabaseService.deleteStore(storeId);

      _stores.removeWhere((s) => s.id == storeId);

      // If we deleted the current store, set a new one or null
      if (_currentStore?.id == storeId) {
        _currentStore = _stores.isNotEmpty ? _stores.first : null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete store: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Switch to a different store (for multi-store support)
  void setCurrentStore(String storeId) {
    final store = _stores.firstWhere(
      (s) => s.id == storeId,
      orElse: () => _stores.isNotEmpty ? _stores.first : throw Exception('Store not found'),
    );

    _currentStore = store;
    notifyListeners();
  }

  /// Refresh stores from server
  Future<void> refresh() async {
    await loadStores();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  // Private methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Create a default store for new users
  Future<void> _createDefaultStore() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await createStore(name: 'My Salon');
  }

  /// Migrate data from old StoreProvider (SharedPreferences)
  Future<void> _migrateFromOldStoreProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeInfoJson = prefs.getString('store_info');

      if (storeInfoJson != null) {
        final storeData = json.decode(storeInfoJson) as Map<String, dynamic>;
        final oldStoreInfo = StoreInfo.fromJson(storeData);

        // Only migrate if it's not the default store or has custom data
        if (oldStoreInfo.name != 'My Salon' ||
            oldStoreInfo.phone.isNotEmpty ||
            oldStoreInfo.address.isNotEmpty) {

          debugPrint('Migrating store data from SharedPreferences to Supabase...');

          await createStore(
            name: oldStoreInfo.name.isNotEmpty ? oldStoreInfo.name : 'My Salon',
            phone: oldStoreInfo.phone,
            address: oldStoreInfo.address,
          );

          // Remove old data after successful migration
          await prefs.remove('store_info');
          debugPrint('Migration completed successfully');
        }
      }
    } catch (e) {
      debugPrint('Migration from old store provider failed: $e');
      // Don't throw error, just log it - we'll create default store instead
    }
  }
}