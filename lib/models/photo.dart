enum PhotoType {
  front,
  back,
  left,
  right;

  String get displayName {
    switch (this) {
      case PhotoType.front:
        return 'Front';
      case PhotoType.back:
        return 'Back';
      case PhotoType.left:
        return 'Left';
      case PhotoType.right:
        return 'Right';
    }
  }

  static PhotoType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'front':
        return PhotoType.front;
      case 'back':
        return PhotoType.back;
      case 'left':
        return PhotoType.left;
      case 'right':
        return PhotoType.right;
      default:
        throw ArgumentError('Invalid photo type: $value');
    }
  }
}

class Photo {
  final String id;
  final String visitId;
  final String userId;
  final String storagePath;
  final PhotoType photoType;
  final int? fileSize;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.visitId,
    required this.userId,
    required this.storagePath,
    required this.photoType,
    this.fileSize,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      visitId: json['visit_id'] as String,
      userId: json['user_id'] as String,
      storagePath: json['storage_path'] as String,
      photoType: PhotoType.fromString(json['photo_type'] as String),
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'visit_id': visitId,
      'user_id': userId,
      'storage_path': storagePath,
      'photo_type': photoType.name,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };

    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  Photo copyWith({
    String? id,
    String? visitId,
    String? userId,
    String? storagePath,
    PhotoType? photoType,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      userId: userId ?? this.userId,
      storagePath: storagePath ?? this.storagePath,
      photoType: photoType ?? this.photoType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}