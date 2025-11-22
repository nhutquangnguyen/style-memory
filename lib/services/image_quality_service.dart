import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_quality.dart';

class ImageQualityService {
  static const String _imageQualityKey = 'image_quality';

  /// Get the currently selected image quality setting
  static Future<ImageQuality> getImageQuality() async {
    final prefs = await SharedPreferences.getInstance();
    final qualityString = prefs.getString(_imageQualityKey) ?? 'hd';
    return ImageQuality.fromString(qualityString);
  }

  /// Save the image quality setting
  static Future<void> setImageQuality(ImageQuality quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageQualityKey, quality.value);
  }

  /// Get the JPEG quality for image compression
  static Future<int> getJpegQuality() async {
    final quality = await getImageQuality();
    return quality.jpegQuality;
  }
}