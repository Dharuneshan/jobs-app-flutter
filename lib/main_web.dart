// Web entry point for the real Jobs App
// This excludes Firebase Messaging to avoid web build issues
// Uses ApiService.create() factory to automatically connect to AWS backend

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_web.dart';
import 'config/api_config.dart';

// Real app pages - excluding Firebase Messaging imports
import 'app_frontend/opening_page.dart';
import 'app_frontend/employee_register_page.dart';
import 'app_frontend/employer_register_page.dart';
import 'app_frontend/employer_dashboard.dart';
import 'app_frontend/employee_home_page.dart';
import 'app_frontend/employee_feed_page.dart';
import 'app_frontend/employee_liked_page.dart';
import 'app_frontend/employee_profile_page.dart';
import 'app_frontend/employee_main_scaffold.dart';
import 'app_frontend/employee_applied_page.dart';
import 'app_frontend/providers/applied_jobs_provider.dart';
import 'app_frontend/providers/liked_jobs_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase Core for web (without messaging)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('Firebase Core initialized successfully for web');
      print('Web app will connect to AWS backend at: ${ApiConfig.baseUrl}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed for web: $e');
    }
    // Continue without Firebase if initialization fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '15 Jobs App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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
