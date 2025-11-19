class Client {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Client copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get client initials for avatar
  String get initials {
    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names.first[0].toUpperCase();
    }
    return 'C';
  }
}