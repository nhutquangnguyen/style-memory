import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'wasabi_service.dart';

class SupabaseService {
  static late SupabaseClient _client;

  static SupabaseClient get client => _client;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _client = Supabase.instance.client;
  }

  // Auth methods
  static User? get currentUser => _client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'email': email,
      },
    );

    // Profile creation is now handled by database trigger
    // If needed, we can ensure profile exists after a short delay
    if (response.user != null && response.session != null) {
      // Small delay to ensure trigger has completed
      await Future.delayed(const Duration(milliseconds: 500));
      await _ensureUserProfileExists(response.user!);
    }

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Ensure profile exists for existing users (edge case handling)
    if (response.user != null && response.session != null) {
      await _ensureUserProfileExists(response.user!);
    }

    return response;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Helper method to ensure user profile exists
  static Future<void> _ensureUserProfileExists(User user) async {
    try {
      final existingProfile = await _client
          .from('user_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Profile doesn't exist, create it manually as fallback
        await _client.from('user_profiles').insert({
          'id': user.id,
          'email': user.email ?? '',
          'full_name': user.userMetadata?['full_name'] ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Log error but don't throw - profile might have been created by trigger
      // In production, use a proper logging framework
    }
  }

  // User Profile methods
  static Future<UserProfile?> getCurrentUserProfile() async {
    if (!isAuthenticated) return null;

    final response = await _client
        .from('user_profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();

    if (response != null) {
      return UserProfile.fromJson(response);
    }
    return null;
  }

  static Future<UserProfile> createUserProfile(UserProfile profile) async {
    final response = await _client
        .from('user_profiles')
        .insert(profile.toJson())
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  static Future<void> updateUserProfile(UserProfile profile) async {
    await _client
        .from('user_profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  // Client methods
  static Future<List<Client>> getClients({String? storeId}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    var query = _client
        .from('clients')
        .select()
        .eq('user_id', currentUser!.id)
; // Temporarily removed soft delete filter to test

    // If storeId is provided, filter by store
    if (storeId != null) {
      query = query.eq('store_id', storeId);
    }

    final response = await query.order('created_at', ascending: false);

    return response.map((client) => Client.fromJson(client)).toList();
  }

  static Future<Client> createClient(Client client) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    final response = await _client
        .from('clients')
        .insert(client.toJson())
        .select()
        .single();

    return Client.fromJson(response);
  }

  static Future<void> updateClient(Client client) async {
    await _client
        .from('clients')
        .update(client.toJson())
        .eq('id', client.id);
  }

  static Future<void> deleteClient(String clientId) async {
    await _client.from('clients').delete().eq('id', clientId);
  }

  // Service methods
  static Future<List<Service>> getServices({String? storeId}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    var query = _client
        .from('services')
        .select()
        .eq('user_id', currentUser!.id)
; // Temporarily removed soft delete filter to test

    // If storeId is provided, filter by store (assuming services will also have store_id)
    if (storeId != null) {
      query = query.eq('store_id', storeId);
    }

    final response = await query.order('name');

    return response.map((service) => Service.fromJson(service)).toList();
  }

  static Future<Service> createService(Service service) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    final response = await _client
        .from('services')
        .insert(service.toJson())
        .select()
        .single();

    return Service.fromJson(response);
  }

  static Future<void> updateService(Service service) async {
    await _client
        .from('services')
        .update(service.toJson())
        .eq('id', service.id);
  }

  static Future<void> deleteService(String serviceId) async {
    await _client.from('services').delete().eq('id', serviceId);
  }

  // Staff methods
  static Future<List<Staff>> getStaff({String? storeId}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    var query = _client
        .from('staff')
        .select()
        .eq('user_id', currentUser!.id)
; // Temporarily removed soft delete filter to test

    // If storeId is provided, filter by store
    if (storeId != null) {
      query = query.eq('store_id', storeId);
    }

    final response = await query.order('name');

    return response.map((staff) => Staff.fromJson(staff)).toList();
  }

  static Future<Staff> createStaff(Staff staff) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    final response = await _client
        .from('staff')
        .insert(staff.toJson())
        .select()
        .single();

    return Staff.fromJson(response);
  }

  static Future<void> updateStaff(Staff staff) async {
    await _client
        .from('staff')
        .update(staff.toJson())
        .eq('id', staff.id);
  }

  static Future<void> deleteStaff(String staffId) async {
    await _client.from('staff').delete().eq('id', staffId);
  }

  // Visit methods
  static Future<List<Visit>> getVisitsForClient(String clientId, {String? storeId}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    var query = _client
        .from('visits')
        .select('''
          *,
          photos!fk_photos_visit_id (*),
          services!fk_visits_service_id (
            id,
            name
          )
        ''')
        .eq('client_id', clientId)
        .eq('user_id', currentUser!.id);

    // If storeId is provided, filter by store
    if (storeId != null) {
      query = query.eq('store_id', storeId);
    }

    final response = await query.order('visit_date', ascending: false);
    return response.map((visit) => Visit.fromJson(visit)).toList();
  }


  static Future<List<Visit>> getVisitsForStaff(String staffId, {String? storeId}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    var query = _client
        .from('visits')
        .select('''
          *,
          photos!fk_photos_visit_id (*),
          services!fk_visits_service_id (
            id,
            name
          )
        ''')
        .eq('staff_id', staffId)
        .eq('user_id', currentUser!.id);

    // If storeId is provided, filter by store
    if (storeId != null) {
      query = query.eq('store_id', storeId);
    }

    final response = await query.order('visit_date', ascending: false);

    return response.map((visit) => Visit.fromJson(visit)).toList();
  }

  static Future<Visit?> getVisit(String visitId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client
          .from('visits')
          .select('''
            *,
            photos!fk_photos_visit_id (*),
            services!fk_visits_service_id (
              id,
              name
            )
          ''')
          .eq('id', visitId)
          .eq('user_id', currentUser!.id)
          .maybeSingle(); // Use maybeSingle to handle case where visit doesn't exist

      if (response == null) {
        return null;
      }

      final visit = Visit.fromJson(response);
      return visit;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Visit> createVisit(Visit visit) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    final response = await _client
        .from('visits')
        .insert(visit.toJson())
        .select()
        .single();

    return Visit.fromJson(response);
  }

  static Future<void> updateVisit(Visit visit) async {
    await _client
        .from('visits')
        .update(visit.toJson())
        .eq('id', visit.id);
  }

  static Future<void> updateVisitLoved(String visitId, bool loved) async {
    await _client
        .from('visits')
        .update({
          'loved': loved,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', visitId);
  }

  static Future<Visit> getVisitById(String visitId) async {
    final response = await _client
        .from('visits')
        .select('''
          *,
          photos!fk_photos_visit_id (*),
          services!fk_visits_service_id (id, name)
        ''')
        .eq('id', visitId)
        .single();

    return Visit.fromJson(response);
  }

  // Get all visits for a specific store
  static Future<List<Visit>> getVisitsForStore(String storeId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    final response = await _client
        .from('visits')
        .select('''
          *,
          photos!fk_photos_visit_id (*),
          services!fk_visits_service_id (
            id,
            name
          )
        ''')
        .eq('store_id', storeId)
        .eq('user_id', currentUser!.id)
        .order('visit_date', ascending: false);

    return response.map((visit) => Visit.fromJson(visit)).toList();
  }

  static Future<void> deleteVisit(String visitId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Delete photos from storage first
      final photos = await _client
          .from('photos')
          .select('storage_path, id')
          .eq('visit_id', visitId);

      for (final photo in photos) {
        final storagePath = photo['storage_path'] as String;
        final photoId = photo['id'] as String;

        // Handle Wasabi storage paths (photos are now stored on Wasabi)
        if (storagePath.startsWith('wasabi:')) {
          // Prefixed Wasabi path
          final objectName = storagePath.substring(7); // Remove 'wasabi:' prefix
          try {
            await WasabiService.deletePhoto('https://s3.ap-southeast-1.wasabisys.com/style-memory-photos/$objectName');
          } catch (e) {
            // Continue with other photos even if one fails
          }
        } else if (storagePath.startsWith('https://') && storagePath.contains('wasabi')) {
          // Full Wasabi URL
          try {
            await WasabiService.deletePhoto(storagePath);
          } catch (e) {
            // Continue with other photos even if one fails
          }
        } else {
          // Unrecognized path format - skip this photo
        }

        // Delete photo record from database
        try {
          await _client.from('photos').delete().eq('id', photoId);
        } catch (e) {
          // Continue even if photo record deletion fails
        }
      }

      // Now delete the visit record
      await _client
          .from('visits')
          .delete()
          .eq('id', visitId)
          .eq('user_id', currentUser!.id); // Add user_id constraint for RLS
    } catch (e) {
      rethrow;
    }
  }

  // Photo database methods (storage is handled by Wasabi)
  static Future<Photo> createPhoto(Photo photo) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    final response = await _client
        .from('photos')
        .insert(photo.toJson())
        .select()
        .single();

    return Photo.fromJson(response);
  }

  /// Delete only the photo record from database (for Wasabi integration)
  static Future<void> deletePhotoRecord(String photoId) async {
    await _client.from('photos').delete().eq('id', photoId);
  }

  // Store methods
  static Future<List<Store>> getUserStores() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('stores')
        .select('*')
        .eq('owner_id', userId);

    return (response as List)
        .map((store) => Store.fromJson(store))
        .toList();
  }

  static Future<Store?> getStore(String storeId) async {
    final response = await _client
        .from('stores')
        .select('*')
        .eq('id', storeId)
        .single();

    if (response.isEmpty) return null;

    return Store.fromJson(response);
  }

  static Future<Store> createStore(Store store) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toIso8601String();

    final storeData = {
      'id': store.id,
      'owner_id': userId,
      'name': store.name,
      'phone': store.phone,
      'address': store.address,
      'created_at': now,
      'updated_at': now,
    };

    final response = await _client
        .from('stores')
        .insert(storeData)
        .select()
        .single();

    return Store.fromJson(response);
  }

  static Future<Store> updateStore(Store store) async {
    final now = DateTime.now().toIso8601String();

    final storeData = {
      'name': store.name,
      'phone': store.phone,
      'address': store.address,
      'slug': store.slug,
      'avatar': store.avatar,
      'cover': store.cover,
      'updated_at': now,
    };

    final response = await _client
        .from('stores')
        .update(storeData)
        .eq('id', store.id)
        .select()
        .single();

    return Store.fromJson(response);
  }

  static Future<void> deleteStore(String storeId) async {
    await _client.from('stores').delete().eq('id', storeId);
  }

  // Utility methods
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}