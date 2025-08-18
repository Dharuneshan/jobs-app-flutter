// This file is only imported for mobile platforms to avoid web compilation issues
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMobileService {
  static Future<void> setupMessaging() async {
    try {
      // Request permissions (especially for iOS)
      await FirebaseMessaging.instance.requestPermission();

      // Get the device token
      String? deviceToken = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        print('FCM Device Token: ${deviceToken ?? 'null'}');
      }

      // Setup local notifications
      await _setupLocalNotifications();

      // Setup message listeners
      await _setupMessageListeners();
    } catch (e) {
      if (kDebugMode) {
        print('FCM setup failed: $e');
      }
    }
  }

  static Future<void> _setupLocalNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> _setupMessageListeners() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received a foreground message: ${message.toMap()}');
      }

      // Show local notification for both notification and data-only messages
      if (message.notification != null || message.data.isNotEmpty) {
        final notification = message.notification;
        final title =
            notification?.title ?? message.data['title'] ?? 'Notification';
        final body = notification?.body ??
            message.data['body'] ??
            'You have a new message';

        flutterLocalNotificationsPlugin.show(
          notification?.hashCode ?? message.data.hashCode,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default',
              channelDescription: 'Default channel for notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Listen for when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification clicked!');
      }
      // Handle navigation or UI update here
    });
  }
}
