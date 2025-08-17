import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// Added for kIsWeb
import 'app_frontend/opening_page.dart';
import 'app_frontend/employee_register_page.dart';
import 'app_frontend/employer_register_page.dart';
import 'app_frontend/employer_dashboard.dart';
// ignore: unused_import
import 'app_frontend/employee_home_page.dart';
import 'app_frontend/employee_feed_page.dart';
import 'app_frontend/employee_liked_page.dart';
import 'app_frontend/employee_profile_page.dart';
import 'app_frontend/employee_main_scaffold.dart';
import 'app_frontend/employee_applied_page.dart';
import 'app_frontend/providers/applied_jobs_provider.dart';
import 'app_frontend/providers/liked_jobs_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase for both web and mobile
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Only setup FCM for mobile platforms (not web)
    if (!kIsWeb) {
      await _setupFCM();
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    }
    // Continue without Firebase if initialization fails
  }

  runApp(const MyApp());
}

Future<void> _setupFCM() async {
  try {
    // Request permissions (especially for iOS)
    await FirebaseMessaging.instance.requestPermission();
    // Get the device token
    String? deviceToken = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      print('FCM Device Token: ${deviceToken ?? 'null'}');
    }
    // Setup local notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received a foreground message: \\${message.toMap()}');
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
      // Optionally, trigger a refresh of the notification list if on NotificationPage
      // (You may need to use a global key or a state management solution for this)
    });
    // Listen for when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification clicked!');
      }
      // Handle navigation or UI update here
    });
  } catch (e) {
    if (kDebugMode) {
      print('FCM setup failed: $e');
    }
    // Continue without FCM if setup fails
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OpeningPage(),
      routes: {
        '/jobs': (context) => const Scaffold(
            body: Center(child: Text('Jobs Page'))), // Placeholder
        '/employer': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String phoneNumber = '';
          if (args is Map && args['phoneNumber'] is String) {
            phoneNumber = args['phoneNumber'];
          }
          if (kDebugMode) {
            print('DEBUG: main.dart /employer route phone: $phoneNumber');
          }
          return EmployerRegisterPage(phoneNumber: phoneNumber);
        },
        '/employee': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String phoneNumber = '';
          if (args is Map && args['phoneNumber'] is String) {
            phoneNumber = args['phoneNumber'];
          }
          return EmployeeRegisterPage(phoneNumber: phoneNumber);
        },
        '/employee-dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (kDebugMode) {
            print('DEBUG: /employee-dashboard route called with args = $args');
          }
          if (args is! Map || args['employeeId'] is! int) {
            throw Exception(
                'employeeId is required for /employee-dashboard route');
          }
          return EmployeeMainScaffold(employeeId: args['employeeId']);
        },
        '/employer-dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String phoneNumber = '';
          if (args is Map && args['phoneNumber'] is String) {
            phoneNumber = args['phoneNumber'];
          }
          if (kDebugMode) {
            print(
                'DEBUG: main.dart /employer-dashboard route phone: $phoneNumber');
          }
          return EmployerDashboard(phoneNumber: phoneNumber);
        },
        '/employee-feed': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (kDebugMode) {
            print('DEBUG: /employee-feed route called with args = $args');
          }
          if (args is! Map || args['employeeId'] is! int) {
            throw Exception('employeeId is required for /employee-feed route');
          }
          if (kDebugMode) {
            print(
                'DEBUG: Creating EmployeeFeedPage with employeeId = ${args['employeeId']}');
          }
          return EmployeeFeedPage(employeeId: args['employeeId']);
        },
        '/employee-liked': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (kDebugMode) {
            print('DEBUG: /employee-liked route called with args = $args');
          }
          if (args is! Map || args['employeeId'] is! int) {
            throw Exception('employeeId is required for /employee-liked route');
          }
          return EmployeeLikedPage(employeeId: args['employeeId']);
        },
        '/employee-profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (kDebugMode) {
            print('DEBUG: /employee-profile route called with args = $args');
          }
          if (args is! Map || args['employeeId'] is! int) {
            throw Exception(
                'employeeId is required for /employee-profile route');
          }
          return EmployeeProfilePage(employeeId: args['employeeId']);
        },
        '/employee-applied': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (kDebugMode) {
            print('DEBUG: /employee-applied route called with args = $args');
          }
          if (args is! Map ||
              args['employeeId'] is! int ||
              args['baseUrl'] is! String) {
            throw Exception(
                'employeeId and baseUrl are required for /employee-applied route');
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AppliedJobsProvider(
                  employeeId: args['employeeId'],
                  baseUrl: args['baseUrl'],
                )..fetchAppliedJobs(),
              ),
              ChangeNotifierProvider(
                create: (_) => LikedJobsProvider(
                  employeeId: args['employeeId'],
                )..fetchLikedJobs(),
              ),
            ],
            child: EmployeeAppliedPage(
              employeeId: args['employeeId'],
              baseUrl: args['baseUrl'],
            ),
          );
        },
      },
    );
  }
}
