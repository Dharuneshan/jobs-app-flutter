import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

// Conditional imports to avoid Firebase Messaging on web
import 'firebase_options.dart'
    if (dart.library.html) 'firebase_options_web.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
      }
      // Continue without Firebase if initialization fails
    }
  }

  static Future<void> setupMessaging() async {
    // Only setup messaging for non-web platforms
    if (!kIsWeb) {
      try {
        // Import Firebase Messaging only for mobile platforms
        // This prevents web compilation issues
        await _setupMobileMessaging();
      } catch (e) {
        if (kDebugMode) {
          print('Firebase Messaging setup failed: $e');
        }
      }
    }
  }

  static Future<void> _setupMobileMessaging() async {
    // This will only be called on mobile platforms
    // Firebase Messaging imports are handled conditionally
    if (kDebugMode) {
      print('Setting up Firebase Messaging for mobile');
    }

    try {
      // Dynamically import the mobile service to avoid web compilation issues
      if (!kIsWeb) {
        // Import and use the mobile Firebase service
        // This is a workaround to avoid web compilation issues
        await _importAndSetupMobileMessaging();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Mobile messaging setup failed: $e');
      }
    }
  }

  static Future<void> _importAndSetupMobileMessaging() async {
    // This method will be implemented to dynamically handle mobile messaging
    // For now, we'll just print a message
    if (kDebugMode) {
      print('Mobile messaging setup placeholder - implement as needed');
    }
  }
}
