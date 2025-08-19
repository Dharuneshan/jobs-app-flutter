import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL for API calls
  static String get baseUrl {
    if (kIsWeb) {
      // Web environment - use EC2 Elastic IP over HTTPS
      return 'https://98.84.239.161';
    } else {
      // Mobile environment - same for now; can be different per env
      return 'https://98.84.239.161';
    }
  }

  // S3 bucket for media files
  static String get s3Bucket {
    return 'jobs-app-media-2024';
  }

  // S3 region
  static String get s3Region {
    return 'us-east-1';
  }

  // Check if running on web
  static bool get isWeb => kIsWeb;

  // Check if running on mobile
  static bool get isMobile => !kIsWeb;
}
