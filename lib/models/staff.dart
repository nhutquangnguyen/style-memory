import 'package:uuid/uuid.dart';

class Staff {
  final String id;
  final String userId; // Links to the salon owner
  final String name;
  final String? email;
  final String? phone;
  final String? specialty; // e.g., "Hair Color Specialist", "Nail Art"
  final String? profileImageUrl;
  final DateTime hireDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    String? id,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
    this.specialty,
    this.profileImageUrl,
    DateTime? hireDate,
    this.isActive = true,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        hireDate = hireDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Display properties
  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get displaySpecialty => specialty ?? 'General Stylist';

  String get formattedHireDate {
    final now = DateTime.now();
    final difference = now.difference(hireDate);

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).round();
      return months <= 1 ? 'New hire' : '$months months';
    } else {
      final years = (difference.inDays / 365).round();
      return '$years year${years > 1 ? 's' : ''}';
    }
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (specialty != null) 'specialty': specialty,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      'hire_date': hireDate.toIso8601String(),
      'is_active': isActive,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      hireDate: DateTime.parse(json['hire_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Copy with method
  Staff copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? specialty,
    String? profileImageUrl,
    DateTime? hireDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialty: specialty ?? this.specialty,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hireDate: hireDate ?? this.hireDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Staff && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Staff(id: $id, name: $name, specialty: $specialty)';
}