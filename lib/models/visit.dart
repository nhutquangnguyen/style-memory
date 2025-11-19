import 'photo.dart';

class Visit {
  final String id;
  final String clientId;
  final String userId;
  final DateTime visitDate;
  final String? serviceType;
  final String? notes;
  final String? productsUsed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Photo>? photos;

  Visit({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.visitDate,
    this.serviceType,
    this.notes,
    this.productsUsed,
    required this.createdAt,
    required this.updatedAt,
    this.photos,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      userId: json['user_id'] as String,
      visitDate: DateTime.parse(json['visit_date'] as String),
      serviceType: json['service_type'] as String?,
      notes: json['notes'] as String?,
      productsUsed: json['products_used'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      photos: json['photos'] != null
          ? (json['photos'] as List)
              .map((photo) => Photo.fromJson(photo))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'client_id': clientId,
      'user_id': userId,
      'visit_date': visitDate.toIso8601String(),
      'service_type': serviceType,
      'notes': notes,
      'products_used': productsUsed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  Visit copyWith({
    String? id,
    String? clientId,
    String? userId,
    DateTime? visitDate,
    String? serviceType,
    String? notes,
    String? productsUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Photo>? photos,
  }) {
    return Visit(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      visitDate: visitDate ?? this.visitDate,
      serviceType: serviceType ?? this.serviceType,
      notes: notes ?? this.notes,
      productsUsed: productsUsed ?? this.productsUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
    );
  }

  // Helper method to get formatted visit date
  String get formattedVisitDate {
    final now = DateTime.now();
    final difference = now.difference(visitDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 14) {
      return '1 week ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 60) {
      return '1 month ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  // Helper method to get short service description
  String get shortDescription {
    if (serviceType != null && serviceType!.isNotEmpty) {
      return serviceType!;
    } else if (notes != null && notes!.isNotEmpty) {
      return notes!.length > 30 ? '${notes!.substring(0, 30)}...' : notes!;
    } else {
      return 'Styling session';
    }
  }
}