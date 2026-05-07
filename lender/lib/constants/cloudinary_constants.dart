class CloudinaryConstants {
  CloudinaryConstants._();

  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  static const String itemsFolder = 'lender/items';
}
