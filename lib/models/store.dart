import 'package:uuid/uuid.dart';

class Store {
  final String id;
  final String ownerId;
  final String name;
  final String phone;
  final String address;
  final String? slug;
  final String? avatar;
  final String? cover;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Store({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.phone,
    required this.address,
    this.slug,
    this.avatar,
    this.cover,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from JSON
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      slug: json['slug'] as String?,
      avatar: json['avatar'] as String?,
      cover: json['cover'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'phone': phone,
      'address': address,
      'slug': slug,
      'avatar': avatar,
      'cover': cover,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a new store with default values
  factory Store.create({
    required String ownerId,
    String name = 'My Salon',
    String phone = '',
    String address = '',
    String? slug,
    String? avatar,
    String? cover,
  }) {
    final now = DateTime.now();
    return Store(
      id: const Uuid().v4(),
      ownerId: ownerId,
      name: name,
      phone: phone,
      address: address,
      slug: slug,
      avatar: avatar,
      cover: cover,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create a copy with updated values
  Store copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? phone,
    String? address,
    String? slug,
    String? avatar,
    String? cover,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Store(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      slug: slug ?? this.slug,
      avatar: avatar ?? this.avatar,
      cover: cover ?? this.cover,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if store has custom information (not default)
  bool get isCustomized {
    return name != 'My Salon' ||
           phone.isNotEmpty ||
           address.isNotEmpty ||
           slug != null ||
           avatar != null ||
           cover != null;
  }

  // Get formatted store information for display
  String get formattedStoreInfo {
    final List<String> parts = [];

    if (name.isNotEmpty) {
      parts.add(name);
    }

    if (phone.isNotEmpty) {
      parts.add(phone);
    }

    if (address.isNotEmpty) {
      parts.add(address);
    }

    return parts.join(' • ');
  }

  // Get store URL slug or generate from name
  String get urlSlug {
    if (slug != null && slug!.isNotEmpty) {
      return slug!;
    }
    // Fallback to ID if no slug
    return id;
  }

  // Check if store has avatar image
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  // Check if store has cover image
  bool get hasCover => cover != null && cover!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Store &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.name == name &&
        other.phone == phone &&
        other.address == address &&
        other.slug == slug &&
        other.avatar == avatar &&
        other.cover == cover;
  }

  @override
  int get hashCode => Object.hash(id, ownerId, name, phone, address, slug, avatar, cover);

  @override
  String toString() {
    return 'Store(id: $id, name: $name, ownerId: $ownerId)';
  }
}