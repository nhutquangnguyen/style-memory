import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'image_variant_service.dart';
import 'wasabi_service.dart';
import 'supabase_service.dart';

/// Service to handle complete photo upload pipeline with variants
class PhotoVariantService {
  /// Process and upload a photo with all variants
  static Future<Photo> processAndUploadPhoto({
    required Uint8List originalImageData,
    required String visitId,
    required PhotoType photoType,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Step 1: Process image into all variants
      debugPrint('Processing image variants...');
      final processedVariants = await ImageVariantService.processImageVariants(
        originalImageData,
      );

      // Step 2: Prepare variant data for upload
      final variantData = <String, Uint8List>{};
      final variantSizes = <String, int>{};

      for (final variant in processedVariants) {
        variantData[variant.variant.suffix] = variant.data;
        variantSizes[variant.variant.suffix] = variant.fileSize;
      }

      // Step 3: Upload all variants to Wasabi
      debugPrint('Uploading ${variantData.length} variants to Wasabi...');
      final uploadedVariants = await WasabiService.uploadPhotoVariants(
        variantData: variantData,
        userId: userId,
        visitId: visitId,
        photoType: photoType.name,
      );

      // Step 4: Determine main storage URL (use original or largest variant)
      final mainUrl = uploadedVariants['original'] ??
                     uploadedVariants['large'] ??
                     uploadedVariants.values.first;

      // Step 5: Calculate total file size
      final totalSize = variantSizes.values.fold<int>(0, (sum, size) => sum + size);

      // Step 6: Create photo record (storagePath now contains the full URL for Wasabi)
      final photo = Photo(
        id: '', // Will be set by database
        visitId: visitId,
        userId: userId,
        storagePath: mainUrl, // This is now a full Wasabi URL
        photoType: photoType,
        fileSize: totalSize,
        createdAt: DateTime.now(),
        variants: uploadedVariants, // Map of variant size -> Wasabi URL
        variantSizes: variantSizes,
      );

      // Step 7: Save to database
      final savedPhoto = await SupabaseService.createPhoto(photo);

      debugPrint('Photo uploaded successfully with ${uploadedVariants.length} variants');
      return savedPhoto;

    } catch (e) {
      debugPrint('Failed to process and upload photo: $e');
      rethrow;
    }
  }

  /// Legacy method - processes and uploads without variants (backward compatibility)
  static Future<Photo> uploadPhotoLegacy({
    required Uint8List imageData,
    required String visitId,
    required PhotoType photoType,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Upload original image only to Wasabi
    final photoUrl = await WasabiService.uploadPhotoFromBytes(
      imageData,
      'jpg',
      customPath: 'photos/$userId/$visitId/${photoType.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // Create photo record without variants
    final photo = Photo(
      id: '',
      visitId: visitId,
      userId: userId,
      storagePath: photoUrl, // Full Wasabi URL
      photoType: photoType,
      fileSize: imageData.length,
      createdAt: DateTime.now(),
      variants: null,
      variantSizes: null,
    );

    return await SupabaseService.createPhoto(photo);
  }

  /// Generate variants for existing photos that don't have them
  static Future<Photo> generateVariantsForExistingPhoto(
    Photo existingPhoto,
    Uint8List originalImageData,
  ) async {
    try {
      debugPrint('Generating variants for existing photo ${existingPhoto.id}');

      // Process variants
      final processedVariants = await ImageVariantService.processImageVariants(
        originalImageData,
      );

      // Prepare upload data (exclude original since it already exists)
      final variantData = <String, Uint8List>{};
      final variantSizes = <String, int>{};

      for (final variant in processedVariants) {
        if (variant.variant != ImageVariant.original) {
          variantData[variant.variant.suffix] = variant.data;
          variantSizes[variant.variant.suffix] = variant.fileSize;
        }
      }

      // Upload new variants to Wasabi
      final uploadedVariants = await WasabiService.uploadPhotoVariants(
        variantData: variantData,
        userId: existingPhoto.userId,
        visitId: existingPhoto.visitId,
        photoType: existingPhoto.photoType.name,
      );

      // Include original path
      uploadedVariants['original'] = existingPhoto.storagePath;
      variantSizes['original'] = existingPhoto.fileSize ?? 0;

      // Update photo with variants
      final updatedPhoto = existingPhoto.copyWith(
        variants: uploadedVariants,
        variantSizes: variantSizes,
      );

      // Note: You'll need to implement updatePhoto in SupabaseService
      // For now, return the updated photo object
      debugPrint('Generated ${uploadedVariants.length} variants for photo ${existingPhoto.id}');
      return updatedPhoto;

    } catch (e) {
      debugPrint('Failed to generate variants for existing photo: $e');
      rethrow;
    }
  }

  /// Get upload progress information
  static Map<String, dynamic> getUploadStats({
    required int originalSize,
    required List<ProcessedImageVariant> variants,
  }) {
    final totalVariantSize = variants.fold<int>(
      0,
      (sum, variant) => sum + variant.fileSize,
    );

    return {
      'original_size': originalSize,
      'total_variant_size': totalVariantSize,
      'size_increase_ratio': totalVariantSize / originalSize,
      'variant_count': variants.length,
      'size_breakdown': {
        for (final variant in variants)
          variant.variant.suffix: {
            'size': variant.fileSize,
            'width': variant.width,
            'height': variant.height,
            'compression_ratio': variant.fileSize / originalSize,
          }
      }
    };
  }

  /// Check if photo should use variant system (based on file size or other criteria)
  static bool shouldUseVariants(Uint8List imageData) {
    const minSizeForVariants = 100 * 1024; // 100KB
    const maxSizeForVariants = 10 * 1024 * 1024; // 10MB

    final size = imageData.length;
    return size >= minSizeForVariants && size <= maxSizeForVariants;
  }

  /// Smart upload - automatically decides whether to use variants
  static Future<Photo> smartUploadPhoto({
    required Uint8List imageData,
    required String visitId,
    required PhotoType photoType,
  }) async {
    if (shouldUseVariants(imageData)) {
      return await processAndUploadPhoto(
        originalImageData: imageData,
        visitId: visitId,
        photoType: photoType,
      );
    } else {
      return await uploadPhotoLegacy(
        imageData: imageData,
        visitId: visitId,
        photoType: photoType,
      );
    }
  }
}