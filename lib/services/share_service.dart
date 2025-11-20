import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/visit.dart';
import '../models/photo.dart';

class ShareService {
  /// Share all photos from a visit with visit details
  static Future<void> shareVisitPhotos(Visit visit, List<String> photoUrls, BuildContext context, {Rect? sharePositionOrigin}) async {
    try {
      if (photoUrls.isEmpty) {
        if (context.mounted) {
          _showMessage(context, 'No photos to share');
        }
        return;
      }

      if (context.mounted) {
        _showMessage(context, 'Preparing photos for sharing...');
      }

      // Download photos to temporary files
      final List<XFile> photoFiles = [];
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < photoUrls.length; i++) {
        final url = photoUrls[i];
        try {
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final fileName = 'style_memory_photo_${i + 1}.jpg';
            final filePath = '${tempDir.path}/$fileName';

            final file = File(filePath);
            await file.writeAsBytes(bytes);

            photoFiles.add(XFile(filePath));
          }
        } catch (e) {
          // Skip this photo if download fails
          debugPrint('Failed to download photo $i: $e');
        }
      }

      if (photoFiles.isEmpty) {
        if (context.mounted) {
          _showMessage(context, 'Failed to prepare photos for sharing');
        }
        return;
      }

      // Create share text with visit details (without URLs)
      // final shareText = _createShareText(visit);

      // Share photos with text
      await Share.shareXFiles(
        photoFiles,
        // text: shareText,
        subject: 'Hair Styling Session - ${visit.formattedVisitDate}',
        sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
      );

      // Clean up temporary files after a delay
      _cleanupTempFilesDelayed(photoFiles);

    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Failed to share photos: $e');
      }
    }
  }

  /// Share a single photo from a visit
  static Future<void> shareVisitPhoto(Visit visit, String photoUrl, PhotoType photoType, BuildContext context, {Rect? sharePositionOrigin}) async {
    try {
      if (context.mounted) {
        _showMessage(context, 'Preparing photo for sharing...');
      }

      // Download photo to temporary file
      final tempDir = await getTemporaryDirectory();
      final response = await http.get(Uri.parse(photoUrl));

      if (response.statusCode != 200) {
        if (context.mounted) {
          _showMessage(context, 'Failed to download photo');
        }
        return;
      }

      final bytes = response.bodyBytes;
      final fileName = 'style_memory_${photoType.displayName.toLowerCase()}_view.jpg';
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Create share text with visit details
      final shareText = _createShareText(visit, photoType: photoType);

      // Share photo with text
      await Share.shareXFiles(
        [XFile(filePath)],
        text: shareText,
        subject: 'Hair Styling - ${photoType.displayName} View',
        sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
      );

      // Clean up temporary file after a delay
      _cleanupTempFilesDelayed([XFile(filePath)]);

    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Failed to share photo: $e');
      }
    }
  }


  /// Create share text with visit details
  static String _createShareText(Visit visit, {PhotoType? photoType}) {
    final buffer = StringBuffer();
    buffer.writeln('Shared from StyleMemory');

    return buffer.toString();
  }

  /// Show a brief message to the user
  static void _showMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Clean up temporary files after a delay to allow sharing to complete
  static void _cleanupTempFilesDelayed(List<XFile> files) {
    Future.delayed(const Duration(seconds: 30), () async {
      for (final file in files) {
        try {
          final fileToDelete = File(file.path);
          if (await fileToDelete.exists()) {
            await fileToDelete.delete();
          }
        } catch (e) {
          // Ignore cleanup errors
          debugPrint('Failed to cleanup temp file: ${file.path}');
        }
      }
    });
  }

}