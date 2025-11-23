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
  final Map<String, String>? variants; // Map of variant size -> storage path
  final Map<String, int>? variantSizes; // Map of variant size -> file size

  Photo({
    required this.id,
    required this.visitId,
    required this.userId,
    required this.storagePath,
    required this.photoType,
    this.fileSize,
    required this.createdAt,
    this.variants,
    this.variantSizes,
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
      variants: json['variants'] != null
        ? Map<String, String>.from(json['variants'] as Map)
        : null,
      variantSizes: json['variant_sizes'] != null
        ? Map<String, int>.from(json['variant_sizes'] as Map)
        : null,
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

    // Include variants if available
    if (variants != null) {
      json['variants'] = variants;
    }

    if (variantSizes != null) {
      json['variant_sizes'] = variantSizes;
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
    Map<String, String>? variants,
    Map<String, int>? variantSizes,
  }) {
    return Photo(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      userId: userId ?? this.userId,
      storagePath: storagePath ?? this.storagePath,
      photoType: photoType ?? this.photoType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      variants: variants ?? this.variants,
      variantSizes: variantSizes ?? this.variantSizes,
    );
  }

  /// Get URL for a specific variant size
  /// Falls back to original storage path if variant doesn't exist
  String getVariantUrl(String variantSize) {
    return variants?[variantSize] ?? storagePath;
  }

  /// Get the best variant URL for a given display width
  String getBestVariantUrl(int displayWidth) {
    if (variants == null || variants!.isEmpty) {
      return storagePath; // Fallback to original
    }

    // Determine best variant based on display width
    if (displayWidth <= 64 && variants!.containsKey('thumb')) {
      return variants!['thumb']!;
    } else if (displayWidth <= 200 && variants!.containsKey('small')) {
      return variants!['small']!;
    } else if (displayWidth <= 400 && variants!.containsKey('medium')) {
      return variants!['medium']!;
    } else if (displayWidth <= 800 && variants!.containsKey('large')) {
      return variants!['large']!;
    }

    // Fallback to original
    return variants!['original'] ?? storagePath;
  }

  /// Legacy method for backward compatibility
  @Deprecated('Use getVariantUrl instead')
  String getVariantPath(String variantSize) => getVariantUrl(variantSize);

  /// Legacy method for backward compatibility
  @Deprecated('Use getBestVariantUrl instead')
  String getBestVariantPath(int displayWidth) => getBestVariantUrl(displayWidth);

  /// Check if variants are available
  bool get hasVariants => variants != null && variants!.isNotEmpty;

  /// Get total storage size of all variants
  int get totalVariantSize {
    if (variantSizes == null) return fileSize ?? 0;

    int total = 0;
    for (final size in variantSizes!.values) {
      total += size;
    }
    return total;
  }

  /// Get available variant sizes
  List<String> get availableVariants {
    return variants?.keys.toList() ?? [];
  }
}