import 'photo.dart';
import '../l10n/app_localizations.dart';

class Visit {
  final String id;
  final String clientId;
  final String userId;
  final String storeId; // ID of the store where the visit occurred
  final String? staffId; // ID of the staff member who performed the service
  final DateTime visitDate;
  final String? serviceId;
  final String? serviceName; // Service name from joined query
  final int? rating; // Rating from 1-5 stars
  final bool? loved; // Whether this visit result is loved by the client
  final String? notes;
  final String? productsUsed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Photo>? photos;

  // New fields added in migration 019
  final String visitStatus; // 'scheduled', 'in_progress', 'completed', 'cancelled', 'no_show'
  final int? durationMinutes;
  final DateTime? appointmentTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  // New fields added in migration 022 (soft delete)
  final DateTime? deletedAt;
  final String? deletedBy;

  Visit({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.storeId,
    this.staffId,
    required this.visitDate,
    this.serviceId,
    this.serviceName,
    this.rating,
    this.loved, // Can be null for existing visits
    this.notes,
    this.productsUsed,
    required this.createdAt,
    required this.updatedAt,
    this.photos,

    // New fields
    String? visitStatus, // Allow nullable in constructor
    this.durationMinutes,
    this.appointmentTime,
    this.actualStartTime,
    this.actualEndTime,
    this.deletedAt,
    this.deletedBy,
  }) : visitStatus = visitStatus ?? 'completed';

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      userId: json['user_id'] as String,
      storeId: json['store_id'] as String,
      staffId: json['staff_id'] as String?,
      visitDate: DateTime.parse(json['visit_date'] as String),
      serviceId: json['service_id'] as String?,
      serviceName: json['services']?['name'] as String?,
      rating: json['rating'] as int?,
      loved: json['loved'] as bool? ?? false, // Default to false if null
      notes: json['notes'] as String?,
      productsUsed: json['products_used'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      photos: json['photos'] != null
          ? (json['photos'] as List)
              .map((photo) => Photo.fromJson(photo))
              .toList()
          : null,

      // New fields from migrations
      visitStatus: (json['visit_status'] as String?) ?? 'completed',
      durationMinutes: json['duration_minutes'] as int?,
      appointmentTime: json['appointment_time'] != null
          ? DateTime.parse(json['appointment_time'] as String)
          : null,
      actualStartTime: json['actual_start_time'] != null
          ? DateTime.parse(json['actual_start_time'] as String)
          : null,
      actualEndTime: json['actual_end_time'] != null
          ? DateTime.parse(json['actual_end_time'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      deletedBy: json['deleted_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'client_id': clientId,
      'user_id': userId,
      'store_id': storeId,
      if (staffId != null) 'staff_id': staffId,
      'visit_date': visitDate.toIso8601String(),
      'service_id': serviceId,
      if (rating != null) 'rating': rating,
      'loved': loved ?? false,
      'notes': notes,
      'products_used': productsUsed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),

      // New fields
      'visit_status': visitStatus,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (appointmentTime != null) 'appointment_time': appointmentTime!.toIso8601String(),
      if (actualStartTime != null) 'actual_start_time': actualStartTime!.toIso8601String(),
      if (actualEndTime != null) 'actual_end_time': actualEndTime!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
      if (deletedBy != null) 'deleted_by': deletedBy,
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
    String? storeId,
    String? staffId,
    DateTime? visitDate,
    String? serviceId,
    String? serviceName,
    int? rating,
    bool? loved,
    String? notes,
    String? productsUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Photo>? photos,

    // New fields
    String? visitStatus,
    int? durationMinutes,
    DateTime? appointmentTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Visit(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      staffId: staffId ?? this.staffId,
      visitDate: visitDate ?? this.visitDate,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      rating: rating ?? this.rating,
      loved: loved ?? this.loved,
      notes: notes ?? this.notes,
      productsUsed: productsUsed ?? this.productsUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,

      // New fields
      visitStatus: visitStatus ?? this.visitStatus,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  // Helper method to get formatted visit date
  String formattedVisitDate(AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(visitDate);

    // Format time as HH:MM
    final timeStr = '${visitDate.hour.toString().padLeft(2, '0')}:${visitDate.minute.toString().padLeft(2, '0')}';

    if (difference.inDays == 0) {
      return '${l10n.today} at $timeStr';
    } else if (difference.inDays == 1) {
      return '${l10n.yesterday} at $timeStr';
    } else if (difference.inDays < 7) {
      // Show actual date for recent visits
      return '${visitDate.day}/${visitDate.month}/${visitDate.year} at $timeStr';
    } else {
      // For older visits, show date without time for cleaner display
      return '${visitDate.day}/${visitDate.month}/${visitDate.year}';
    }
  }

  // Helper method to get simple time format for client cards
  String simpleTimeFormat(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDay = DateTime(visitDate.year, visitDate.month, visitDate.day);

    // Format time as HH:MM
    final timeStr = '${visitDate.hour.toString().padLeft(2, '0')}:${visitDate.minute.toString().padLeft(2, '0')}';

    if (visitDay.isAtSameMomentAs(today)) {
      // Today: just show time
      return timeStr;
    } else {
      // Other days: show date + time
      return '${visitDate.day}/${visitDate.month}/${visitDate.year} at $timeStr';
    }
  }

  // Helper method to get short service description
  String get shortDescription {
    if (serviceName != null && serviceName!.isNotEmpty) {
      return serviceName!;
    } else if (serviceId != null && serviceId!.isNotEmpty) {
      return 'Service selected'; // Fallback if serviceName is not available
    } else if (notes != null && notes!.isNotEmpty) {
      return notes!.length > 30 ? '${notes!.substring(0, 30)}...' : notes!;
    } else {
      return 'Styling session';
    }
  }
}