// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'app_frontend/opening_page_web.dart';
import 'app_frontend/providers/applied_jobs_provider.dart';
import 'app_frontend/providers/liked_jobs_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Web-specific initialization without Firebase
  if (kDebugMode) {
    print('Initializing Jobs App for Web - Using Real App');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppliedJobsProvider(
              employeeId: 1, baseUrl: 'http://98.84.239.161'),
        ),
        ChangeNotifierProvider(
          create: (_) => LikedJobsProvider(employeeId: 1),
        ),
      ],
      child: MaterialApp(
        title: 'Jobs App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const OpeningPageWeb(), // Use your real OpeningPage
      ),
    );
  }
}
