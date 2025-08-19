// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_web.dart';

// Real app pages
import 'app_frontend/opening_page_web.dart';
import 'app_frontend/employee_register_page.dart';
import 'app_frontend/employer_register_page.dart';
import 'app_frontend/employer_dashboard.dart';
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
		await Firebase.initializeApp(
			options: DefaultFirebaseOptions.currentPlatform,
		);
		if (kDebugMode) {
			print('Firebase initialized successfully for web');
		}
	} catch (e) {
		if (kDebugMode) {
			print('Firebase initialization failed for web: $e');
		}
	}

	runApp(const MyApp());
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Jobs App',
			debugShowCheckedModeBanner: false,
			home: const OpeningPageWeb(),
			routes: {
				'/employer': (context) {
					final args = ModalRoute.of(context)?.settings.arguments;
					String phoneNumber = '';
					if (args is Map && args['phoneNumber'] is String) {
						phoneNumber = args['phoneNumber'];
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
					if (args is! Map || args['employeeId'] is! int) {
						throw Exception('employeeId is required for /employee-dashboard route');
					}
					return EmployeeMainScaffold(employeeId: args['employeeId']);
				},
				'/employer-dashboard': (context) {
					final args = ModalRoute.of(context)?.settings.arguments;
					String phoneNumber = '';
					if (args is Map && args['phoneNumber'] is String) {
						phoneNumber = args['phoneNumber'];
					}
					return EmployerDashboard(phoneNumber: phoneNumber);
				},
				'/employee-feed': (context) {
					final args = ModalRoute.of(context)?.settings.arguments;
					if (args is! Map || args['employeeId'] is! int) {
						throw Exception('employeeId is required for /employee-feed route');
					}
					return EmployeeFeedPage(employeeId: args['employeeId']);
				},
				'/employee-liked': (context) {
					final args = ModalRoute.of(context)?.settings.arguments;
					if (args is! Map || args['employeeId'] is! int) {
						throw Exception('employeeId is required for /employee-liked route');
					}
					return EmployeeLikedPage(employeeId: args['employeeId']);
				},
				'/employee-profile': (context) {
					final args = ModalRoute.of(context)?.settings.arguments;
					if (args is! Map || args['employeeId'] is! int) {
						throw Exception('employeeId is required for /employee-profile route');
					}
					return EmployeeProfilePage(employeeId: args['employeeId']);
				},
				'/employee-applied': (context) {
					final args = ModalRoute.of(context)?.settings.arguments;
					if (args is! Map || args['employeeId'] is! int || args['baseUrl'] is! String) {
						throw Exception('employeeId and baseUrl are required for /employee-applied route');
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
