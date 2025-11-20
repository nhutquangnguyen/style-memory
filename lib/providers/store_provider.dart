import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/store_info.dart';

class StoreProvider with ChangeNotifier {
  StoreInfo _storeInfo = StoreInfo.defaultStore;
  bool _isLoading = false;

  StoreInfo get storeInfo => _storeInfo;
  bool get isLoading => _isLoading;

  // Keys for SharedPreferences
  static const String _storeInfoKey = 'store_info';

  // Initialize and load store info from local storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadStoreInfo();
    } catch (e) {
      debugPrint('Error initializing store provider: $e');
      // Keep default values if loading fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load store info from SharedPreferences
  Future<void> _loadStoreInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeInfoJson = prefs.getString(_storeInfoKey);

      if (storeInfoJson != null) {
        final Map<String, dynamic> json = jsonDecode(storeInfoJson);
        _storeInfo = StoreInfo.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading store info: $e');
      // Keep default store info if loading fails
    }
  }

  // Save store info to SharedPreferences
  Future<void> _saveStoreInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeInfoJson = jsonEncode(_storeInfo.toJson());
      await prefs.setString(_storeInfoKey, storeInfoJson);
    } catch (e) {
      debugPrint('Error saving store info: $e');
      throw Exception('Failed to save store information');
    }
  }

  // Update store name
  Future<void> updateStoreName(String name) async {
    try {
      _storeInfo = _storeInfo.copyWith(name: name.trim());
      await _saveStoreInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store name: $e');
      throw Exception('Failed to update store name');
    }
  }

  // Update store phone
  Future<void> updateStorePhone(String phone) async {
    try {
      _storeInfo = _storeInfo.copyWith(phone: phone.trim());
      await _saveStoreInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store phone: $e');
      throw Exception('Failed to update store phone');
    }
  }

  // Update store address
  Future<void> updateStoreAddress(String address) async {
    try {
      _storeInfo = _storeInfo.copyWith(address: address.trim());
      await _saveStoreInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store address: $e');
      throw Exception('Failed to update store address');
    }
  }

  // Update all store info at once
  Future<void> updateStoreInfo({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      _storeInfo = _storeInfo.copyWith(
        name: name?.trim(),
        phone: phone?.trim(),
        address: address?.trim(),
      );
      await _saveStoreInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store info: $e');
      throw Exception('Failed to update store information');
    }
  }

  // Reset to default store info
  Future<void> resetStoreInfo() async {
    try {
      _storeInfo = StoreInfo.defaultStore;
      await _saveStoreInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting store info: $e');
      throw Exception('Failed to reset store information');
    }
  }

  // Check if store info has been customized (not default)
  bool get isStoreInfoCustomized {
    return _storeInfo != StoreInfo.defaultStore;
  }

  // Get formatted store info for display
  String get formattedStoreInfo {
    final parts = <String>[];

    if (_storeInfo.name.isNotEmpty) {
      parts.add(_storeInfo.name);
    }

    if (_storeInfo.phone.isNotEmpty) {
      parts.add(_storeInfo.phone);
    }

    if (_storeInfo.address.isNotEmpty) {
      parts.add(_storeInfo.address);
    }

    return parts.join('\n');
  }
}