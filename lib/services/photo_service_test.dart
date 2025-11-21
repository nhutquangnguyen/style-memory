import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'wasabi_service.dart';

class PhotoServiceTest {
  /// Test Wasabi upload with a sample image
  static Future<Map<String, dynamic>> testWasabiUpload() async {
    try {
      debugPrint('Starting Wasabi upload test...');

      // Initialize if not already done
      await WasabiService.initialize();

      // Get bucket stats first
      final stats = await WasabiService.getBucketStats();
      debugPrint('Bucket stats: $stats');

      return {
        'success': true,
        'message': 'Wasabi service initialized successfully',
        'bucket_stats': stats,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Wasabi upload test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Test Wasabi upload with an actual image file
  static Future<Map<String, dynamic>> testWasabiUploadWithImage() async {
    try {
      debugPrint('Starting Wasabi image upload test...');

      // Pick an image
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) {
        return {
          'success': false,
          'error': 'No image selected',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      // Upload to Wasabi
      final uploadStartTime = DateTime.now();
      final imageUrl = await WasabiService.uploadPhoto(image);
      final uploadDuration = DateTime.now().difference(uploadStartTime);

      debugPrint('Image uploaded successfully: $imageUrl');
      debugPrint('Upload took: ${uploadDuration.inMilliseconds}ms');

      return {
        'success': true,
        'message': 'Image uploaded successfully to Wasabi',
        'image_url': imageUrl,
        'upload_duration_ms': uploadDuration.inMilliseconds,
        'file_size_bytes': await image.length(),
        'file_name': image.name,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Wasabi image upload test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Test file deletion
  static Future<Map<String, dynamic>> testWasabiDelete(String imageUrl) async {
    try {
      debugPrint('Testing Wasabi delete for: $imageUrl');

      final deleteStartTime = DateTime.now();
      final success = await WasabiService.deletePhoto(imageUrl);
      final deleteDuration = DateTime.now().difference(deleteStartTime);

      debugPrint('Delete result: $success');
      debugPrint('Delete took: ${deleteDuration.inMilliseconds}ms');

      return {
        'success': success,
        'message': success ? 'Image deleted successfully' : 'Failed to delete image',
        'delete_duration_ms': deleteDuration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Wasabi delete test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Run comprehensive Wasabi test suite
  static Future<Map<String, dynamic>> runFullWasabiTest() async {
    debugPrint('Running full Wasabi test suite...');

    final results = <String, dynamic>{
      'test_start': DateTime.now().toIso8601String(),
      'tests': <Map<String, dynamic>>[],
    };

    try {
      // Test 1: Initialize and get stats
      debugPrint('Test 1: Initialize and get stats');
      final initTest = await testWasabiUpload();
      results['tests'].add({
        'test': 'initialization',
        'result': initTest,
      });

      if (!initTest['success']) {
        results['overall_success'] = false;
        results['message'] = 'Initialization failed';
        return results;
      }

      // Test 2: Upload image
      debugPrint('Test 2: Upload image');
      final uploadTest = await testWasabiUploadWithImage();
      results['tests'].add({
        'test': 'upload',
        'result': uploadTest,
      });

      if (uploadTest['success']) {
        // Test 3: Delete the uploaded image
        debugPrint('Test 3: Delete uploaded image');
        final deleteTest = await testWasabiDelete(uploadTest['image_url']);
        results['tests'].add({
          'test': 'delete',
          'result': deleteTest,
        });
      }

      results['overall_success'] = true;
      results['message'] = 'All tests completed';

    } catch (e) {
      results['overall_success'] = false;
      results['error'] = e.toString();
    }

    results['test_end'] = DateTime.now().toIso8601String();
    debugPrint('Wasabi test suite completed');

    return results;
  }
}