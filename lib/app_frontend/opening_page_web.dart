// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/profile_service.dart';
import 'package:flutter/foundation.dart';
import 'choose_role_page.dart';
// ignore: unused_import
import '../services/api_service.dart';
// ignore: duplicate_import
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Web-compatible device token function
Future<String?> getDeviceToken() async {
  if (kIsWeb) {
    // Return a placeholder token for web
    return 'web-device-token-placeholder';
  } else {
    // For mobile, return placeholder for now
    return 'mobile-device-token-placeholder';
  }
}

Future<void> updateDeviceToken(
    String phoneNumber, String deviceToken, bool isEmployer) async {
  final url = isEmployer
      ? 'http://98.84.239.161/api/employer-registrations/update-device-token/'
      : 'http://98.84.239.161/api/employee-registrations/update-device-token/';
  final response = await http.patch(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'phone_number': phoneNumber,
      'device_token': deviceToken,
    }),
  );
  if (response.statusCode == 200) {
    if (kDebugMode) print('Device token updated successfully');
  } else {
    if (kDebugMode) print('Failed to update device token: ${response.body}');
  }
}

class OpeningPageWeb extends StatefulWidget {
  const OpeningPageWeb({Key? key}) : super(key: key);

  @override
  State<OpeningPageWeb> createState() => _OpeningPageWebState();
}

class _OpeningPageWebState extends State<OpeningPageWeb> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final phoneNumber = _phoneController.text;
        if (kDebugMode) {
          print('DEBUG: Starting phone number verification for: $phoneNumber');
        }

        // First, check registration type
        final regType =
            await _profileService.checkRegistrationType(phoneNumber);
        print('DEBUG: Registration type from checkRegistrationType = $regType');

        if (regType == 'employee') {
          if (kDebugMode) {
            print(
                'DEBUG: Found employee registration, redirecting to employee dashboard');
          }
          // Fetch employeeId from backend using phone number
          final employeeList =
              await ApiService().getEmployeeRegistrationByPhone(phoneNumber);
          print('DEBUG: employeeList = $employeeList');
          final employeeId = employeeList[0]['employee_id'];
          // Register device token
          final deviceToken = await getDeviceToken();
          if (deviceToken != null) {
            await updateDeviceToken(phoneNumber, deviceToken, false);
          }
          if (!mounted) return;
          print(
              'DEBUG: Navigating to /employee-dashboard with employeeId = $employeeId (from regType == employee)');
          Navigator.pushReplacementNamed(
            context,
            '/employee-dashboard',
            arguments: {'employeeId': employeeId},
          );
          return;
        } else if (regType == 'employer') {
          if (kDebugMode) {
            print(
                'DEBUG: Found employer registration, redirecting to employer dashboard');
          }
          // Register device token
          final deviceToken = await getDeviceToken();
          if (deviceToken != null) {
            await updateDeviceToken(phoneNumber, deviceToken, true);
          }
          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(
            // ignore: use_build_context_synchronously
            context,
            '/employer-dashboard',
            arguments: {'phoneNumber': phoneNumber},
          );
          return;
        } else {
          if (kDebugMode) {
            print('DEBUG: No registration found, redirecting to choose role');
          }
          // No registration found, go to choose role page
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChooseRolePage(phoneNumber: phoneNumber),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: Error in _handleNext: $e');
        }
        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('An error occurred: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.work,
                      size: 60,
                      color: Color(0xFF667eea),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App Title
                  const Text(
                    'Jobs App',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtitle
                  const Text(
                    'Your job search and recruitment platform',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  // Phone Number Form
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'Enter your phone number',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter phone number',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.phone,
                                color: Colors.white,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.white),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (value.length < 10) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF667eea),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 8,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF667eea)),
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Web indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Web Version - Connected to AWS Backend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
