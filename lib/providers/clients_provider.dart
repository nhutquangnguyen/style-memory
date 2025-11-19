import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';

class ClientsProvider extends ChangeNotifier {
  List<Client> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

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
    return _clients
        .where((client) => client.fullName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadClients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clients = await SupabaseService.getClients();
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
    await loadClients();
  }
}