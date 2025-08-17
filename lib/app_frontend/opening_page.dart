// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/profile_service.dart';
import 'package:flutter/foundation.dart';
import 'choose_role_page.dart';
// ignore: unused_import
import '../services/api_service.dart';
// ignore: duplicate_import
import '../services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> getDeviceToken() async {
  return await FirebaseMessaging.instance.getToken();
}

Future<void> updateDeviceToken(
    String phoneNumber, String deviceToken, bool isEmployer) async {
  final url = isEmployer
      ? 'http://10.0.2.2:8000/api/employer-registrations/update-device-token/'
      : 'http://10.0.2.2:8000/api/employee-registrations/update-device-token/';
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

class OpeningPage extends StatefulWidget {
  const OpeningPage({Key? key}) : super(key: key);

  @override
  State<OpeningPage> createState() => _OpeningPageState();
}

class _OpeningPageState extends State<OpeningPage> {
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
        }

        if (kDebugMode) {
          print('DEBUG: No registration found, checking profile table');
        }

        // If not registered, proceed with profile logic
        final result = await _profileService.checkPhoneNumber(phoneNumber);
        if (kDebugMode) {
          print('DEBUG: Profile check result: $result');
        }

        if (!mounted) return;

        if (result['exists']) {
          if (kDebugMode) {
            print(
                'DEBUG: Profile exists with type: ${result['candidate_type']}, is_registered: ${result['is_registered']}');
          }
          // Number exists in profile table
          if (result['is_registered']) {
            // User is registered, redirect to appropriate dashboard
            if (result['candidate_type'] == 'employee') {
              if (kDebugMode) {
                print(
                    'DEBUG: Profile is registered as employee, redirecting to employee dashboard');
              }
              // Fetch employeeId from backend using phone number
              final employeeList = await ApiService()
                  .getEmployeeRegistrationByPhone(phoneNumber);
              print('DEBUG: employeeList = $employeeList');
              final employeeId = employeeList[0]['employee_id'];
              // Register device token
              final deviceToken = await getDeviceToken();
              if (deviceToken != null) {
                await updateDeviceToken(phoneNumber, deviceToken, false);
              }
              print(
                  'DEBUG: selected employeeId = $employeeId (from profile is_registered)');
              if (!mounted) return;
              print(
                  'DEBUG: Navigating to /employee-dashboard with employeeId = $employeeId (from profile is_registered)');
              Navigator.pushReplacementNamed(
                context,
                '/employee-dashboard',
                arguments: {'employeeId': employeeId},
              );
            } else {
              if (kDebugMode) {
                print(
                    'DEBUG: Profile is registered as employer, redirecting to employer dashboard');
              }
              Navigator.pushReplacementNamed(
                context,
                '/employer-dashboard',
                arguments: {'phoneNumber': phoneNumber},
              );
            }
          } else {
            // User exists but not registered, redirect to registration
            if (result['candidate_type'] == 'employee') {
              if (kDebugMode) {
                print(
                    'DEBUG: Profile exists as employee but not registered, redirecting to employee registration');
              }
              Navigator.pushReplacementNamed(
                context,
                '/employee',
                arguments: {'phoneNumber': phoneNumber},
              );
            } else {
              if (kDebugMode) {
                print(
                    'DEBUG: Profile exists as employer but not registered, redirecting to employer registration');
              }
              Navigator.pushReplacementNamed(
                context,
                '/employer',
                arguments: {'phoneNumber': phoneNumber},
              );
            }
          }
        } else {
          if (kDebugMode) {
            print(
                'DEBUG: No profile exists, creating new profile and redirecting to candidate page');
          }
          // Number doesn't exist, create profile and go to candidate page
          // final profile = Profile(
          //   phoneNumber: phoneNumber,
          //   candidateType: 'employee', // Default type
          // );
          // await _profileService.saveProfile(profile);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChooseRolePage(
                phoneNumber: phoneNumber,
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('DEBUG: Error in _handleNext: $e');
          print('DEBUG: Stack trace: $stackTrace');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Logo placeholder
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0044CC),
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome to 15 Jobs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Find your dream job or hire the best talent',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Phone Number Input with +91 prefix
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          '+91',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
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
                  const SizedBox(height: 32),
                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0044CC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: Color(0xFF0044CC),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF0044CC),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
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
