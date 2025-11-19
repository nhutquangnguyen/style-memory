import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';

class ClientsProvider extends ChangeNotifier {
  List<Client> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Cache to prevent unnecessary reloads
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Search functionality
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<Client> get filteredClients {
    if (_searchQuery.isEmpty) {
      return _clients;
    }

    final query = _searchQuery.toLowerCase();
    return _clients.where((client) {
      // Search by name
      final nameMatch = client.fullName.toLowerCase().contains(query);

      // Search by phone (if available)
      final phoneMatch = client.phone != null &&
          client.phone!.toLowerCase().contains(query);

      // Search by email (if available)
      final emailMatch = client.email != null &&
          client.email!.toLowerCase().contains(query);

      return nameMatch || phoneMatch || emailMatch;
    }).toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadClients() async {
    // Check if we have valid cached data
    if (_clients.isNotEmpty &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < _cacheExpiry) {
      // Use cached data - no loading needed
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clients = await SupabaseService.getClients();
      _lastLoadTime = DateTime.now(); // Cache the load time
    } catch (e) {
      _errorMessage = 'Failed to load clients: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createClient({
    required String fullName,
    String? phone,
    String? email,
  }) async {
    if (!SupabaseService.isAuthenticated) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final client = Client(
        id: const Uuid().v4(),
        userId: SupabaseService.currentUser!.id,
        fullName: fullName.trim(),
        phone: phone?.trim(),
        email: email?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdClient = await SupabaseService.createClient(client);
      _clients.insert(0, createdClient); // Add to beginning of list

      // Invalidate cache since we added a new client
      _lastLoadTime = DateTime.now();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create client: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClient(Client client) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedClient = client.copyWith(
        updatedAt: DateTime.now(),
      );

      await SupabaseService.updateClient(updatedClient);

      // Update in local list
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = updatedClient;
      }

      // Update cache timestamp since we modified data
      _lastLoadTime = DateTime.now();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update client: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClient(String clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.deleteClient(clientId);

      // Remove from local list
      _clients.removeWhere((c) => c.id == clientId);

      // Update cache timestamp since we modified data
      _lastLoadTime = DateTime.now();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete client: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Client? getClientById(String clientId) {
    try {
      return _clients.firstWhere((client) => client.id == clientId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    // Force refresh by clearing cache
    _lastLoadTime = null;
    await loadClients();
  }

  // Method to force refresh (clear cache and reload)
  Future<void> forceRefresh() async {
    _lastLoadTime = null;
    await loadClients();
  }
}