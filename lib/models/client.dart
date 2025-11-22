class Client {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? email;
  final DateTime? birthday;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.email,
    this.birthday,
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
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
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
      'birthday': birthday?.toIso8601String(),
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
    DateTime? birthday,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearPhone = false,
    bool clearEmail = false,
    bool clearBirthday = false,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: clearPhone ? null : (phone ?? this.phone),
      email: clearEmail ? null : (email ?? this.email),
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
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

  // Helper method to format birthday display
  String? get formattedBirthday {
    if (birthday == null) return null;

    final now = DateTime.now();
    final birthdayThisYear = DateTime(now.year, birthday!.month, birthday!.day);

    // Check if birthday is today
    if (birthdayThisYear.year == now.year &&
        birthdayThisYear.month == now.month &&
        birthdayThisYear.day == now.day) {
      return '🎉 Today!';
    }

    // Check if birthday is within a week
    final daysUntilBirthday = birthdayThisYear.difference(now).inDays;
    if (daysUntilBirthday >= 0 && daysUntilBirthday <= 7) {
      if (daysUntilBirthday == 1) {
        return '🎂 Tomorrow!';
      } else {
        return '🎂 In $daysUntilBirthday days';
      }
    }

    // If day is available, show full date
    if (birthday!.day != 1) {
      return '${birthday!.day}/${birthday!.month}/${birthday!.year}';
    } else {
      // Only month and year available (day was set to 1 as default)
      return '${birthday!.month}/${birthday!.year}';
    }
  }
}