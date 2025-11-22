enum ImageQuality {
  raw(95),
  hd(85),
  compressed(70);

  const ImageQuality(this.jpegQuality);

  final int jpegQuality;

  // Get enum from string value
  static ImageQuality fromString(String value) {
    switch (value) {
      case 'raw':
        return ImageQuality.raw;
      case 'hd':
        return ImageQuality.hd;
      case 'compressed':
        return ImageQuality.compressed;
      default:
        return ImageQuality.hd; // Default to HD
    }
  }

  // Get string value for storage
  String get value => name;
}